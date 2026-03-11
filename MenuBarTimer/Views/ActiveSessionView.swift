import SwiftUI

struct ActiveSessionView: View {
    @EnvironmentObject var timerManager: TimerManager

    private var elapsedString: String {
        let elapsed = timerManager.currentEntry?.actualDuration ?? 0
        let mins = Int(elapsed) / 60
        let secs = Int(elapsed) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var plannedString: String {
        let planned = timerManager.currentEntry?.plannedDuration ?? 0
        let mins = Int(planned) / 60
        return "\(mins)m"
    }

    var body: some View {
        VStack(spacing: 14) {
            // Client & task header
            VStack(spacing: 3) {
                Text(timerManager.currentEntry?.client ?? "")
                    .font(.system(.headline, design: .rounded))
                if let task = timerManager.currentEntry?.task, !task.isEmpty {
                    Text(task)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 18)

            if timerManager.isOpenEnded {
                // Open-ended: count up with pulsing ring
                openEndedTimer
            } else {
                // Countdown with progress ring
                countdownTimer
            }

            if timerManager.isPaused {
                Text("Paused")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
            }

            if timerManager.isOffFocus && !timerManager.focusApp.isEmpty {
                Text("Get back to \(timerManager.focusApp)!")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.red.opacity(0.12)))
            }

            Spacer()

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    if timerManager.isPaused {
                        timerManager.resume()
                    } else {
                        timerManager.pause()
                    }
                } label: {
                    Label(
                        timerManager.isPaused ? "Resume" : "Pause",
                        systemImage: timerManager.isPaused ? "play.fill" : "pause.fill"
                    )
                    .font(.system(.callout, design: .rounded).weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.orange.opacity(0.12))
                    )
                    .foregroundColor(.orange)
                }
                .buttonStyle(.plain)

                Button {
                    timerManager.stop()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.system(.callout, design: .rounded).weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.12))
                        )
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Countdown mode

    private var countdownTimer: some View {
        ZStack {
            CircularProgressView(
                progress: timerManager.progress,
                lineWidth: 10,
                size: 160
            )

            VStack(spacing: 4) {
                Text(timerManager.remainingTimeString)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Text("\(elapsedString) of \(plannedString)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Open-ended (count up) mode

    private var openEndedTimer: some View {
        ZStack {
            PulsingRingView(size: 160, lineWidth: 10)

            VStack(spacing: 4) {
                Text(elapsedString)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Text("open session")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Pulsing ring for open-ended sessions

struct PulsingRingView: View {
    var size: CGFloat
    var lineWidth: CGFloat

    @State private var rotation: Double = 0

    private var gradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color(red: 0.2, green: 0.8, blue: 0.75).opacity(0.6),
                Color(red: 0.35, green: 0.5, blue: 0.95).opacity(0.1),
                Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.6),
                Color(red: 0.2, green: 0.8, blue: 0.75).opacity(0.1),
                Color(red: 0.2, green: 0.8, blue: 0.75).opacity(0.6)
            ]),
            center: .center
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.07), lineWidth: lineWidth)

            Circle()
                .stroke(gradient, lineWidth: lineWidth)
                .rotationEffect(.degrees(rotation))
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
