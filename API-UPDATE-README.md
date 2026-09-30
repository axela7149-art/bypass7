# macielfilza — Kaygen license validation

`ThreeOneOSFive/AuthenticationViewModel.swift` now uses the exact endpoint `https://kaygen-final.vercel.app/api/public/validate` and the published Kaygen request contract: `key`, `hwid`, and `application_id`.

The configured Kaygen Application ID is `cc9389c9-f2b2-412b-999c-f7bc3ad30a1b` (copied from **Copiar ID da Aplicação** in the Kaygen panel; it is not the iOS bundle identifier). Both first-time login and saved-license revalidation send this ID. The client treats HTTP 2xx as a successful validation, matching the documented `{ status, expires_at }` response, and preserves a saved key during temporary rate limits or server outages.

License keys remain stored in Keychain and are not included in request logs. The updated source ZIP must be rebuilt in Codemagic to produce a new unsigned IPA.
