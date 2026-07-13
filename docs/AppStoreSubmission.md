# App Store submission notes — Bread & Butter

Reference for submitting the watchOS app. Copy the review notes verbatim; use
the rest as a checklist.

## App Review notes (paste into App Store Connect → App Review Information → Notes)

> Bread & Butter is a watchOS‑only app. It reads heart rate from Apple Health
> and shows an estimated fat‑vs‑carbohydrate fuel split and heart‑rate zone.
>
> To test on a real Apple Watch:
>
> 1. Launch Bread & Butter and allow the Health permission prompt.
> 2. Wear the watch. Within a few seconds the app starts a heart‑rate session,
>    and the butter/baguette bar, percentages, BPM, and zone appear and update
>    live. (If Apple's Workout app is already running a workout, the app uses
>    those readings instead of starting its own session.)
>
> Notes for review:
> - Live heart rate requires the watch's sensor, which only streams during a
>   session, so the app starts a lightweight HealthKit workout session while it
>   is open. That session is DISCARDED when the app is backgrounded — it is not
>   saved as a workout and does not appear in Fitness or Activity.
> - This cannot be exercised in the Simulator (no live heart rate); please test
>   on a physical Apple Watch.
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
- Share types: `workoutType`, `heartRate` — needed to run the live heart‑rate
  session. The session is discarded, so no workout is saved.
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

## Nice-to-have before 1.0 (not blockers)

- v2 style: dripping‑butter effect at high fat, animated steam on the bread at
  high carbs.
