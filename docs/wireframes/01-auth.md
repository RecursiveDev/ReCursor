# 01 - Authentication Screens

> Phase 1 — Login, OAuth, and onboarding.

---

## 1A. Splash Screen

```
+---------------------------------------+
|                                       |
|                                       |
|                                       |
|                                       |
|            [ App Logo ]               |
|                                       |
|            ReCursor                   |
|     AI Coding Agents, Anywhere        |
|                                       |
|                                       |
|           ( loading spinner )         |
|                                       |
|                                       |
|                                       |
+---------------------------------------+
```

**Behavior:**
- Auto-checks for stored auth token
- If valid token found -> navigate to Bridge Pairing or Main Shell
- If no token -> navigate to Login Screen
- Duration: 1-2s max

---

## 1B. Login Screen

```
+---------------------------------------+
|              ReCursor                 |
+---------------------------------------+
|                                       |
|            [ App Logo ]               |
|                                       |
|   Control your AI coding agents       |
|   from anywhere.                      |
|                                       |
|                                       |
|  +----------------------------------+ |
|  |                                  | |
|  |   [G]  Sign in with GitHub       | |
|  |                                  | |
|  +----------------------------------+ |
|                                       |
|                                       |
|         ---- or ----                  |
|                                       |
|                                       |
|  +----------------------------------+ |
|  |  Personal Access Token           | |
|  |  +----------------------------+  | |
|  |  | ghp_xxxxxxxxxxxxxxxxxxxx   |  | |
|  |  +----------------------------+  | |
|  |                                  | |
|  |  [    Connect with PAT       ]   | |
|  +----------------------------------+ |
|                                       |
|                                       |
|   By continuing, you agree to the     |
|   Terms of Service & Privacy Policy   |
|                                       |
+---------------------------------------+
```

**Elements:**
- GitHub OAuth button (primary, filled, with GitHub icon)
- PAT input section (expandable/collapsible, secondary option)
- PAT field: obscured text input with show/hide toggle
- Legal links at bottom

**States:**
- Default: OAuth button prominent, PAT collapsed
- PAT expanded: text field visible with connect button
- Loading: button shows spinner, inputs disabled
- Error: red banner below input with message ("Invalid token", "Auth failed")

---

## 1C. OAuth WebView

```
+---------------------------------------+
| [X]         GitHub Login              |
+---------------------------------------+
|                                       |
|  +----------------------------------+ |
|  |                                  | |
|  |     github.com/login/oauth      | |
|  |                                  | |
|  |   Username or email address      | |
|  |   +----------------------------+ | |
|  |   |                            | | |
|  |   +----------------------------+ | |
|  |                                  | |
|  |   Password                       | |
|  |   +----------------------------+ | |
|  |   |                            | | |
|  |   +----------------------------+ | |
|  |                                  | |
|  |   [ Sign in ]                    | |
|  |                                  | |
|  +----------------------------------+ |
|                                       |
|  ( progress bar at top of webview )   |
|                                       |
+---------------------------------------+
```

**Behavior:**
- Opens GitHub OAuth authorize URL in in-app WebView
- Intercepts redirect to `remotecli://authed?code=xxx`
- Exchanges code for token in background
- On success: close WebView, navigate to Bridge Pairing
- On failure: show error toast, return to Login Screen
- [X] button cancels and returns to Login
