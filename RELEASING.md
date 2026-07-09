# Releasing OnlyEQ

OnlyEQ uses Sparkle 2 for signed automatic updates. The Ed25519 private key stays in the macOS login Keychain under the account `zollans.OnlyEQ`; never commit or upload an exported private key. The corresponding public key lives in `Resources/Info.plist`.

For each release:

1. Increment both `CFBundleVersion` and `CFBundleShortVersionString` in `Resources/Info.plist`.
2. Add `release-notes/VERSION.md`.
3. Run `./scripts/prepare-release.sh VERSION`.
4. Commit the source changes and generated `appcast.xml`, merge them to `main`, and tag the merged commit as `vVERSION`.
5. Publish `build/OnlyEQ.app.zip` and `appcast.xml` as release assets, using the versioned release-notes file as the GitHub release notes.

Example publishing command after the release commit is on `main`:

```sh
gh release create v1.1.0 \
  build/OnlyEQ.app.zip appcast.xml \
  --title "OnlyEQ 1.1.0" \
  --notes-file release-notes/1.1.0.md \
  --target main
```

The appcast is served from `https://raw.githubusercontent.com/zollans/OnlyEQ/main/appcast.xml`. Update archives must retain the app bundle and Sparkle framework symlinks; `prepare-release.sh` uses `ditto` for that reason.

OnlyEQ is ad-hoc signed rather than Developer ID signed or notarized. Sparkle archive signatures authenticate updates, but losing the Ed25519 private key would require another manual bridge release because Developer ID key rotation is unavailable.
