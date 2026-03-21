import { CloudflareTransportProvider } from "./providers/cloudflare_provider";
import { ManualTransportProvider } from "./providers/manual_provider";
import { NgrokTransportProvider } from "./providers/ngrok_provider";
import { TailscaleTransportProvider } from "./providers/tailscale_provider";
import type { TransportProvider, TransportProviderId } from "./types";

const providers: TransportProvider[] = [
  new TailscaleTransportProvider(),
  new CloudflareTransportProvider(),
  new NgrokTransportProvider(),
  new ManualTransportProvider(),
];

export function listTransportProviders(): TransportProvider[] {
  return [...providers];
}

export function getTransportProvider(id: TransportProviderId): TransportProvider {
  const provider = providers.find((candidate) => candidate.id === id);
  if (!provider) {
    throw new Error(`Unknown transport provider: ${id}`);
  }
  return provider;
}
