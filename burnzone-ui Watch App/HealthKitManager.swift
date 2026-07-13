//
//  HealthKitManager.swift
//  burnzone-ui Watch App
//
//  Sources live heart rate two ways, preferring whichever is already available:
//
//  1. If Apple's Workout app (or anything else) is already recording, we simply
//     read its fresh HR samples with a long-lived HKAnchoredObjectQuery.
//  2. Otherwise, so the app works whenever it is open, we start our OWN
//     lightweight HKWorkoutSession to turn on the sensor. That session is never
//     saved as a workout — it is discarded when the app is backgrounded.
//
//  This "hybrid" keeps the companion-to-Workout behavior while adding standalone
//  use, and avoids running two sessions at once (we defer to a live external
//  source when its samples are fresh).
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitManager: NSObject, ObservableObject {

    /// Most recent heart-rate reading (bpm) and when it was taken.
    @Published private(set) var heartRate: Double?
    @Published private(set) var sampleDate: Date?

    /// Auto-estimation inputs read from HealthKit.
    @Published private(set) var restingHeartRate: Double?
    @Published private(set) var age: Int?

    /// True while we are driving our own session (vs. reading an external one).
    @Published private(set) var runningOwnSession = false

    @Published private(set) var authorizationRequested = false
    let healthDataAvailable = HKHealthStore.isHealthDataAvailable()

    private let healthStore = HKHealthStore()
    private let heartRateType = HKQuantityType(.heartRate)
    private let restingType = HKQuantityType(.restingHeartRate)
    private var runningQuery: HKAnchoredObjectQuery?

    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var hybridTask: Task<Void, Never>?
    private var isReady = false

    /// If a sample newer than this arrives, we assume an external workout is live
    /// and do not start our own session.
    private let externalFreshWindow: TimeInterval = 15

    private var bpmUnit: HKUnit { HKUnit.count().unitDivided(by: .minute()) }

    /// A reading is considered stale (and hidden) if older than 60 seconds.
    func isStale(asOf now: Date) -> Bool {
        guard let sampleDate else { return true }
        return now.timeIntervalSince(sampleDate) > 60
    }

    // MARK: - Authorization

    func requestAuthorization() {
        guard healthDataAvailable else {
            authorizationRequested = true
            return
        }
        // Read-only by default; workout-share is requested lazily, only if the
        // user turns on the standalone "Live HR when open" setting.
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
                self.isReady = true
                self.loadAge()
                self.loadRestingHeartRate()
                self.startHeartRateQuery()
            }
        }
    }

    // MARK: - App lifecycle (called from the view's scenePhase)

    /// `standalone` mirrors the user's "Live HR when open" setting.
    func onBecameActive(standalone: Bool) {
        guard isReady else { return }
        startHeartRateQuery()
        if standalone {
            scheduleHybridCheck()
        } else {
            hybridTask?.cancel()
            stopOwnSession()
        }
    }

    func onResignedActive() {
        hybridTask?.cancel()
        stopOwnSession()
    }

    /// React to the setting being toggled while the app is open.
    func setStandalone(_ enabled: Bool) {
        guard isReady else { return }
        if enabled {
            scheduleHybridCheck()
        } else {
            hybridTask?.cancel()
            stopOwnSession()
        }
    }

    /// After a short grace period, start our own session unless fresh external
    /// samples are already arriving.
    private func scheduleHybridCheck() {
        hybridTask?.cancel()
        hybridTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled, !runningOwnSession else { return }
            if let sampleDate, Date().timeIntervalSince(sampleDate) < externalFreshWindow {
                return // an external source is live — defer to it
            }
            startOwnSession()
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

    // MARK: - Reading live samples (external or our own)

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

    // MARK: - Our own session (standalone use)

    private func startOwnSession() {
        guard !runningOwnSession, session == nil, healthDataAvailable else { return }
        // Ask for workout-share only now — users who never enable standalone
        // mode are never prompted for write access.
        let share: Set<HKSampleType> = [HKQuantityType.workoutType(), heartRateType]
        healthStore.requestAuthorization(toShare: share, read: []) { [weak self] success, _ in
            guard let self, success else { return }
            Task { @MainActor in self.beginOwnSession() }
        }
    }

    private func beginOwnSession() {
        guard !runningOwnSession, session == nil, healthDataAvailable else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown

        do {
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self

            let start = Date()
            session.startActivity(with: start)
            builder.beginCollection(withStart: start) { _, _ in }

            self.session = session
            self.builder = builder
            self.runningOwnSession = true
        } catch {
            runningOwnSession = false
        }
    }

    private func stopOwnSession() {
        guard let session else { return }
        session.end() // delegate fires .ended, where we discard + clean up
    }

    private func finalizeOwnSession() {
        builder?.discardWorkout()
        builder = nil
        session = nil
        runningOwnSession = false
    }
}

// MARK: - Session & live-builder delegates

extension HealthKitManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        guard toState == .ended else { return }
        Task { @MainActor in self.finalizeOwnSession() }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor in self.finalizeOwnSession() }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        let hrType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(hrType),
              let stats = workoutBuilder.statistics(for: hrType),
              let quantity = stats.mostRecentQuantity()
        else { return }
        let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let date = stats.mostRecentQuantityDateInterval()?.end ?? Date()
        Task { @MainActor in self.ingest(bpm: bpm, date: date) }
    }
}
