//
//  HealthKitManager.swift
//  burnzone-ui Watch App
//
//  Observes live heart rate from HealthKit WITHOUT starting a workout session.
//  The user runs a workout (Apple's Workout app, or any app that records HR),
//  which writes frequent HR samples; we watch those with a long-lived
//  HKAnchoredObjectQuery and always surface the most recent sample.
//
//  (A session-free standalone mode — reading a Bluetooth strap directly over
//  CoreBluetooth — is planned for a future version. Running our own workout
//  session was intentionally dropped because it inflates Activity rings.)
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitManager: ObservableObject {

    /// Most recent heart-rate reading (bpm) and when it was taken.
    @Published private(set) var heartRate: Double?
    @Published private(set) var sampleDate: Date?

    /// Auto-estimation inputs read from HealthKit.
    @Published private(set) var restingHeartRate: Double?
    @Published private(set) var age: Int?

    @Published private(set) var authorizationRequested = false
    let healthDataAvailable = HKHealthStore.isHealthDataAvailable()

    private let healthStore = HKHealthStore()
    private let heartRateType = HKQuantityType(.heartRate)
    private let restingType = HKQuantityType(.restingHeartRate)
    private var runningQuery: HKAnchoredObjectQuery?

    private var bpmUnit: HKUnit { HKUnit.count().unitDivided(by: .minute()) }

    /// A reading is considered stale (and hidden) if older than 60 seconds.
    func isStale(asOf now: Date) -> Bool {
        guard let sampleDate else { return true }
        return now.timeIntervalSince(sampleDate) > 60
    }

    func requestAuthorization() {
        guard healthDataAvailable else {
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
                self.loadRestingHeartRate()
                self.startHeartRateQuery()
            }
        }
    }

    // MARK: - Characteristics & resting HR

    private func loadAge() {
        guard let components = try? healthStore.dateOfBirthComponents(),
              let birthDate = Calendar.current.date(from: components),
              let years = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
        else { return }
        age = years
    }

    private func loadRestingHeartRate() {
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let unit = bpmUnit
        let query = HKSampleQuery(
            sampleType: restingType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sort]
        ) { [weak self] _, samples, _ in
            guard let self, let sample = samples?.first as? HKQuantitySample else { return }
            let bpm = sample.quantity.doubleValue(for: unit)
            Task { @MainActor in self.restingHeartRate = bpm }
        }
        healthStore.execute(query)
    }

    // MARK: - Live heart rate

    private func startHeartRateQuery() {
        guard runningQuery == nil else { return }

        // Only look at recent samples so a workout already in progress shows up
        // immediately, without loading the entire history.
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-5 * 60),
            end: nil,
            options: .strictEndDate
        )
        let unit = bpmUnit

        // Extract only Sendable values (Double/Date) before hopping to the main
        // actor — HKSample/HKQueryAnchor are not Sendable.
        let handler: @Sendable (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { [weak self] _, samples, _, _, _ in
            guard let self else { return }
            let latest = samples?
                .compactMap { $0 as? HKQuantitySample }
                .max(by: { $0.endDate < $1.endDate })
            guard let latest else { return }
            let bpm = latest.quantity.doubleValue(for: unit)
            let date = latest.endDate
            Task { @MainActor in self.ingest(bpm: bpm, date: date) }
        }

        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: handler
        )
        query.updateHandler = handler
        runningQuery = query
        healthStore.execute(query)
    }

    private func ingest(bpm: Double, date: Date) {
        // Keep only the newest reading.
        if let current = sampleDate, current > date { return }
        heartRate = bpm
        sampleDate = date
    }
}
