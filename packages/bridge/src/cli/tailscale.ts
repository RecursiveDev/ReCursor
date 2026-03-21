import fs from "fs/promises";
import { execFile } from "child_process";
import { promisify } from "util";

const execFileAsync = promisify(execFile);

interface TailscaleStatusResult {
  Self?: {
    DNSName?: string;
  };
}

export interface TailscaleTlsMaterial {
  hostname: string;
  certPath: string;
  keyPath: string;
}

function normalizeHostname(value: string): string {
  return value.trim().replace(/\.$/, "");
}

export async function isTailscaleAvailable(): Promise<boolean> {
  try {
    await execFileAsync("tailscale", ["version"]);
    return true;
  } catch {
    return false;
  }
}

export async function getTailscaleHostname(): Promise<string> {
  const { stdout } = await execFileAsync("tailscale", ["status", "--json"]);
  const status = JSON.parse(stdout) as TailscaleStatusResult;
  const hostname = status.Self?.DNSName;

  if (!hostname) {
    throw new Error("Tailscale is installed, but no tailnet DNS name was reported.");
  }

  return normalizeHostname(hostname);
}

export async function ensureTailscaleTlsMaterial(input: {
  certPath: string;
  keyPath: string;
  hostname?: string;
}): Promise<TailscaleTlsMaterial> {
  const hostname = input.hostname
    ? normalizeHostname(input.hostname)
    : await getTailscaleHostname();

  await execFileAsync("tailscale", [
    "cert",
    "--cert-file",
    input.certPath,
    "--key-file",
    input.keyPath,
    hostname,
  ]);

  await Promise.all([fs.access(input.certPath), fs.access(input.keyPath)]);

  return {
    hostname,
    certPath: input.certPath,
    keyPath: input.keyPath,
  };
}
