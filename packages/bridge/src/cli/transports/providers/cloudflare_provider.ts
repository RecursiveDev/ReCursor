import { spawn, type ChildProcess } from "child_process";
import { commandExists, httpsToWss, sleep } from "../utils";
import type {
  ResolvedTransportSetup,
  RuntimeStartContext,
  RuntimeStartResult,
  SetupContext,
  TransportDetectionResult,
  TransportProvider,
} from "../types";

function extractTryCloudflareUrl(text: string): string | null {
  const match = text.match(/https:\/\/[a-z0-9-]+\.trycloudflare\.com/i);
  return match?.[0] ?? null;
}

export class CloudflareTransportProvider implements TransportProvider {
  readonly id = "cloudflare" as const;
  readonly label = "Cloudflare Tunnel";

  async detect(_context: SetupContext): Promise<TransportDetectionResult> {
    const available = await commandExists("cloudflared", ["--version"]);
    return {
      providerId: this.id,
      label: this.label,
      available,
      detail: available
        ? "cloudflared CLI detected. A temporary trycloudflare.com URL can be created at runtime."
        : undefined,
      reason: available ? undefined : "CLI not found on PATH.",
    };
  }

  async setup(context: SetupContext): Promise<ResolvedTransportSetup> {
    return {
      transport: {
        provider: this.id,
        label: this.label,
        mode: "secure_remote",
        publicUrlMode: "dynamic",
        localProtocol: "http",
        localPort: context.options.port,
        localHost: "127.0.0.1",
        tlsTermination: "upstream",
        metadata: {
          runtimeProvider: "cloudflare",
        },
      },
      setupSummary: [
        `Cloudflare Tunnel will expose http://127.0.0.1:${context.options.port} at runtime.`,
        "A temporary trycloudflare.com HTTPS/WSS URL will be generated when the bridge starts.",
      ],
    };
  }

  async startRuntime(context: RuntimeStartContext): Promise<RuntimeStartResult> {
    const port = context.config.transport.localPort;
    const child: ChildProcess = spawn(
      "cloudflared",
      ["tunnel", "--no-autoupdate", "--url", `http://127.0.0.1:${port}`],
      {
        stdio: ["ignore", "pipe", "pipe"],
        shell: false,
      },
    );

    let discoveredUrl: string | null = null;
    const onData = (chunk: Buffer) => {
      const text = chunk.toString();
      context.log(`[cloudflared] ${text.trim()}`);
      discoveredUrl ??= extractTryCloudflareUrl(text);
    };

    child.stdout?.on("data", onData);
    child.stderr?.on("data", onData);

    for (let attempt = 0; attempt < 30; attempt += 1) {
      if (discoveredUrl) {
        return {
          publicHttpsUrl: discoveredUrl,
          publicWsUrl: httpsToWss(discoveredUrl),
          stop: async () => {
            child.kill("SIGTERM");
            await new Promise<void>((resolve) => {
              child.once("exit", () => resolve());
            });
          },
        };
      }
      await sleep(500);
    }

    child.kill("SIGTERM");
    throw new Error("cloudflared did not publish a tunnel URL within 15 seconds.");
  }

  async doctor(_context: RuntimeStartContext): Promise<string[]> {
    return [
      "Transport provider: Cloudflare Tunnel",
      "Public URL is generated dynamically when `recursor start` runs.",
    ];
  }
}
