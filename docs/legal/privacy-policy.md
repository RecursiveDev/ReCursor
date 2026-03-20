# Privacy Policy

**Last updated: 2026-03-17**

## Overview
ReCursor ("we", "our", "the app") is an open-source mobile application for monitoring AI coding agent workflows. This policy describes what data we collect, how we use it, and your rights.

## Data We Collect

### Data stored locally on your device
- **Bridge connection**: Bridge server URLs and device pairing tokens, stored encrypted via secure keychain
- **Agent configurations**: Working directories and agent preferences, stored in the app's local database
- **Session history**: Chat messages and tool call records from your AI agent sessions, stored locally in SQLite
- **App preferences**: Theme settings and notification preferences, stored in local key-value storage

### Data we do NOT collect
- We do not operate any servers or collect any telemetry by default
- We do not transmit your code, files, or session data to any third party
- We do not use advertising identifiers
- We do not track your location

### Optional analytics (opt-in only)
If you explicitly enable analytics in Settings, the app logs anonymized usage events locally. These events are never transmitted unless you configure a self-hosted analytics endpoint.

## Data Transmission
ReCursor communicates only with:
1. **Your bridge server**: The app connects directly to the ReCursor bridge server running on your own machine via WebSocket. You control this server.
2. **Anthropic API**: If using the Agent SDK integration, requests are made via your bridge server using your own API key. ReCursor does not have access to your Anthropic API key.

## Security
- Bridge pairing tokens are stored using iOS Keychain / Android Keystore via `flutter_secure_storage`
- All bridge connections use WSS (TLS-encrypted WebSocket)
- We recommend using Tailscale or WireGuard for bridge connectivity

## Your Rights
You can delete all locally stored data by uninstalling the app or using "Reset App" in Settings.

## Changes
We will update this policy as the app evolves. Check the app's GitHub repository for the latest version.

## Contact
Questions? Open an issue at https://github.com/RecursiveDev/ReCursor/issues
