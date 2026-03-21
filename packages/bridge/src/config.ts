import { z } from "zod";

const optionalString = z
  .string()
  .trim()
  .optional()
  .transform((value) => (value && value.length > 0 ? value : undefined));

const configSchema = z.object({
  PORT: z
    .string()
    .default("3000")
    .transform((value) => Number.parseInt(value, 10)),
  BRIDGE_TOKEN: z.string().min(1, "BRIDGE_TOKEN is required"),
  HOOK_TOKEN: z.string().min(1, "HOOK_TOKEN is required"),
  ANTHROPIC_API_KEY: optionalString,
  AGENT_MODEL: z.string().default("claude-opus-4-6"),
  AGENT_MAX_ITERATIONS: z
    .string()
    .default("25")
    .transform((value) => Number.parseInt(value, 10)),
  ALLOWED_PROJECT_ROOT: z.string().min(1, "ALLOWED_PROJECT_ROOT is required"),
  BRIDGE_TLS_CERT_PATH: optionalString,
  BRIDGE_TLS_KEY_PATH: optionalString,
});

function loadConfig() {
  const result = configSchema.safeParse(process.env);
  if (!result.success) {
    const messages = result.error.errors
      .map((error) => `  ${error.path.join(".")}: ${error.message}`)
      .join("\n");
    throw new Error(`Configuration error:\n${messages}`);
  }

  const config = result.data;
  const hasTlsCert = Boolean(config.BRIDGE_TLS_CERT_PATH);
  const hasTlsKey = Boolean(config.BRIDGE_TLS_KEY_PATH);

  if (hasTlsCert !== hasTlsKey) {
    throw new Error(
      "Configuration error:\n  BRIDGE_TLS_CERT_PATH and BRIDGE_TLS_KEY_PATH must be provided together",
    );
  }

  return {
    ...config,
    TLS_ENABLED: hasTlsCert && hasTlsKey,
  };
}

export const config = loadConfig();

export type Config = typeof config;
