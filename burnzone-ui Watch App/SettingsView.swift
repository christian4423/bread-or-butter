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
                Toggle("Enabled", isOn: $adderallEnabled)
                if adderallEnabled {
                    Stepper(value: $adderallOffset, in: 0...25, step: 1) {
                        Text("Offset −\(Int(adderallOffset)) bpm")
                    }
                }
            } header: {
                Text("💊 Adderall Mode")
            } footer: {
                Text("Subtracts the offset from measured HR so zones reflect true effort, not med-elevated heart rate.")
            }

            Section {
                Toggle("Override", isOn: $ageOverrideEnabled)
                if ageOverrideEnabled {
                    Stepper(value: $ageOverride, in: 10...100, step: 1) {
                        Text("\(Int(ageOverride)) yrs")
                    }
                } else {
                    Text(health.age.map { "HealthKit: \($0) yrs" } ?? "HealthKit: unavailable")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Age")
            } footer: {
                Text("Used to estimate max HR as 220 − age.")
            }

            Section("Max Heart Rate") {
                Toggle("Override", isOn: $maxHROverrideEnabled)
                if maxHROverrideEnabled {
                    Stepper(value: $maxHROverride, in: 120...220, step: 1) {
                        Text("\(Int(maxHROverride)) bpm")
                    }
                } else {
                    Text("Auto: \(autoMaxHR) bpm")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Resting Heart Rate") {
                Toggle("Override", isOn: $restingHROverrideEnabled)
                if restingHROverrideEnabled {
                    Stepper(value: $restingHROverride, in: 30...120, step: 1) {
                        Text("\(Int(restingHROverride)) bpm")
                    }
                } else {
                    Text(health.restingHeartRate.map { "HealthKit: \(Int($0)) bpm" } ?? "Default: \(Int(SettingsDefault.fallbackRestingHR)) bpm")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
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
