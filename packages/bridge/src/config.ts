import { z } from "zod";

const configSchema = z.object({
  PORT: z
    .string()
    .default("3000")
    .transform((v) => parseInt(v, 10)),
  BRIDGE_TOKEN: z.string().min(1, "BRIDGE_TOKEN is required"),
  HOOK_TOKEN: z.string().min(1, "HOOK_TOKEN is required"),
  ANTHROPIC_API_KEY: z.string().min(1, "ANTHROPIC_API_KEY is required"),
  AGENT_MODEL: z.string().default("claude-opus-4-6"),
  ALLOWED_PROJECT_ROOT: z.string().min(1, "ALLOWED_PROJECT_ROOT is required"),
});

function loadConfig() {
  const result = configSchema.safeParse(process.env);
  if (!result.success) {
    const messages = result.error.errors
      .map((e) => `  ${e.path.join(".")}: ${e.message}`)
      .join("\n");
    throw new Error(`Configuration error:\n${messages}`);
  }
  return result.data;
}

export const config = loadConfig();

export type Config = typeof config;
