//
//  FuelModel.swift
//  Bread or Butter (iOS companion)
//
//  Same fat/carb crossover + Karvonen zone math as the watch app (copied because
//  the iOS app is a separate module). Ballpark textbook values, not medical data.
//

import Foundation

/// Smoothstep interpolation: 0 below `edge0`, 1 above `edge1`, an S-curve between.
func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
    guard edge1 > edge0 else { return x < edge0 ? 0 : 1 }
    let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
    return t * t * (3 - 2 * t)
}

/// Heart-rate zones 1–5 derived from heart-rate reserve (Karvonen).
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

    /// Heart rate (bpm) at a given fraction of heart-rate reserve.
    func heartRate(atReserveFraction f: Double) -> Double {
        restingHR + f * (maxHR - restingHR)
    }
}

/// Fat vs. carbohydrate energy split based on the crossover concept.
struct FuelSplit {
    let fatFraction: Double
    var carbFraction: Double { 1 - fatFraction }

    /// ~85% fat at easy effort tapering smoothly to ~10% fat at 90%+ of max.
    static func from(intensityFractionOfMax x: Double) -> FuelSplit {
        let fatAtLowIntensity = 0.85
        let fatAtHighIntensity = 0.10
        let t = smoothstep(0.5, 0.9, x)
        let fat = fatAtLowIntensity + (fatAtHighIntensity - fatAtLowIntensity) * t
        return FuelSplit(fatFraction: fat)
    }
}
