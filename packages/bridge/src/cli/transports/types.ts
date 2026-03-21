import type { StoredBridgeConfig } from "../config_store";
import type { ReCursorPaths } from "../paths";

export type TransportProviderId = "tailscale" | "cloudflare" | "ngrok" | "manual";
export type TransportMode = "local_only" | "private_network" | "secure_remote" | "direct_public";
export type TlsTermination = "local" | "upstream";
export type LocalProtocol = "http" | "https";

export interface TransportDetectionResult {
  providerId: TransportProviderId;
  label: string;
  available: boolean;
  recommended?: boolean;
  detail?: string;
  reason?: string;
}

export interface ConfigurableSetupOptions {
  port: number;
  projectRoot: string;
  anthropicApiKey?: string;
  hostname?: string;
  tlsCertPath?: string;
  tlsKeyPath?: string;
  publicUrl?: string;
  localMode?: "local-tls" | "upstream-proxy";
}

export interface SetupContext {
  paths: ReCursorPaths;
  options: ConfigurableSetupOptions;
  existingConfig: StoredBridgeConfig | null;
  promptText(message: string, defaultValue?: string): Promise<string>;
  promptSelect(message: string, options: Array<{ value: string; label: string }>): Promise<string>;
  ensureFileExists(filePath: string, description: string): Promise<void>;
}

export interface RuntimeStartResult {
  publicWsUrl?: string;
  publicHttpsUrl?: string;
  stop?: () => Promise<void>;
}

export interface StoredTransportConfig {
  provider: TransportProviderId;
  label: string;
  mode: TransportMode;
  publicUrlMode: "static" | "dynamic";
  publicWsUrl?: string;
  publicHttpsUrl?: string;
  localProtocol: LocalProtocol;
  localPort: number;
  localHost: string;
  tlsTermination: TlsTermination;
  tls?: {
    source: "tailscale" | "manual";
    hostname: string;
    certPath: string;
    keyPath: string;
  };
  metadata?: Record<string, string>;
}

export interface ResolvedTransportSetup {
  transport: StoredTransportConfig;
  setupSummary: string[];
}

export interface RuntimeStartContext {
  config: StoredBridgeConfig;
  log(message: string): void;
}

export interface TransportProvider {
  id: TransportProviderId;
  label: string;
  detect(context: SetupContext): Promise<TransportDetectionResult>;
  setup(context: SetupContext): Promise<ResolvedTransportSetup>;
  startRuntime?(context: RuntimeStartContext): Promise<RuntimeStartResult>;
  doctor?(context: RuntimeStartContext): Promise<string[]>;
}
