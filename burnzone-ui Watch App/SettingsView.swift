//
//  SettingsView.swift
//  burnzone-ui Watch App
//
//  Override max HR, resting HR, and age when HealthKit data is missing or
//  wrong, and configure the stimulant-medication HR offset.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var health: HealthKitManager

    @AppStorage(SettingsKey.maxHROverrideEnabled) private var maxHROverrideEnabled = false
    @AppStorage(SettingsKey.maxHROverride) private var maxHROverride = SettingsDefault.maxHROverride
    @AppStorage(SettingsKey.restingHROverrideEnabled) private var restingHROverrideEnabled = false
    @AppStorage(SettingsKey.restingHROverride) private var restingHROverride = SettingsDefault.restingHROverride
    @AppStorage(SettingsKey.ageOverrideEnabled) private var ageOverrideEnabled = false
    @AppStorage(SettingsKey.ageOverride) private var ageOverride = SettingsDefault.ageOverride
    @AppStorage(SettingsKey.adderallEnabled) private var adderallEnabled = false
    @AppStorage(SettingsKey.adderallOffset) private var adderallOffset = SettingsDefault.adderallOffset

    var body: some View {
        Form {
            Section {
                Toggle("Adderall mode", isOn: $adderallEnabled)
                if adderallEnabled {
                    Stepper(value: $adderallOffset, in: 0...25, step: 1) {
                        stepperLabel("Offset", value: "\(Int(adderallOffset)) bpm")
                    }
                }
            } header: {
                Text("💊 Medication")
            } footer: {
                Text("Subtracts the offset from measured HR so zones reflect true effort, not med-elevated heart rate.")
            }

            Section {
                Toggle("Override", isOn: $ageOverrideEnabled)
                if ageOverrideEnabled {
                    Stepper(value: $ageOverride, in: 10...100, step: 1) {
                        stepperLabel("Age", value: "\(Int(ageOverride)) yrs")
                    }
                } else {
                    autoLabel(health.age.map { "HealthKit: \($0) yrs" } ?? "HealthKit: unavailable")
                }
            } header: {
                Text("Age")
            } footer: {
                Text("Used to estimate max HR as 220 − age.")
            }

            Section("Max heart rate") {
                Toggle("Override", isOn: $maxHROverrideEnabled)
                if maxHROverrideEnabled {
                    Stepper(value: $maxHROverride, in: 120...220, step: 1) {
                        stepperLabel("Max HR", value: "\(Int(maxHROverride)) bpm")
                    }
                } else {
                    autoLabel("Auto: \(autoMaxHR) bpm")
                }
            }

            Section("Resting heart rate") {
                Toggle("Override", isOn: $restingHROverrideEnabled)
                if restingHROverrideEnabled {
                    Stepper(value: $restingHROverride, in: 30...120, step: 1) {
                        stepperLabel("Resting", value: "\(Int(restingHROverride)) bpm")
                    }
                } else {
                    autoLabel(health.restingHeartRate.map { "HealthKit: \(Int($0)) bpm" } ?? "Default: \(Int(SettingsDefault.fallbackRestingHR)) bpm")
                }
            }
        }
        .navigationTitle("Settings")
    }

    /// Compact two-part label for a Stepper: name on the left, value on the
    /// right, both kept to a single line so they never wrap beside the −/+ keys.
    private func stepperLabel(_ name: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(name)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private func autoLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private var autoMaxHR: Int {
        let age = ageOverrideEnabled ? Int(ageOverride) : (health.age ?? SettingsDefault.fallbackAge)
        return 220 - age
    }
}

#Preview {
    NavigationStack {
        SettingsView().environmentObject(HealthKitManager())
    }
}
