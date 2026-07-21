//
//  BreadOrButterApp.swift
//  Bread or Butter (iOS companion)
//
//  iPhone companion to the watch app. Shows your heart-rate zones and estimated
//  fat/carb fuel mix from Health. The live gauge (during a workout) is on the
//  Apple Watch — the phone has no heart-rate sensor.
//

import SwiftUI

@main
struct BreadOrButterApp: App {
    var body: some Scene {
        WindowGroup {
            PhoneView()
        }
    }
}

struct PhoneView: View {
    @StateObject private var health = HealthKitManager()

    private let butter = Color(red: 0.953, green: 0.792, blue: 0.376)
    private let bread = Color(red: 0.910, green: 0.604, blue: 0.235)
    private let fatColor = Color(red: 0.85, green: 0.62, blue: 0.12)

    /// The most recent reading, if it's fresh enough to be meaningful (< 2h old).
    private var recent: (bpm: Int, zone: Int, fat: Double)? {
        guard let hr = health.latestHeartRate, let date = health.latestSampleDate,
              Date().timeIntervalSince(date) < 2 * 3600 else { return nil }
        let fat = FuelSplit.from(intensityFractionOfMax: hr / health.maxHR).fatFraction
        return (Int(hr.rounded()), health.zones.zone(for: hr), fat)
    }

    private var displayFat: Double { recent?.fat ?? 0.62 }

    var body: some View {
        ZStack {
            LinearGradient(colors: [butter.opacity(0.25), bread.opacity(0.25)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    Text("Bread or Butter")
                        .font(.largeTitle.bold())
                        .padding(.top, 20)

                    VStack(spacing: 10) {
                        FuelRatioBar(fatFraction: displayFat)
                            .frame(height: 116)
                        HStack {
                            Text("fat").foregroundStyle(fatColor)
                            Spacer()
                            Text("carbs").foregroundStyle(bread)
                        }
                        .font(.headline)
                        .padding(.horizontal, 6)

                        if let r = recent {
                            Text("Last reading  \(r.bpm) BPM · Zone \(r.zone)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Open on your Apple Watch during a workout for a live reading.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 24)

                    zonesCard
                        .padding(.horizontal, 20)

                    Text("Estimate, not medical advice.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear { health.requestAuthorization() }
    }

    private var zonesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your zones")
                    .font(.headline)
                Spacer()
                Text("resting \(Int(health.effectiveRestingHR)) · max ~\(Int(health.maxHR))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(zoneRows, id: \.zone) { row in
                HStack {
                    Text("Z\(row.zone)")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 30, alignment: .leading)
                    Text("\(row.lo)–\(row.hi) bpm")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(row.fatPct)% 🧈  \(100 - row.fatPct)% 🍞")
                        .font(.subheadline)
                        .monospacedDigit()
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.5)))
    }

    /// Zone 1–5 rows: bpm range (from %HRR boundaries) and the fat share at the
    /// zone's midpoint intensity.
    private var zoneRows: [(zone: Int, lo: Int, hi: Int, fatPct: Int)] {
        let z = health.zones
        let bounds = [0.0, 0.60, 0.70, 0.80, 0.90, 1.0]
        return (0..<5).map { i in
            let loHR = z.heartRate(atReserveFraction: bounds[i])
            let hiHR = z.heartRate(atReserveFraction: bounds[i + 1])
            let mid = (loHR + hiHR) / 2
            let fat = FuelSplit.from(intensityFractionOfMax: mid / z.maxHR).fatFraction
            return (i + 1, Int(loHR.rounded()), Int(hiHR.rounded()), Int((fat * 100).rounded()))
        }
    }
}

#Preview {
    PhoneView()
}
