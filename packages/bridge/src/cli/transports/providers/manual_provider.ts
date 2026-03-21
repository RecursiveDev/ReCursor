import { findPrivateNetworkCandidates, wsToHttps } from "../utils";
import type {
  ResolvedTransportSetup,
  RuntimeStartContext,
  RuntimeStartResult,
  SetupContext,
  TransportDetectionResult,
  TransportProvider,
} from "../types";

function validateSecureWsUrl(value: string): string {
  const normalized = value.trim();
  const parsed = new URL(normalized);
  if (parsed.protocol !== "wss:") {
    throw new Error("Manual public URL must use wss://");
  }
  return normalized;
}

export class ManualTransportProvider implements TransportProvider {
  readonly id = "manual" as const;
  readonly label = "Manual / Existing Remote Endpoint";

  async detect(_context: SetupContext): Promise<TransportDetectionResult> {
    const candidates = await findPrivateNetworkCandidates();
    return {
      providerId: this.id,
      label: this.label,
      available: true,
      detail:
        candidates.length > 0
          ? `Private network candidates: ${candidates.join(", ")}`
          : "Use this with your own reverse proxy, LAN cert, or public hostname.",
    };
  }

  async setup(context: SetupContext): Promise<ResolvedTransportSetup> {
    const selectedMode =
      context.options.localMode ??
      ((await context.promptSelect("How is TLS terminated for your manual endpoint?", [
        { value: "local-tls", label: "Bridge terminates TLS locally (cert/key on this machine)" },
        { value: "upstream-proxy", label: "A reverse proxy/tunnel terminates TLS upstream" },
      ])) as "local-tls" | "upstream-proxy");

    const publicUrl = validateSecureWsUrl(
      context.options.publicUrl ??
        (await context.promptText("Enter the public WSS bridge URL", "wss://bridge.example.com")),
    );
    const publicUrlObject = new URL(publicUrl);
    const localTlsPort = publicUrlObject.port
      ? Number.parseInt(publicUrlObject.port, 10)
      : context.options.port;

    if (selectedMode === "local-tls") {
      const hostname =
        context.options.hostname ??
        (await context.promptText(
          "Enter the TLS certificate hostname",
          new URL(publicUrl).hostname,
        ));
      const certPath =
        context.options.tlsCertPath ??
        (await context.promptText("Enter the path to your TLS certificate file"));
      const keyPath =
        context.options.tlsKeyPath ??
        (await context.promptText("Enter the path to your TLS private key file"));

      await context.ensureFileExists(certPath, "TLS certificate");
      await context.ensureFileExists(keyPath, "TLS private key");

      return {
        transport: {
          provider: this.id,
          label: this.label,
          mode: "secure_remote",
          publicUrlMode: "static",
          publicWsUrl: publicUrl,
          publicHttpsUrl: wsToHttps(publicUrl),
          localProtocol: "https",
          localPort: localTlsPort,
          localHost: "0.0.0.0",
          tlsTermination: "local",
          tls: {
            source: "manual",
            hostname,
            certPath,
            keyPath,
          },
        },
        setupSummary: [`Public URL: ${publicUrl}`, `Local TLS certificate: ${certPath}`],
      };
    }

    return {
      transport: {
        provider: this.id,
        label: this.label,
        mode: "secure_remote",
        publicUrlMode: "static",
        publicWsUrl: publicUrl,
        publicHttpsUrl: wsToHttps(publicUrl),
        localProtocol: "http",
        localPort: context.options.port,
        localHost: "127.0.0.1",
        tlsTermination: "upstream",
      },
      setupSummary: [
        `Public URL: ${publicUrl}`,
        `Upstream proxy/tunnel forwards to http://127.0.0.1:${context.options.port}`,
      ],
    };
  }

  async startRuntime(_context: RuntimeStartContext): Promise<RuntimeStartResult> {
    return {};
  }

  async doctor(context: RuntimeStartContext): Promise<string[]> {
    const lines = [`Transport provider: ${this.label}`];
    if (context.config.transport.publicWsUrl) {
      lines.push(`Public URL: ${context.config.transport.publicWsUrl}`);
    }
    lines.push(
      `Local origin: ${context.config.transport.localProtocol}://${context.config.transport.localHost}:${context.config.transport.localPort}`,
    );
    return lines;
  }
}
