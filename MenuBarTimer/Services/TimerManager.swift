import Foundation
import Combine
import AppKit

class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var progress: Double = 0
    @Published var remainingSeconds: TimeInterval = 0
    @Published var currentEntry: TimeEntry?

    var onTick: ((Double, String?) -> Void)?

    private var timer: AnyCancellable?
    private var startTime: Date?
    private var pausedElapsed: TimeInterval = 0
    private var plannedDuration: TimeInterval = 0

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

    func start(client: String, task: String, duration: TimeInterval) {
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

        startTimer()
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
}
