import fs from "fs/promises";
import path from "path";
import { z } from "zod";
import type { ReCursorPaths } from "./paths";
import type { StoredTransportConfig } from "./transports/types";

const claudePluginSchema = z.object({
  pluginDir: z.string().min(1),
  installedAt: z.string().min(1),
  hookCommand: z.string().min(1),
});

const transportSchema: z.ZodType<StoredTransportConfig> = z.object({
  provider: z.enum(["tailscale", "cloudflare", "ngrok", "manual"]),
  label: z.string().min(1),
  mode: z.enum(["local_only", "private_network", "secure_remote", "direct_public"]),
  publicUrlMode: z.enum(["static", "dynamic"]),
  publicWsUrl: z.string().url().optional(),
  publicHttpsUrl: z.string().url().optional(),
  localProtocol: z.enum(["http", "https"]),
  localPort: z.number().int().positive(),
  localHost: z.string().min(1),
  tlsTermination: z.enum(["local", "upstream"]),
  tls: z
    .object({
      source: z.enum(["tailscale", "manual"]),
      hostname: z.string().min(1),
      certPath: z.string().min(1),
      keyPath: z.string().min(1),
    })
    .optional(),
  metadata: z.record(z.string()).optional(),
});

const storedConfigV2Schema = z.object({
  version: z.literal(2),
  createdAt: z.string().min(1),
  updatedAt: z.string().min(1),
  bridgeToken: z.string().min(1),
  hookToken: z.string().min(1),
  allowedProjectRoot: z.string().min(1),
  anthropicApiKey: z.string().min(1).optional(),
  transport: transportSchema,
  claudePlugin: claudePluginSchema,
});

const storedConfigV1Schema = z.object({
  version: z.literal(1),
  createdAt: z.string().min(1),
  updatedAt: z.string().min(1),
  bridgeToken: z.string().min(1),
  hookToken: z.string().min(1),
  port: z.number().int().positive(),
  allowedProjectRoot: z.string().min(1),
  anthropicApiKey: z.string().min(1).optional(),
  bridgeUrl: z.string().url(),
  httpUrl: z.string().url(),
  tls: z.object({
    source: z.enum(["tailscale", "manual"]),
    hostname: z.string().min(1),
    certPath: z.string().min(1),
    keyPath: z.string().min(1),
  }),
  claudePlugin: claudePluginSchema,
});

export type StoredBridgeConfig = z.infer<typeof storedConfigV2Schema>;

type StoredBridgeConfigV1 = z.infer<typeof storedConfigV1Schema>;

function migrateV1ToV2(config: StoredBridgeConfigV1): StoredBridgeConfig {
  const provider = config.tls.source === "tailscale" ? "tailscale" : "manual";
  const label = provider === "tailscale" ? "Tailscale" : "Manual / Existing Remote Endpoint";

  return {
    version: 2,
    createdAt: config.createdAt,
    updatedAt: config.updatedAt,
    bridgeToken: config.bridgeToken,
    hookToken: config.hookToken,
    allowedProjectRoot: config.allowedProjectRoot,
    anthropicApiKey: config.anthropicApiKey,
    transport: {
      provider,
      label,
      mode: "secure_remote",
      publicUrlMode: "static",
      publicWsUrl: config.bridgeUrl,
      publicHttpsUrl: config.httpUrl,
      localProtocol: "https",
      localPort: config.port,
      localHost: "0.0.0.0",
      tlsTermination: "local",
      tls: config.tls,
    },
    claudePlugin: config.claudePlugin,
  };
}

export async function ensureCliDirectories(paths: ReCursorPaths): Promise<void> {
  await fs.mkdir(paths.configDir, { recursive: true });
  await fs.mkdir(paths.certDir, { recursive: true });
  await fs.mkdir(paths.claudeSettingsDir, { recursive: true });
  await fs.mkdir(paths.recursorMarketplaceDir, { recursive: true });
}

export async function loadStoredConfig(paths: ReCursorPaths): Promise<StoredBridgeConfig | null> {
  try {
    const content = await fs.readFile(paths.configPath, "utf8");
    const parsed = JSON.parse(content) as unknown;

    const v2 = storedConfigV2Schema.safeParse(parsed);
    if (v2.success) {
      return v2.data;
    }

    const v1 = storedConfigV1Schema.safeParse(parsed);
    if (v1.success) {
      return migrateV1ToV2(v1.data);
    }

    throw new Error(`Invalid ReCursor CLI config: ${v2.error.message}`);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return null;
    }
    throw error;
  }
}

export async function saveStoredConfig(
  paths: ReCursorPaths,
  config: StoredBridgeConfig,
): Promise<void> {
  await ensureCliDirectories(paths);
  await fs.writeFile(paths.configPath, `${JSON.stringify(config, null, 2)}\n`, "utf8");
}

export function buildStoredConfig(input: {
  bridgeToken: string;
  hookToken: string;
  allowedProjectRoot: string;
  anthropicApiKey?: string;
  transport: StoredTransportConfig;
  claudePlugin: StoredBridgeConfig["claudePlugin"];
  existingCreatedAt?: string;
}): StoredBridgeConfig {
  const now = new Date().toISOString();

  return {
    version: 2,
    createdAt: input.existingCreatedAt ?? now,
    updatedAt: now,
    bridgeToken: input.bridgeToken,
    hookToken: input.hookToken,
    allowedProjectRoot: path.resolve(input.allowedProjectRoot),
    anthropicApiKey: input.anthropicApiKey,
    transport: input.transport,
    claudePlugin: input.claudePlugin,
  };
}
