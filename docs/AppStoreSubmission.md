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
> 2. On the watch, start any workout in Apple's Workout app (e.g. Outdoor Walk)
>    so the watch records heart rate.
> 3. Return to Bread & Butter. Within a few seconds the butter/baguette bar,
>    percentages, BPM, and zone appear and update live.
>
> Without an active workout the app shows an explainer telling the user to start
> one — this is expected, not a bug. (Live heart rate requires the watch's
> sensor, which only streams during a workout, so the app reads an existing
> workout's HR rather than starting its own session.)
>
> The app is on‑device only: read‑only HealthKit access, no network, no account,
> no analytics. The optional "Stimulant offset" in Settings simply subtracts a
> user‑chosen bpm value before computing the zone; it is a display adjustment,
> not medical functionality. All figures are labeled estimates and are not
> medical advice.

## Privacy details ("nutrition label") — suggested answers

Data collection: **No, we do not collect data from this app.** Health data is
read on‑device only, never leaves the device, and is not linked to the user or
used for tracking. (If App Store Connect asks you to list Health & Fitness even
so, mark it Not Linked to the user and Not Used for Tracking.)

- Tracking: **No.**
- Third‑party SDKs: **None.**

## HealthKit specifics

- Read‑only types: `heartRate`, `restingHeartRate`, `dateOfBirth`. No write access.
- Usage string (already set): `NSHealthShareUsageDescription` explains why each
  is read.
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
