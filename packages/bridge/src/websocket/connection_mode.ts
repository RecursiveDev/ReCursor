export type ConnectionMode =
  | "local_only"
  | "private_network"
  | "secure_remote"
  | "direct_public"
  | "misconfigured";

export interface ConnectionModeMetadata {
  remoteAddress?: string;
  host?: string;
  secureTransport: boolean;
}

function normalizeAddress(value?: string): string | undefined {
  if (!value) {
    return undefined;
  }

  const trimmed = value.trim().toLowerCase();
  const withoutPort = trimmed.startsWith("[")
    ? trimmed.replace(/^\[([^\]]+)\](?::\d+)?$/, "$1")
    : trimmed.replace(/:(\d+)$/, "");

  if (withoutPort.startsWith("::ffff:")) {
    return withoutPort.slice(7);
  }

  return withoutPort;
}

function isLoopbackAddress(value?: string): boolean {
  const normalized = normalizeAddress(value);
  return normalized === "127.0.0.1" || normalized === "::1" || normalized === "localhost";
}

function isPrivateIpv4(value: string): boolean {
  if (value.startsWith("10.")) {
    return true;
  }

  if (value.startsWith("192.168.")) {
    return true;
  }

  const match = /^172\.(\d{1,3})\./.exec(value);
  if (!match) {
    return false;
  }

  const secondOctet = Number.parseInt(match[1] ?? "0", 10);
  return secondOctet >= 16 && secondOctet <= 31;
}

function isTailscaleIpv4(value: string): boolean {
  const match = /^(\d{1,3})\.(\d{1,3})\./.exec(value);
  if (!match) {
    return false;
  }

  const firstOctet = Number.parseInt(match[1] ?? "0", 10);
  const secondOctet = Number.parseInt(match[2] ?? "0", 10);

  return firstOctet === 100 && secondOctet >= 64 && secondOctet <= 127;
}

function isPrivateAddress(value?: string): boolean {
  const normalized = normalizeAddress(value);
  if (!normalized) {
    return false;
  }

  if (normalized.includes(":")) {
    return (
      normalized.startsWith("fc") || normalized.startsWith("fd") || normalized.startsWith("fe80:")
    );
  }

  return isPrivateIpv4(normalized);
}

function normalizeHost(value?: string): string | undefined {
  if (!value) {
    return undefined;
  }

  return value
    .trim()
    .toLowerCase()
    .replace(/:(\d+)$/, "");
}

function isSecureTunnelAddress(value?: string, host?: string): boolean {
  const normalizedAddress = normalizeAddress(value);
  const normalizedHost = normalizeHost(host);

  if (
    normalizedHost?.endsWith(".tailnet.ts.net") ||
    normalizedHost?.endsWith(".ts.net") ||
    normalizedHost?.endsWith(".trycloudflare.com")
  ) {
    return true;
  }

  if (!normalizedAddress) {
    return false;
  }

  if (normalizedAddress.includes(":")) {
    return normalizedAddress.startsWith("fd7a:115c:a1e0:");
  }

  return isTailscaleIpv4(normalizedAddress);
}

export function detectConnectionMode(metadata: ConnectionModeMetadata): ConnectionMode {
  if (!metadata.secureTransport) {
    return "misconfigured";
  }

  if (isLoopbackAddress(metadata.remoteAddress) || isLoopbackAddress(metadata.host)) {
    return "local_only";
  }

  if (isSecureTunnelAddress(metadata.remoteAddress, metadata.host)) {
    return "secure_remote";
  }

  if (isPrivateAddress(metadata.remoteAddress) || isPrivateAddress(metadata.host)) {
    return "private_network";
  }

  return "direct_public";
}

export function describeConnectionMode(
  mode: ConnectionMode,
  metadata: Pick<ConnectionModeMetadata, "remoteAddress" | "host">,
): string {
  const address = metadata.host ?? metadata.remoteAddress ?? "unknown";

  switch (mode) {
    case "local_only":
      return `Loopback connection (${address})`;
    case "private_network":
      return `Private network connection (${address})`;
    case "secure_remote":
      return `Secure tunnel connection (${address})`;
    case "direct_public":
      return `Direct public connection (${address})`;
    case "misconfigured":
      return "Unencrypted transport detected";
  }
}

export function buildBridgeUrl(host?: string, secureTransport: boolean = true): string {
  const normalizedHost = host?.trim() || "bridge.local";
  return `${secureTransport ? "wss" : "ws"}://${normalizedHost}`;
}
