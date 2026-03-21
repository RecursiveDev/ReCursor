import QRCode from "qrcode";

export interface PairingPayload {
  url: string;
  token: string;
}

export function buildPairingPayload(payload: PairingPayload): string {
  return JSON.stringify({
    url: payload.url,
    token: payload.token,
  });
}

export async function renderPairingQr(payload: PairingPayload): Promise<string> {
  return QRCode.toString(buildPairingPayload(payload), {
    type: "terminal",
    small: true,
  });
}
