//
//  HealthKitManager.swift
//  Bread or Butter (iOS companion)
//
//  Read-only HealthKit access on the phone: resting heart rate, age (from date
//  of birth), and the most recent heart-rate sample (written by the watch). The
//  phone has no HR sensor, so there is no live reading here — the live gauge is
//  on the Apple Watch. We use this to show your resting/max HR and zones.
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitManager: ObservableObject {

    @Published private(set) var restingHeartRate: Double?
    @Published private(set) var age: Int?
    @Published private(set) var latestHeartRate: Double?
    @Published private(set) var latestSampleDate: Date?
    @Published private(set) var authorizationRequested = false

    private let healthStore = HKHealthStore()
    private let heartRateType = HKQuantityType(.heartRate)
    private let restingType = HKQuantityType(.restingHeartRate)
    private var bpmUnit: HKUnit { HKUnit.count().unitDivided(by: .minute()) }

    /// Effective values, falling back to sensible defaults when Health has none.
    var effectiveRestingHR: Double { restingHeartRate ?? 60 }
    var effectiveAge: Int { age ?? 30 }
    var maxHR: Double { 220 - Double(effectiveAge) }
    var zones: HeartRateZones { HeartRateZones(maxHR: maxHR, restingHR: effectiveRestingHR) }

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationRequested = true
            return
        }
        let toRead: Set<HKObjectType> = [
            heartRateType,
            restingType,
            HKCharacteristicType(.dateOfBirth),
        ]
        healthStore.requestAuthorization(toShare: [], read: toRead) { [weak self] success, _ in
            guard let self else { return }
            Task { @MainActor in
                self.authorizationRequested = true
                guard success else { return }
                self.loadAge()
                self.loadMostRecent(self.restingType) { bpm, _ in self.restingHeartRate = bpm }
                self.loadMostRecent(self.heartRateType) { bpm, date in
                    self.latestHeartRate = bpm
                    self.latestSampleDate = date
                }
            }
        }
    }

    private func loadAge() {
        guard let components = try? healthStore.dateOfBirthComponents(),
              let birthDate = Calendar.current.date(from: components),
              let years = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
        else { return }
        age = years
    }

    private func loadMostRecent(_ type: HKQuantityType, assign: @escaping (Double, Date) -> Void) {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let unit = bpmUnit
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: unit)
            let date = sample.endDate
            Task { @MainActor in assign(bpm, date) }
        }
        healthStore.execute(query)
    }
}
