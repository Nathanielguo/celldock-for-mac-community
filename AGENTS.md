# CellDock project instructions

- Communicate with the user in Chinese; keep code and technical identifiers in English.
- Preserve the downloaded source archive and all existing user data. Never permanently delete project or installed-app files; move replaced items to a recoverable backup or the macOS Trash.
- Do not overwrite `/Applications/CellDock.app` without first preserving the existing app as a timestamped backup.
- Treat code signing, Keychain identities, privileged helpers, LaunchDaemons, network order, modem firmware, eSIM changes, and module-side writes as security-sensitive operations. Resolve exact targets and verify them independently after changes.
- Build the personal community edition only. Do not reintroduce account login, licensing, trial, telemetry, or commercial-service dependencies.
- Keep the app, `CellDockNetworkHelper`, and `CellDockVoWiFiRuntime` signed by the same certificate, with their existing identifiers.
- Prefer local, project-scoped toolchains and vendored dependencies. Do not install global dependencies unless the user explicitly authorizes them.
- Before installation, run `scripts/run_tests.sh`, build from the pinned `Package.resolved`, verify archive contents and signatures, and confirm no credentials are packaged.
- After installation, verify the installed version, code signature and entitlements, helper hashes and labels, running executable path, macOS Microphone/Contacts entries, and QDC507 detection. Do not claim full modem functionality without a real-device flow.
