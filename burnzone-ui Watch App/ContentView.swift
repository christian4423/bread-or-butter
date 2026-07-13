//
//  ContentView.swift
//  burnzone-ui Watch App
//
//  Butter 🧈 (fat) vs. Bread 🍞 (carbs): each emoji scales with its share of
//  the current fuel mix, driven by live heart rate.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var health = HealthKitManager()

    @AppStorage(SettingsKey.maxHROverrideEnabled) private var maxHROverrideEnabled = false
    @AppStorage(SettingsKey.maxHROverride) private var maxHROverride = SettingsDefault.maxHROverride
    @AppStorage(SettingsKey.restingHROverrideEnabled) private var restingHROverrideEnabled = false
    @AppStorage(SettingsKey.restingHROverride) private var restingHROverride = SettingsDefault.restingHROverride
    @AppStorage(SettingsKey.ageOverrideEnabled) private var ageOverrideEnabled = false
    @AppStorage(SettingsKey.ageOverride) private var ageOverride = SettingsDefault.ageOverride
    @AppStorage(SettingsKey.medOffsetEnabled) private var medOffsetEnabled = false
    @AppStorage(SettingsKey.medOffset) private var medOffset = SettingsDefault.medOffset

    @State private var now = Date()
    private let ticker = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    // MARK: - Derived values

    private var overrides: PhysiologyOverrides {
        PhysiologyOverrides(
            maxHREnabled: maxHROverrideEnabled, maxHR: maxHROverride,
            restingHREnabled: restingHROverrideEnabled, restingHR: restingHROverride,
            ageEnabled: ageOverrideEnabled, age: ageOverride
        )
    }

    private var physiology: Physiology {
        resolvePhysiology(
            healthAge: health.age,
            healthRestingHR: health.restingHeartRate,
            overrides: overrides
        )
    }

    /// True effort HR: subtract the med offset so the intensity reflects real work.
    private var effortHR: Double? {
        guard let raw = health.heartRate else { return nil }
        guard medOffsetEnabled else { return raw }
        return max(physiology.restingHR, raw - medOffset)
    }

    private var fuel: FuelSplit? {
        guard let effortHR else { return nil }
        return FuelSplit.from(intensityFractionOfMax: effortHR / physiology.maxHR)
    }

    private var zone: Int? {
        guard let effortHR else { return nil }
        return HeartRateZones(maxHR: physiology.maxHR, restingHR: physiology.restingHR)
            .zone(for: effortHR)
    }

    private var showLiveData: Bool {
        health.heartRate != nil && !health.isStale(asOf: now)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if showLiveData, let fuel {
                    liveView(fuel: fuel)
                } else {
                    hintView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if medOffsetEnabled {
                        Text("💊").font(.footnote)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView().environmentObject(health)
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .onAppear { health.requestAuthorization() }
        .onReceive(ticker) { now = $0 }
    }

    // MARK: - Subviews

    private func liveView(fuel: FuelSplit) -> some View {
        let fatPct = Int((fuel.fatFraction * 100).rounded())
        let carbPct = 100 - fatPct

        return VStack(spacing: 8) {
            Spacer(minLength: 0)

            FuelRatioBar(fatFraction: fuel.fatFraction)
                .frame(height: 58)
                .animation(.spring(response: 0.55, dampingFraction: 0.8), value: fuel.fatFraction)

            HStack(alignment: .firstTextBaseline) {
                percentLabel(pct: fatPct, name: "fat", tint: .yellow)
                Spacer(minLength: 0)
                percentLabel(pct: carbPct, name: "carbs", tint: .orange)
            }
            .padding(.horizontal, 6)

            VStack(spacing: 1) {
                if let effort = effortHR {
                    Text("\(Int(effort.rounded())) BPM · Zone \(zone ?? 1)")
                        .font(.footnote.weight(.medium))
                }
                if medOffsetEnabled, let measured = health.heartRate {
                    Text("measured \(Int(measured.rounded())) · −\(Int(medOffset)) 💊")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Text("estimate, not medical")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private func percentLabel(pct: Int, name: String, tint: Color) -> some View {
        VStack(spacing: 0) {
            Text("\(pct)%")
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(tint)
            Text(name)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var hintView: some View {
        VStack(spacing: 8) {
            FuelRatioBar(fatFraction: 0.5)
                .frame(height: 40)
                .opacity(0.3)
                .padding(.horizontal, 10)
            Text("Live fat vs. carb burn, read from your heart rate.")
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Start a workout in Apple's Workout app to see it.")
                .font(.system(size: 10))
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    ContentView()
}
