# App Store submission notes — Bread & Butter

Reference for submitting the watchOS app. Copy the review notes verbatim; use
the rest as a checklist.

## App Review notes (paste into App Store Connect → App Review Information → Notes)

> Bread & Butter is a watchOS‑only app. It reads heart rate from Apple Health
> and shows an estimated fat‑vs‑carbohydrate fuel split and heart‑rate zone.
>
> To test on a real Apple Watch (live heart rate is not available in the
> Simulator — please use a physical device):
>
> 1. Launch Bread & Butter and allow the Health permission prompt.
> 2. To see live data, EITHER:
>    a. Start any workout in Apple's Workout app (the app reads those HR
>       samples), OR
>    b. In the app's Settings, turn on "Live HR when open" — the app then starts
>       its own lightweight heart‑rate session so it works without a workout.
> 3. The butter/baguette bar, percentages, BPM, and zone appear and update live.
>
> Notes for review:
> - Live heart rate requires the watch's sensor, which only streams during a
>   session. By default the app is a companion that reads an existing workout's
>   HR. The optional "Live HR when open" setting starts a lightweight HealthKit
>   workout session; that session is DISCARDED when the app is backgrounded — it
>   is not saved as a workout and does not appear in Fitness or Activity. Write
>   access is requested only when that setting is enabled.
> - The app is on‑device only: no network, no account, no analytics. The optional
>   "Stimulant offset" in Settings simply subtracts a user‑chosen bpm value before
>   computing the zone; it is a display adjustment, not medical functionality.
>   All figures are labeled estimates and are not medical advice.

## Privacy details ("nutrition label") — suggested answers

Data collection: **No, we do not collect data from this app.** Health data is
read on‑device only, never leaves the device, and is not linked to the user or
used for tracking. (If App Store Connect asks you to list Health & Fitness even
so, mark it Not Linked to the user and Not Used for Tracking.)

- Tracking: **No.**
- Third‑party SDKs: **None.**

## HealthKit specifics

- Read types: `heartRate`, `restingHeartRate`, `dateOfBirth`.
- Share types: `workoutType`, `heartRate` — requested lazily, only if the user
  enables "Live HR when open", to run the discarded session. No workout is saved.
- Usage strings (already set): `NSHealthShareUsageDescription` (why data is read)
  and `NSHealthUpdateUsageDescription` (why a session is started).
- Entitlement: `com.apple.developer.healthkit` (+ background‑delivery). No
  Clinical Health Records.

## Pre‑submission checklist

- [ ] Enroll in the Apple Developer Program ($99/yr) — required to submit.
- [ ] Host `PrivacyPolicy.md` at a public URL; add it to the App Store listing
      **and** the app's metadata (HealthKit apps require a privacy policy URL).
- [ ] Confirm the app name "Bread & Butter" is available in App Store Connect.
- [ ] Category: Health & Fitness. Set age rating.
- [ ] Add watch screenshots (live view + settings). The App Store requires
      Apple Watch screenshots for a watch‑only app.
- [ ] Archive in Xcode against a real device / Generic watchOS Device, then
      distribute to App Store Connect. Consider a TestFlight pass first.
- [ ] Fill in the review notes above so the reviewer starts a workout.

## v2 ideas (not blockers)

- Style: dripping‑butter effect at high fat, animated steam on the bread at
  high carbs.
- Direct Bluetooth (BLE) heart-rate straps: connect to a Polar H10 (or any
  standard BLE HR strap) directly via CoreBluetooth, reading the Heart Rate
  Measurement characteristic. Shows the strap's HR instantly on open — no
  session, no wrist-sensor fallback, less battery — even if the strap isn't
  paired to the watch.
