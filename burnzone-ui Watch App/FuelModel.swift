//
//  FuelModel.swift
//  burnzone-ui Watch App
//
//  Pure, testable math for heart-rate zones (Karvonen / %HRR) and the
//  fat-vs-carb "crossover" fuel split. These are ballpark textbook values —
//  an estimate for fun, not medical data.
//

import Foundation

/// Smoothstep interpolation: 0 below `edge0`, 1 above `edge1`, an S-curve between.
func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
    guard edge1 > edge0 else { return x < edge0 ? 0 : 1 }
    let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
    return t * t * (3 - 2 * t)
}

/// Resolved physiology used for all downstream calculations.
struct Physiology {
    var maxHR: Double
    var restingHR: Double
    var age: Int
    var maxHRIsEstimated: Bool
    var restingHRIsEstimated: Bool
}

/// Heart-rate zones 1–5 derived from heart-rate reserve (Karvonen).
/// This mirrors Apple's approach because their user-configured zones are not
/// readable through any public API.
struct HeartRateZones {
    let maxHR: Double
    let restingHR: Double

    /// Fraction of heart-rate reserve used, clamped to 0...1.
    func reserveFraction(for hr: Double) -> Double {
        let denom = max(1, maxHR - restingHR)
        return min(max((hr - restingHR) / denom, 0), 1)
    }

    /// Zone 1...5 with %HRR boundaries at 60 / 70 / 80 / 90.
    func zone(for hr: Double) -> Int {
        let pct = reserveFraction(for: hr) * 100
        switch pct {
        case ..<60: return 1
        case ..<70: return 2
        case ..<80: return 3
        case ..<90: return 4
        default:    return 5
        }
    }
}

/// Fat vs. carbohydrate energy split based on the crossover concept.
struct FuelSplit {
    /// Fraction of energy coming from fat, 0...1.
    let fatFraction: Double
    /// Fraction of energy coming from carbohydrate, 0...1.
    var carbFraction: Double { 1 - fatFraction }

    /// Map intensity (as a fraction of max HR, 0...1) to a fat/carb split.
    /// ~85% fat at easy effort tapering smoothly to ~10% fat at 90%+ of max.
    static func from(intensityFractionOfMax x: Double) -> FuelSplit {
        let fatAtLowIntensity = 0.85
        let fatAtHighIntensity = 0.10
        let t = smoothstep(0.5, 0.9, x)
        let fat = fatAtLowIntensity + (fatAtHighIntensity - fatAtLowIntensity) * t
        return FuelSplit(fatFraction: fat)
    }
}
