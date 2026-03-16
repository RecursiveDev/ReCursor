# CI/CD Pipeline

> GitHub Actions + Fastlane for building, testing, and distributing to iOS and Android.

---

## Pipeline Overview

```
PR opened/updated:
  [flutter analyze] -> [flutter test] -> (pass/fail)

Push to main:
  [flutter analyze] -> [flutter test] -> [build Android APK/AAB] -> [build iOS IPA]
                                              |                          |
                                         Play Store              TestFlight
                                        (internal track)
```

## GitHub Actions Workflow Structure

Three jobs:
1. **`test`** — runs on `ubuntu-latest`: analyze, unit tests, widget tests, golden tests
2. **`build-android`** — runs on `ubuntu-latest`: build AAB, upload to Play Store internal track
3. **`build-ios`** — runs on `macos-latest` (required for Xcode): build IPA, upload to TestFlight

## iOS Code Signing (Fastlane Match)

- Store encrypted certificates and provisioning profiles in a **private Git repo**.
- Required GitHub Secrets:
  - `MATCH_GIT_BASIC_AUTHORIZATION` — base64-encoded `username:PAT`
  - `MATCH_PASSWORD` — encryption passphrase
  - App Store Connect API key (preferred over `FASTLANE_PASSWORD` to avoid 2FA issues)
- Use `setup_ci` in the Fastlane lane to create a temporary keychain on the CI runner.

## Android Code Signing

- Store the keystore as a **base64-encoded GitHub Secret** (`KEYSTORE_BASE64`).
- Decode in workflow: `echo $KEYSTORE_BASE64 | base64 --decode > android/app/keystore.jks`
- Reference key alias and passwords from secrets in `key.properties`.
- Upload to Play Store internal track via Fastlane's `supply` action.
- **Note:** First release must be uploaded manually via Play Console.

## Key Principles

- **Never echo secret values in logs.**
- PR builds run tests only, never deploy.
- Use branch-based triggers: PRs -> test; `main` push -> test + deploy.
- Pin Flutter version in CI to match local development (`subosito/flutter-action`).
- Cache pub dependencies and build artifacts between runs.

## Alternative: Codemagic

- Purpose-built for Flutter with macOS build machines included.
- Built-in code signing management (no Fastlane config needed).
- Costs money but saves significant setup time, especially for iOS.
- Consider if GitHub Actions macOS runner costs or complexity become prohibitive.
