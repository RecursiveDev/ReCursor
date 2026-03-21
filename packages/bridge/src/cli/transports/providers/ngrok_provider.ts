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

interface NgrokTunnelApiResponse {
  tunnels?: Array<{
    public_url?: string;
    proto?: string;
    config?: {
      addr?: string;
    };
  }>;
}

async function fetchNgrokTunnelUrl(port: number): Promise<string | null> {
  try {
    const response = await fetch("http://127.0.0.1:4040/api/tunnels");
    if (!response.ok) {
      return null;
    }

    const payload = (await response.json()) as NgrokTunnelApiResponse;
    const matchingTunnel = payload.tunnels?.find((tunnel) => {
      const publicUrl = tunnel.public_url ?? "";
      const addr = tunnel.config?.addr ?? "";
      return publicUrl.startsWith("https://") && addr.endsWith(`:${port}`);
    });

    return matchingTunnel?.public_url ?? null;
  } catch {
    return null;
  }
}

export class NgrokTransportProvider implements TransportProvider {
  readonly id = "ngrok" as const;
  readonly label = "ngrok";

  async detect(_context: SetupContext): Promise<TransportDetectionResult> {
    const available = await commandExists("ngrok", ["version"]);
    return {
      providerId: this.id,
      label: this.label,
      available,
      detail: available ? "ngrok CLI detected. Public URL is allocated at runtime." : undefined,
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
          runtimeProvider: "ngrok",
        },
      },
      setupSummary: [
        `ngrok will expose http://127.0.0.1:${context.options.port} at runtime.`,
        "A temporary public HTTPS/WSS URL will be generated each time the bridge starts.",
      ],
    };
  }

  async startRuntime(context: RuntimeStartContext): Promise<RuntimeStartResult> {
    const port = context.config.transport.localPort;
    const child: ChildProcess = spawn(
      "ngrok",
      ["http", `http://127.0.0.1:${port}`, "--log", "stdout"],
      {
        stdio: ["ignore", "pipe", "pipe"],
        shell: false,
      },
    );

    const logTunnelOutput = (prefix: string, chunk: Buffer) => {
      const text = chunk.toString().trim();
      if (text.length > 0) {
        context.log(`[ngrok] ${prefix}${text}`);
      }
    };

    child.stdout?.on("data", (chunk: Buffer) => logTunnelOutput("", chunk));
    child.stderr?.on("data", (chunk: Buffer) => logTunnelOutput("stderr: ", chunk));

    for (let attempt = 0; attempt < 20; attempt += 1) {
      const publicHttpsUrl = await fetchNgrokTunnelUrl(port);
      if (publicHttpsUrl) {
        return {
          publicHttpsUrl,
          publicWsUrl: httpsToWss(publicHttpsUrl),
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
    throw new Error("ngrok did not publish a tunnel URL within 10 seconds.");
  }

  async doctor(_context: RuntimeStartContext): Promise<string[]> {
    return [
      "Transport provider: ngrok",
      "Public URL is generated dynamically when `recursor start` runs.",
    ];
  }
}
