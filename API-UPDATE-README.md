# BYPASS7-PROXY — API validation update

Updated `ThreeOneOSFive/AuthenticationViewModel.swift` to:
- use `https://ipakeydash-swz9qhsx.manus.space/v`
- POST `key`, `hwid`, `application_id`, and `platform: "ios"`
- keep the existing success contract (`status == "success"`)

The source project is ready to open in Xcode and build/sign. The IPA itself must be rebuilt and signed on a macOS/Xcode environment with the appropriate signing identity.
