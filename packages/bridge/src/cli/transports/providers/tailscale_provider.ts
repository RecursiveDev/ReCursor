import path from "path";
import {
  ensureTailscaleTlsMaterial,
  getTailscaleHostname,
  isTailscaleAvailable,
} from "../../tailscale";
import type {
  ResolvedTransportSetup,
  RuntimeStartContext,
  RuntimeStartResult,
  SetupContext,
  TransportDetectionResult,
  TransportProvider,
} from "../types";

export class TailscaleTransportProvider implements TransportProvider {
  readonly id = "tailscale" as const;
  readonly label = "Tailscale";

  async detect(_context: SetupContext): Promise<TransportDetectionResult> {
    const available = await isTailscaleAvailable();
    if (!available) {
      return {
        providerId: this.id,
        label: this.label,
        available: false,
        reason: "CLI not found on PATH.",
      };
    }

    try {
      const hostname = await getTailscaleHostname();
      return {
        providerId: this.id,
        label: this.label,
        available: true,
        recommended: true,
        detail: `Signed in as ${hostname}`,
      };
    } catch (error) {
      return {
        providerId: this.id,
        label: this.label,
        available: false,
        reason: error instanceof Error ? error.message : String(error),
      };
    }
  }

  async setup(context: SetupContext): Promise<ResolvedTransportSetup> {
    const certPath = path.join(context.paths.certDir, "tailscale-bridge.crt");
    const keyPath = path.join(context.paths.certDir, "tailscale-bridge.key");
    const material = await ensureTailscaleTlsMaterial({
      certPath,
      keyPath,
      hostname: context.options.hostname,
    });

    return {
      transport: {
        provider: this.id,
        label: this.label,
        mode: "secure_remote",
        publicUrlMode: "static",
        publicWsUrl: `wss://${material.hostname}:${context.options.port}`,
        publicHttpsUrl: `https://${material.hostname}:${context.options.port}`,
        localProtocol: "https",
        localPort: context.options.port,
        localHost: "0.0.0.0",
        tlsTermination: "local",
        tls: {
          source: "tailscale",
          hostname: material.hostname,
          certPath: material.certPath,
          keyPath: material.keyPath,
        },
        metadata: {
          tailnetHostname: material.hostname,
        },
      },
      setupSummary: [
        `Tailscale hostname: ${material.hostname}`,
        `TLS certificate: ${material.certPath}`,
      ],
    };
  }

  async startRuntime(_context: RuntimeStartContext): Promise<RuntimeStartResult> {
    return {};
  }

  async doctor(context: RuntimeStartContext): Promise<string[]> {
    const lines = [`Transport provider: ${this.label}`];
    if (context.config.transport.tls?.hostname) {
      lines.push(`Tailnet hostname: ${context.config.transport.tls.hostname}`);
    }
    return lines;
  }
}
