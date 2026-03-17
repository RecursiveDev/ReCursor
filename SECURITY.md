# Security Policy

ReCursor is early-stage software. Please treat the current codebase as **pre-release**.

## Supported versions

At this time there are no formal releases. Security fixes (when applicable) will be made on the default branch.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for suspected vulnerabilities.

Instead, use GitHub's private vulnerability reporting (Security Advisories):

- https://github.com/RecursiveDev/ReCursor/security/advisories/new

If that link is not available for your account, contact the repository maintainers through GitHub.

### What to include

Please include:
- A clear description of the issue and potential impact
- Steps to reproduce (proof-of-concept if available)
- Affected component(s) (e.g., Flutter app, bridge server, docs)
- Any logs or screenshots that help explain the issue

### What to expect

We will aim to:
- Acknowledge receipt within **7 days**
- Provide a status update within **14 days**

Timelines may vary depending on severity and maintainers' availability.

## Disclosure policy

We prefer coordinated disclosure:
- Please allow maintainers time to investigate and remediate before public disclosure.
- We will credit reporters in release notes when appropriate (unless you request anonymity).

## Security best practices

- Do not commit API keys, tokens, or secrets.
- Use `.env` files locally and keep them out of git.
- Prefer least-privilege credentials and short-lived tokens.
