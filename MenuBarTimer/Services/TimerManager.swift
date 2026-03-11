import Foundation
import Combine
import AppKit

class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var progress: Double = 0
    @Published var remainingSeconds: TimeInterval = 0
    @Published var currentEntry: TimeEntry?
    @Published var focusApp: String = ""
    @Published var isOffFocus = false

    var onTick: ((Double, String?) -> Void)?
    var onFocusNudge: (() -> Void)?

    private var timer: AnyCancellable?
    private var startTime: Date?
    private var pausedElapsed: TimeInterval = 0
    private var plannedDuration: TimeInterval = 0
    private var focusCheckTimer: AnyCancellable?
    private var offFocusSince: Date?
    private let offFocusThreshold: TimeInterval = 30 // seconds before nudge
    private var lastNudgeTime: Date?
    private let nudgeCooldown: TimeInterval = 30

    private let storage = StorageService.shared
    private let notionService = NotionService.shared

    var remainingTimeString: String {
        let remaining = max(0, remainingSeconds)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var isOpenEnded: Bool {
        plannedDuration <= 0
    }

    var elapsedTimeString: String {
        let elapsed = currentEntry?.actualDuration ?? 0
        let mins = Int(elapsed) / 60
        let secs = Int(elapsed) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    func start(client: String, task: String, duration: TimeInterval, focusAppName: String = "") {
        let entry = TimeEntry(
            id: UUID(),
            client: client,
            task: task,
            plannedDuration: duration,
            actualDuration: 0,
            startedAt: Date(),
            completedAt: nil,
            status: .running
        )

        currentEntry = entry
        plannedDuration = duration
        remainingSeconds = duration
        progress = 0
        isRunning = true
        isPaused = false
        startTime = Date()
        pausedElapsed = 0
        focusApp = focusAppName
        isOffFocus = false
        offFocusSince = nil
        lastNudgeTime = nil

        startTimer()
        startFocusMonitor()
    }

    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true

        if let start = startTime {
            pausedElapsed += Date().timeIntervalSince(start)
        }
        timer?.cancel()
        timer = nil

        currentEntry?.status = .paused
        let displayTime = isOpenEnded ? elapsedTimeString : remainingTimeString
        onTick?(progress, "⏸ " + displayTime)
    }

    func resume() {
        guard isRunning, isPaused else { return }
        isPaused = false
        startTime = Date()
        currentEntry?.status = .running
        startTimer()
    }

    func stop() {
        guard isRunning else { return }

        let elapsed = calculateElapsed()

        timer?.cancel()
        timer = nil

        var entry = currentEntry
        entry?.actualDuration = elapsed
        entry?.completedAt = Date()
        entry?.status = .stopped

        if let entry = entry {
            storage.addEntry(entry)
            notionService.logEntry(entry)
        }

        resetState()
        onTick?(0, nil)
    }

    private func complete() {
        let elapsed = calculateElapsed()

        timer?.cancel()
        timer = nil

        var entry = currentEntry
        entry?.actualDuration = elapsed
        entry?.completedAt = Date()
        entry?.status = .completed

        if let entry = entry {
            storage.addEntry(entry)
            notionService.logEntry(entry)
        }

        if storage.soundEnabled {
            NSSound(named: "Glass")?.play()
        }

        resetState()

        onTick?(1.0, "Done")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.onTick?(0, nil)
        }
    }

    private func resetState() {
        isRunning = false
        isPaused = false
        progress = 0
        remainingSeconds = 0
        currentEntry = nil
        startTime = nil
        pausedElapsed = 0
        plannedDuration = 0
        focusApp = ""
        isOffFocus = false
        offFocusSince = nil
        lastNudgeTime = nil
        stopFocusMonitor()
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        let elapsed = calculateElapsed()

        if isOpenEnded {
            remainingSeconds = 0
            progress = 0
            currentEntry?.actualDuration = elapsed
            onTick?(0, elapsedTimeString)
        } else {
            let remaining = max(0, plannedDuration - elapsed)
            remainingSeconds = remaining
            progress = min(1.0, elapsed / plannedDuration)
            currentEntry?.actualDuration = elapsed
            onTick?(progress, remainingTimeString)

            if remaining <= 0 {
                complete()
            }
        }
    }

    private func calculateElapsed() -> TimeInterval {
        guard let start = startTime else { return pausedElapsed }
        return pausedElapsed + Date().timeIntervalSince(start)
    }

    // MARK: - Focus App Monitoring

    private func startFocusMonitor() {
        stopFocusMonitor()
        let trimmed = focusApp.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        focusCheckTimer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkFocusApp()
            }
    }

    private func stopFocusMonitor() {
        focusCheckTimer?.cancel()
        focusCheckTimer = nil
    }

    private func checkFocusApp() {
        guard isRunning, !isPaused else { return }
        let targetName = focusApp.trimmingCharacters(in: .whitespaces).lowercased()
        guard !targetName.isEmpty else { return }

        let frontApp = NSWorkspace.shared.frontmostApplication
        let appName = (frontApp?.localizedName ?? "").lowercased()
        let bundleID = (frontApp?.bundleIdentifier ?? "").lowercased()

        let isOnTarget = appName.contains(targetName) || bundleID.contains(targetName)

        if isOnTarget {
            // Back on track
            if isOffFocus {
                isOffFocus = false
                offFocusSince = nil
            }
        } else {
            // Off target
            if offFocusSince == nil {
                offFocusSince = Date()
            }

            if let since = offFocusSince,
               Date().timeIntervalSince(since) >= offFocusThreshold {
                isOffFocus = true

                // Send a nudge notification (with cooldown)
                if lastNudgeTime == nil || Date().timeIntervalSince(lastNudgeTime!) >= nudgeCooldown {
                    sendFocusNudge()
                    lastNudgeTime = Date()
                }
            }
        }
    }

    private func sendFocusNudge() {
        if storage.soundEnabled {
            NSSound(named: "Tink")?.play()
        }
        onFocusNudge?()
    }
}
