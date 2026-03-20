# CI/CD Pipeline

> GitHub Actions + Fastlane for building, testing, and distributing ReCursor to iOS and Android.

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

---

## GitHub Actions Workflow Structure

Three jobs:
1. **`test`** — runs on `ubuntu-latest`: analyze, unit tests, widget tests, golden tests
2. **`build-android`** — runs on `ubuntu-latest`: build AAB, upload to Play Store internal track
3. **`build-ios`** — runs on `macos-latest` (required for Xcode): build IPA, upload to TestFlight

---

## Workflow Configuration

```yaml
# .github/workflows/test.yml
name: Test

on:
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
        working-directory: apps/mobile
      
      - name: Analyze
        run: flutter analyze
        working-directory: apps/mobile
      
      - name: Run tests
        run: flutter test
        working-directory: apps/mobile
```

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # Same as test.yml

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Setup Fastlane
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      
      - name: Decode keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks
        working-directory: apps/mobile
      
      - name: Build AAB
        run: fastlane android deploy
        working-directory: apps/mobile
        env:
          KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Setup Fastlane
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      
      - name: Build IPA
        run: fastlane ios deploy
        working-directory: apps/mobile
        env:
          MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
          FASTLANE_PASSWORD: ${{ secrets.FASTLANE_PASSWORD }}
```

---

## iOS Code Signing (Fastlane Match)

- Store encrypted certificates and provisioning profiles in a **private Git repo**.
- Required GitHub Secrets:
  - `MATCH_GIT_BASIC_AUTHORIZATION` — base64-encoded `username:PAT`
  - `MATCH_PASSWORD` — encryption passphrase
  - App Store Connect API key (preferred over `FASTLANE_PASSWORD` to avoid 2FA issues)
- Use `setup_ci` in the Fastlane lane to create a temporary keychain on the CI runner.

### Fastfile (iOS)

```ruby
# fastlane/Fastfile
platform :ios do
  desc "Deploy iOS app to TestFlight"
  lane :deploy do
    setup_ci
    
    match(
      type: "appstore",
      readonly: is_ci,
    )
    
    build_app(
      scheme: "Runner",
      workspace: "ios/Runner.xcworkspace",
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
    )
  end
end
```

---

## Android Code Signing

- Store the keystore as a **base64-encoded GitHub Secret** (`KEYSTORE_BASE64`).
- Decode in workflow: `echo $KEYSTORE_BASE64 | base64 --decode > android/app/keystore.jks`
- Reference key alias and passwords from secrets in `key.properties`.
- Upload to Play Store internal track via Fastlane's `supply` action.
- **Note:** First release must be uploaded manually via Play Console.

### Fastfile (Android)

```ruby
# fastlane/Fastfile
platform :android do
  desc "Deploy Android app to Play Store"
  lane :deploy do
    build_android_app(
      task: "bundle",
      build_type: "release",
    )
    
    upload_to_play_store(
      track: "internal",
      release_status: "draft",
    )
  end
end
```

---

## Key Principles

- **Never echo secret values in logs.**
- PR builds run tests only, never deploy.
- Use branch-based triggers: PRs -> test; `main` push -> test + deploy.
- Pin Flutter version in CI to match local development (`subosito/flutter-action`).
- Cache pub dependencies and build artifacts between runs.

---

## Alternative: Codemagic

- Purpose-built for Flutter with macOS build machines included.
- Built-in code signing management (no Fastlane config needed).
- Costs money but saves significant setup time, especially for iOS.
- Consider if GitHub Actions macOS runner costs or complexity become prohibitive.

---

## Related Documentation

- [Testing Strategy](/operations/testing-strategy/) — Testing approach
- [Architecture Overview](/architecture/system-overview/) — System architecture

---

*Last updated: 2026-03-17*
