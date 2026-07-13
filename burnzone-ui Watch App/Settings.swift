//
//  Settings.swift
//  burnzone-ui Watch App
//
//  UserDefaults keys + defaults shared between the main screen and the
//  settings page, plus the logic that resolves the effective physiology from
//  HealthKit data and any user overrides.
//

import Foundation

enum SettingsKey {
    static let maxHROverrideEnabled = "maxHROverrideEnabled"
    static let maxHROverride = "maxHROverride"
    static let restingHROverrideEnabled = "restingHROverrideEnabled"
    static let restingHROverride = "restingHROverride"
    static let ageOverrideEnabled = "ageOverrideEnabled"
    static let ageOverride = "ageOverride"
    // Key strings are kept as-is so an existing setting on the watch isn't reset.
    static let medOffsetEnabled = "adderallEnabled"
    static let medOffset = "adderallOffset"
}

enum SettingsDefault {
    static let maxHROverride: Double = 190
    static let restingHROverride: Double = 60
    static let ageOverride: Double = 30
    static let medOffset: Double = 10

    /// Fallbacks when neither an override nor HealthKit data is available.
    static let fallbackAge = 30
    static let fallbackRestingHR: Double = 60
}

/// Overrides captured from the settings screen.
struct PhysiologyOverrides {
    var maxHREnabled: Bool
    var maxHR: Double
    var restingHREnabled: Bool
    var restingHR: Double
    var ageEnabled: Bool
    var age: Double
}

/// Resolve the physiology to use, preferring user overrides, then HealthKit,
/// then sensible fallbacks. Max HR is estimated as 220 − age when not overridden.
func resolvePhysiology(
    healthAge: Int?,
    healthRestingHR: Double?,
    overrides: PhysiologyOverrides
) -> Physiology {
    let age: Int
    if overrides.ageEnabled {
        age = Int(overrides.age)
    } else {
        age = healthAge ?? SettingsDefault.fallbackAge
    }

    let maxHR: Double
    let maxHRIsEstimated: Bool
    if overrides.maxHREnabled {
        maxHR = overrides.maxHR
        maxHRIsEstimated = false
    } else {
        maxHR = 220 - Double(age)
        maxHRIsEstimated = true
    }

    let restingHR: Double
    let restingHRIsEstimated: Bool
    if overrides.restingHREnabled {
        restingHR = overrides.restingHR
        restingHRIsEstimated = false
    } else if let hr = healthRestingHR {
        restingHR = hr
        restingHRIsEstimated = false
    } else {
        restingHR = SettingsDefault.fallbackRestingHR
        restingHRIsEstimated = true
    }

    return Physiology(
        maxHR: maxHR,
        restingHR: restingHR,
        age: age,
        maxHRIsEstimated: maxHRIsEstimated,
        restingHRIsEstimated: restingHRIsEstimated
    )
}
