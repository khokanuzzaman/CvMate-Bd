# Test fonts

Static font files used **only by tests** (`test/screenshots/`), so screenshots
render with the real brand fonts instead of the test environment's placeholder
font, and so tests never touch the network. They are not declared in
`pubspec.yaml`, so they are not bundled into the app.

| File | Family / weight |
|---|---|
| `Sora-SemiBold.ttf`, `Sora-Bold.ttf` | Sora 600, 700 |
| `PlusJakartaSans-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf`, `-Bold.ttf` | Plus Jakarta Sans 400, 500, 600, 700 |

These are the exact files `google_fonts` downloads at runtime (file names in the
`google_fonts` package are their SHA-256 hashes; each was verified when added).

Both families are licensed under the SIL Open Font License 1.1
(<https://openfontlicense.org>): Sora © The Sora Project Authors, Plus Jakarta
Sans © The Plus Jakarta Sans Project Authors.
