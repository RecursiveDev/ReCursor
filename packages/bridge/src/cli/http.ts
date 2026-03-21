import type { StoredBridgeConfig } from "./config_store";

function asErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function resolvePublicHttpsUrl(config: StoredBridgeConfig): string {
  const url = config.transport.publicHttpsUrl;
  if (!url) {
    throw new Error(
      "No public bridge HTTPS URL is currently available. Start the bridge first so the selected transport can publish one.",
    );
  }
  return url;
}

export async function postHookEvent(
  config: StoredBridgeConfig,
  body: string,
): Promise<{ ok: boolean; status: number; body: string }> {
  const response = await fetch(`${resolvePublicHttpsUrl(config)}/hooks/event`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${config.hookToken}`,
    },
    body,
  });

  return {
    ok: response.ok,
    status: response.status,
    body: await response.text(),
  };
}

export async function fetchBridgeHealth(
  config: StoredBridgeConfig,
): Promise<{ ok: boolean; status: number; body: string; message?: string }> {
  try {
    const response = await fetch(`${resolvePublicHttpsUrl(config)}/api/v1/health`, {
      headers: {
        authorization: `Bearer ${config.bridgeToken}`,
      },
    });

    return {
      ok: response.ok,
      status: response.status,
      body: await response.text(),
    };
  } catch (error) {
    return {
      ok: false,
      status: 0,
      body: "",
      message: asErrorMessage(error),
    };
  }
}
