import fs from "fs/promises";
import os from "os";
import { execFile } from "child_process";
import { promisify } from "util";

const execFileAsync = promisify(execFile);

export function normalizeHostname(value: string): string {
  return value.trim().replace(/\.$/, "");
}

export async function commandExists(
  command: string,
  versionArgs: string[] = ["--version"],
): Promise<boolean> {
  try {
    await execFileAsync(command, versionArgs);
    return true;
  } catch {
    return false;
  }
}

export async function ensureAccessible(filePath: string): Promise<void> {
  await fs.access(filePath);
}

export async function execJson<T>(command: string, args: string[]): Promise<T> {
  const { stdout } = await execFileAsync(command, args);
  return JSON.parse(stdout) as T;
}

export async function findPrivateNetworkCandidates(): Promise<string[]> {
  const interfaces = os.networkInterfaces();
  const candidates = new Set<string>();

  for (const entries of Object.values(interfaces)) {
    for (const entry of entries ?? []) {
      if (entry.internal || entry.family !== "IPv4") {
        continue;
      }

      if (
        entry.address.startsWith("10.") ||
        entry.address.startsWith("192.168.") ||
        /^172\.(1[6-9]|2\d|3[0-1])\./.test(entry.address)
      ) {
        candidates.add(entry.address);
      }
    }
  }

  return [...candidates];
}

export function wsToHttps(url: string): string {
  if (url.startsWith("wss://")) {
    return `https://${url.slice("wss://".length)}`;
  }
  if (url.startsWith("ws://")) {
    return `http://${url.slice("ws://".length)}`;
  }
  return url;
}

export function httpsToWss(url: string): string {
  if (url.startsWith("https://")) {
    return `wss://${url.slice("https://".length)}`;
  }
  if (url.startsWith("http://")) {
    return `ws://${url.slice("http://".length)}`;
  }
  return url;
}

export function sleep(milliseconds: number): Promise<void> {
  return new Promise((resolve) => {
    setTimeout(resolve, milliseconds);
  });
}
