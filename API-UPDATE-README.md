# BYPASS7-PROXY — API validation update

Updated `ThreeOneOSFive/AuthenticationViewModel.swift` to:
- use `https://kaygen-final.vercel.app/api/public/validate`
- POST `key`, `hwid`, and `platform: "ios"` (the existing client payload)
- require the existing success contract (`status == "success"` and `valid == true`)

The source project is ready to open in Xcode and build/sign. The IPA itself must be rebuilt and signed on a macOS/Xcode environment with the appropriate signing identity.
