# App Store submission notes — Bread or Butter

Bread or Butter ships as an **iPhone app with an Apple Watch app**. Copy the
review notes verbatim; use the rest as a checklist.

## App Review notes (paste into App Store Connect → App Review Information → Notes)

> Bread or Butter is an iPhone app with an Apple Watch app. It reads your heart
> data from Apple Health (read‑only) and shows an estimated fat‑vs‑carbohydrate
> fuel mix and heart‑rate zones.
>
> Fastest way to review — the iPhone app (no workout needed):
> 1. Launch Bread or Butter on iPhone and allow the Health permission prompt.
> 2. It shows your resting and estimated max heart rate and a "Your zones" card
>    (Zones 1–5 with the butter/bread fat‑carb split per zone). If Health has a
>    recent heart‑rate sample, the gauge reflects it.
>
> The Apple Watch app (live gauge — requires a workout, physical device only):
> 1. On the watch, start any workout in Apple's Workout app (e.g. Outdoor Walk)
>    so the watch records heart rate.
> 2. Open Bread or Butter on the watch; within a few seconds the butter/baguette
>    gauge, percentages, BPM, and zone appear and update live. Live heart rate
>    requires the watch's sensor, which only streams during a workout — it is not
>    available in the Simulator.
>
> About the iPhone app: it is a real companion (heart‑rate zones) and also serves
> as the iOS container that lets the watch app reach the App Store — Xcode 26
> cannot distribute a bare watch‑only build (a known Apple bug), so the watch app
> ships embedded in this iPhone app.
>
> The app is on‑device only: read‑only HealthKit access, no network, no account,
> no analytics, no data collection. The optional "Stimulant offset" on the watch
> simply subtracts a user‑chosen bpm value before computing the zone — a display
> adjustment, not medical functionality. All figures are labeled estimates and
> are not medical advice.

## Privacy details ("nutrition label") — suggested answers

Data collection: **No, we do not collect data from this app.** Health data is
read on‑device only, never leaves the device, and is not linked to the user or
used for tracking. (If App Store Connect makes you list Health & Fitness anyway,
mark it Not Linked to the user and Not Used for Tracking.)

- Tracking: **No.**
- Third‑party SDKs: **None.**

## HealthKit specifics

- Read‑only types (iPhone and Apple Watch): `heartRate`, `restingHeartRate`,
  `dateOfBirth`. No write access.
- Usage strings (set): `NSHealthShareUsageDescription` (why data is read) and
  `NSHealthUpdateUsageDescription`. The update string is required by App Store
  validation whenever the HealthKit entitlement is present, even though the app
  never writes — its text says so plainly.
- Entitlement: `com.apple.developer.healthkit` on both targets. No Clinical
  Health Records.
- `ITSAppUsesNonExemptEncryption = NO` is set, so no export‑compliance question.

## Pre‑submission checklist

- [x] Apple Developer Program enrollment.
- [x] Privacy policy hosted; put the URL in the listing **and** app metadata.
- [x] App Store Connect record created (iOS, bundle id `com.matsoukis.bread-and-butter`).
- [x] Build uploaded and processing in TestFlight.
- [ ] Screenshots: iPhone → `docs/screenshots/ios-1-companion-6.7.png` (1284×2778);
      Apple Watch → `docs/screenshots/1-4`.
- [ ] Category: Health & Fitness. Set age rating.
- [ ] Complete the App Privacy nutrition label (see above).
- [ ] Attach the processed build, paste the review notes above, submit for review.

## v2 ideas (not blockers)

- Style: dripping‑butter effect at high fat, animated steam on the bread at
  high carbs.
- Direct Bluetooth (BLE) heart-rate straps: connect to a Polar H10 (or any
  standard BLE HR strap) directly via CoreBluetooth, reading the Heart Rate
  Measurement characteristic. Shows the strap's HR instantly on open — no
  session, no wrist-sensor fallback, less battery — even if the strap isn't
  paired to the watch.
- A real iPhone experience beyond the zones card (history, trends).
