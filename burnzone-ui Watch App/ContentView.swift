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
    @AppStorage(SettingsKey.adderallEnabled) private var adderallEnabled = false
    @AppStorage(SettingsKey.adderallOffset) private var adderallOffset = SettingsDefault.adderallOffset

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
        guard adderallEnabled else { return raw }
        return max(physiology.restingHR, raw - adderallOffset)
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
                    if adderallEnabled {
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

        return VStack(spacing: 10) {
            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 14) {
                emoji("🧈", label: "\(fatPct)%", fraction: fuel.fatFraction)
                emoji("🍞", label: "\(carbPct)%", fraction: fuel.carbFraction)
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.8), value: fuel.fatFraction)

            VStack(spacing: 2) {
                if let bpm = health.heartRate {
                    Text("\(Int(bpm.rounded())) BPM · Zone \(zone ?? 1)")
                        .font(.footnote.weight(.medium))
                }
                Text("estimate, not medical")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
    }

    private func emoji(_ symbol: String, label: String, fraction: Double) -> some View {
        VStack(spacing: 4) {
            Text(symbol)
                .font(.system(size: 24 + fraction * 44))
            Text(label)
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var hintView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Text("🧈").font(.system(size: 34)).opacity(0.35)
                Text("🍞").font(.system(size: 34)).opacity(0.35)
            }
            Text("Start a workout for live HR")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Open Apple's Workout app so heart rate keeps flowing.")
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
