import { spawn, type ChildProcess } from "child_process";
import { commandExists, httpsToWss, sleep, wsToHttps } from "../utils";
import type {
  ResolvedTransportSetup,
  RuntimeStartContext,
  RuntimeStartResult,
  SetupContext,
  StoredTransportConfig,
  TransportDetectionResult,
  TransportProvider,
} from "../types";

function extractTryCloudflareUrl(text: string): string | null {
  const match = text.match(/https:\/\/[a-z0-9-]+\.trycloudflare\.com/i);
  return match?.[0] ?? null;
}

function normalizeConfiguredHttpsUrl(value: string): string {
  const trimmed = value.trim();
  const withProtocol = /^[a-z]+:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`;
  const parsed = new URL(withProtocol);
  const protocol = parsed.protocol === "wss:" || parsed.protocol === "ws:" ? "https:" : "https:";
  const pathname = parsed.pathname === "/" ? "" : parsed.pathname.replace(/\/$/, "");

  return `${protocol}//${parsed.host}${pathname}${parsed.search}${parsed.hash}`;
}

function resolveConfiguredUrls(
  transport: StoredTransportConfig,
): Pick<RuntimeStartResult, "publicHttpsUrl" | "publicWsUrl"> {
  const publicHttpsUrl = transport.publicHttpsUrl
    ? normalizeConfiguredHttpsUrl(transport.publicHttpsUrl)
    : transport.publicWsUrl
      ? wsToHttps(transport.publicWsUrl)
      : undefined;

  return {
    publicHttpsUrl,
    publicWsUrl: transport.publicWsUrl ?? (publicHttpsUrl ? httpsToWss(publicHttpsUrl) : undefined),
  };
}

function getLocalOrigin(transport: StoredTransportConfig): string {
  return `${transport.localProtocol}://${transport.localHost}:${transport.localPort}`;
}

function isNamedTunnel(transport: StoredTransportConfig): boolean {
  return transport.metadata?.tunnelType === "named" || transport.publicUrlMode === "static";
}

function createStopHandler(child: ChildProcess): () => Promise<void> {
  return async () => {
    child.kill("SIGTERM");
    await new Promise<void>((resolve) => {
      child.once("exit", () => resolve());
    });
  };
}

function createQuickTunnelMetadata(): Record<string, string> {
  const metadata: Record<string, string> = {
    runtimeProvider: "cloudflare",
  };

  Object.defineProperty(metadata, "tunnelType", {
    value: "quick",
    enumerable: false,
    writable: true,
    configurable: true,
  });

  return metadata;
}

async function resolveNamedTunnelName(context: SetupContext): Promise<string | undefined> {
  const existingTunnelName = context.existingConfig?.transport.metadata?.tunnelName?.trim();
  if (existingTunnelName) {
    return existingTunnelName;
  }

  const promptedTunnelName = await context.promptText(
    "Enter the existing Cloudflare tunnel name",
    "recursor-bridge",
  );

  const tunnelName = promptedTunnelName?.trim();
  return tunnelName && tunnelName.length > 0 ? tunnelName : undefined;
}

export class CloudflareTransportProvider implements TransportProvider {
  readonly id = "cloudflare" as const;
  readonly label = "Cloudflare Tunnel";

  async detect(context: SetupContext): Promise<TransportDetectionResult> {
    const available = await commandExists("cloudflared", ["--version"]);
    const wantsNamedTunnel = Boolean(context.options.publicUrl?.trim());

    return {
      providerId: this.id,
      label: this.label,
      available,
      detail: available
        ? wantsNamedTunnel
          ? "cloudflared CLI detected. Named tunnel mode can reuse a pre-created Cloudflare tunnel and configured hostname."
          : "cloudflared CLI detected. A temporary trycloudflare.com URL can be created at runtime."
        : undefined,
      reason: available ? undefined : "CLI not found on PATH.",
    };
  }

  async setup(context: SetupContext): Promise<ResolvedTransportSetup> {
    const localProtocol = context.options.localMode === "local-tls" ? "https" : "http";
    const localOrigin = `${localProtocol}://127.0.0.1:${context.options.port}`;
    const configuredPublicUrl = context.options.publicUrl?.trim();

    if (configuredPublicUrl) {
      const publicHttpsUrl = normalizeConfiguredHttpsUrl(configuredPublicUrl);
      const tunnelName = await resolveNamedTunnelName(context);
      const metadata: Record<string, string> = {
        runtimeProvider: "cloudflare",
        tunnelType: "named",
      };

      if (tunnelName) {
        metadata.tunnelName = tunnelName;
      }

      return {
        transport: {
          provider: this.id,
          label: this.label,
          mode: "secure_remote",
          publicUrlMode: "static",
          publicHttpsUrl,
          publicWsUrl: httpsToWss(publicHttpsUrl),
          localProtocol,
          localPort: context.options.port,
          localHost: "127.0.0.1",
          tlsTermination: "upstream",
          metadata,
        },
        setupSummary: [
          `Cloudflare named tunnel public URL: ${publicHttpsUrl}`,
          `Local origin: ${localOrigin}`,
          tunnelName
            ? `Tunnel name: ${tunnelName}`
            : "Tunnel name was not stored. Re-run setup to provide the existing named tunnel if runtime start cannot launch it.",
          localProtocol === "https"
            ? "Cloudflare terminates public TLS at the edge and connects to a local HTTPS origin."
            : "Cloudflare terminates public TLS at the edge and proxies to a local HTTP origin.",
        ],
      };
    }

    return {
      transport: {
        provider: this.id,
        label: this.label,
        mode: "secure_remote",
        publicUrlMode: "dynamic",
        localProtocol,
        localPort: context.options.port,
        localHost: "127.0.0.1",
        tlsTermination: "upstream",
        metadata: createQuickTunnelMetadata(),
      },
      setupSummary: [
        `Cloudflare Quick Tunnel will expose ${localOrigin} at runtime.`,
        "A temporary trycloudflare.com HTTPS/WSS URL will be generated when the bridge starts.",
        localProtocol === "https"
          ? "Cloudflare terminates public TLS at the edge and connects to a local HTTPS origin."
          : "Cloudflare terminates public TLS at the edge and proxies to a local HTTP origin.",
      ],
    };
  }

  async startRuntime(context: RuntimeStartContext): Promise<RuntimeStartResult> {
    const transport = context.config.transport;
    const namedTunnel = isNamedTunnel(transport);
    const tunnelName = transport.metadata?.tunnelName?.trim();

    if (namedTunnel && !tunnelName) {
      context.log(
        "[cloudflared] No tunnel name configured; assuming the named tunnel is managed externally.",
      );
      return resolveConfiguredUrls(transport);
    }

    const args = namedTunnel
      ? ["tunnel", "--no-autoupdate", "run", tunnelName as string]
      : ["tunnel", "--no-autoupdate", "--url", getLocalOrigin(transport)];

    const child: ChildProcess = spawn("cloudflared", args, {
      stdio: ["ignore", "pipe", "pipe"],
      shell: false,
    });

    let discoveredUrl: string | null = null;
    const onData = (chunk: Buffer) => {
      const text = chunk.toString();
      context.log(`[cloudflared] ${text.trim()}`);
      discoveredUrl ??= extractTryCloudflareUrl(text);
    };

    child.stdout?.on("data", onData);
    child.stderr?.on("data", onData);

    const stop = createStopHandler(child);

    if (namedTunnel) {
      return {
        ...resolveConfiguredUrls(transport),
        stop,
      };
    }

    for (let attempt = 0; attempt < 30; attempt += 1) {
      if (discoveredUrl) {
        return {
          publicHttpsUrl: discoveredUrl,
          publicWsUrl: httpsToWss(discoveredUrl),
          stop,
        };
      }
      await sleep(500);
    }

    child.kill("SIGTERM");
    throw new Error(
      "cloudflared did not publish a tunnel URL within 15 seconds. Check cloudflared availability, network access, and Quick Tunnel readiness.",
    );
  }

  async doctor(context: RuntimeStartContext): Promise<string[]> {
    const available = await commandExists("cloudflared", ["--version"]);
    const transport = context.config.transport;
    const namedTunnel = isNamedTunnel(transport);
    const configuredUrls = resolveConfiguredUrls(transport);
    const lines = [`Transport provider: Cloudflare Tunnel`];

    lines.push(`cloudflared: ${available ? "detected on PATH" : "not detected on PATH"}`);
    lines.push(
      namedTunnel
        ? "Tunnel type: named (persistent hostname)"
        : "Tunnel type: quick (temporary trycloudflare.com URL)",
    );

    if (transport.metadata?.tunnelName) {
      lines.push(`Tunnel name: ${transport.metadata.tunnelName}`);
    }

    if (transport.publicUrlMode === "static" && configuredUrls.publicHttpsUrl) {
      lines.push(`Public URL: ${configuredUrls.publicHttpsUrl}`);
    } else {
      lines.push("Public URL: dynamic (generated by cloudflared at runtime)");
    }

    lines.push(`Local origin: ${getLocalOrigin(transport)}`);
    lines.push(
      transport.localProtocol === "https"
        ? "TLS: Cloudflare terminates public HTTPS at the edge and connects to a local HTTPS origin."
        : "TLS: Cloudflare terminates public HTTPS at the edge and proxies to a local HTTP origin.",
    );

    return lines;
  }
}
