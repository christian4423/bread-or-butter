# App Store submission notes — Bread & Butter

Reference for submitting the watchOS app. Copy the review notes verbatim; use
the rest as a checklist.

## App Review notes (paste into App Store Connect → App Review Information → Notes)

> Bread & Butter is a watchOS‑only app. It reads heart rate from Apple Health
> and shows an estimated fat‑vs‑carbohydrate fuel split and heart‑rate zone.
>
> IMPORTANT — how to see the main screen: the live view only appears while
> heart‑rate samples are arriving. By design the app does NOT start its own
> workout session (to avoid conflicting with Apple's Workout app). To test:
>
> 1. Launch Bread & Butter and grant the Health permission prompt (heart rate,
>    resting heart rate, date of birth — read only).
> 2. On the watch, open Apple's Workout app and start any workout (e.g. Outdoor
>    Walk). This makes the watch record heart rate.
> 3. Return to Bread & Butter. Within a few seconds the butter/baguette bar,
>    percentages, BPM, and zone appear and update live.
>
> Without an active workout the app shows an explainer telling the user to start
> one — this is expected, not a bug.
>
> The app is entirely on‑device: read‑only HealthKit access, no network, no
> account, no analytics. The optional "Stimulant offset" in Settings simply
> subtracts a user‑chosen bpm value before computing the zone; it is a display
> adjustment, not medical functionality. All figures are labeled estimates and
> are not medical advice.

## Privacy details ("nutrition label") — suggested answers

Data collection: **No, we do not collect data from this app.** Health data is
read on‑device only, never leaves the device, and is not linked to the user or
used for tracking. (If App Store Connect asks you to list Health & Fitness even
so, mark it Not Linked to the user and Not Used for Tracking.)

- Tracking: **No.**
- Third‑party SDKs: **None.**

## HealthKit specifics

- Read‑only types: `heartRate`, `restingHeartRate`, `dateOfBirth`. No write access.
- Usage string (already set): NSHealthShareUsageDescription explains why each is read.
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
