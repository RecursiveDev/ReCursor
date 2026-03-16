# Security Architecture

> Best practices for securing the WebSocket bridge between the mobile app and the coding agent.

---

## Network Layer

- **Use Tailscale as the primary networking layer.** It wraps WireGuard encryption, handles NAT traversal, and creates a zero-config mesh VPN between phone and dev machine. DERP relay servers never see unencrypted data.
- **Always use `wss://` (WebSocket Secure).** TLS at the application layer + WireGuard at the network layer = defense in depth.
- **Never expose the bridge on a public IP.** The bridge should only be reachable within the Tailscale network or via SSH tunnel.

## Authentication

- **Require a strong API key (32+ character random token) on every WebSocket handshake.** Pass it as a header or in the initial WebSocket message.
- **Store tokens in `flutter_secure_storage`** (backed by Keychain on iOS, EncryptedSharedPreferences on Android).
- **Rate-limit failed auth attempts** on the bridge server to prevent brute force.
- **QR code pairing** encodes bridge URL + one-time auth token for initial setup.

## Certificate Pinning

- Flutter supports SSL pinning via `SecurityContext` with certificate chain files from assets.
- **Pin the public key**, not the certificate itself — more resilient to cert renewals.
- Maintain backup pins per OWASP guidance to prevent app breakage.
- Optional when running over Tailscale (WireGuard already provides authentication).

## Bridge Authorization

- The bridge server is the security boundary — it must enforce its own authorization layer.
- **Allowlist of permitted operations** (e.g., file read yes, `rm -rf /` no).
- **Enforce working directory boundaries** — the agent should only access the project directory.
- **Log all commands** sent through the bridge for audit.
- **Separate bridge auth from agent auth** — compromising one shouldn't compromise the other.

## Data in Transit

- All WebSocket messages should be JSON with a defined schema.
- Sensitive data (tokens, keys found in code) should be flagged and optionally redacted in transit.
- Consider message signing (HMAC) for critical operations (git push, file delete) as an additional integrity check.
