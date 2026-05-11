import SwiftUI

struct NewSessionView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Binding var client: String
    @Binding var task: String
    @Binding var focusApp: String
    @Binding var selectedDuration: Int
    @Binding var customDuration: String
    @Binding var startedMinutesAgo: Int
    @Binding var customStartedAt: Date

    private let presetDurations = [15, 30, 45, 60, 0] // 0 = open-ended
    private let presetStartedAgo = [0, 5, 15, 30] // 0 = now
    private let storage = StorageService.shared

    private let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.2, green: 0.8, blue: 0.75),
            Color(red: 0.35, green: 0.5, blue: 0.95)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    private var isOpenEnded: Bool {
        selectedDuration == 0
    }

    private var effectiveDuration: TimeInterval {
        if selectedDuration == 0 { return 0 } // open-ended
        if selectedDuration == -1, let custom = Int(customDuration), custom > 0 {
            return TimeInterval(custom * 60)
        }
        return TimeInterval(selectedDuration * 60)
    }

    private var effectiveStartDate: Date {
        if startedMinutesAgo == -1 {
            // Time-of-day picker — interpret as today; if future, roll back a day.
            let now = Date()
            let cal = Calendar.current
            let comps = cal.dateComponents([.hour, .minute], from: customStartedAt)
            var todayComps = cal.dateComponents([.year, .month, .day], from: now)
            todayComps.hour = comps.hour
            todayComps.minute = comps.minute
            todayComps.second = 0
            let candidate = cal.date(from: todayComps) ?? now
            return candidate > now ? candidate.addingTimeInterval(-86400) : candidate
        }
        return Date().addingTimeInterval(-TimeInterval(max(0, startedMinutesAgo) * 60))
    }

    private var effectiveStartedAgo: TimeInterval {
        max(0, Date().timeIntervalSince(effectiveStartDate))
    }

    private var willLogCompleted: Bool {
        !isOpenEnded && effectiveStartedAgo >= effectiveDuration && effectiveDuration > 0
    }

    private var canStart: Bool {
        !client.trimmingCharacters(in: .whitespaces).isEmpty && (isOpenEnded || effectiveDuration > 0)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("New Session")
                .font(.system(.headline, design: .rounded))
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 14) {
                clientField
                taskField
                focusAppField
                durationPicker
                startedAgoPicker
            }
            .padding(.horizontal, 16)

            Spacer()

            startButton
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Subviews

    private var clientSuggestions: [String] {
        let trimmed = client.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return storage.recentClients }
        return storage.recentClients.filter {
            $0.lowercased().contains(trimmed) && $0.lowercased() != trimmed
        }
    }

    private var clientField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Client")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    TextField("Client name", text: $client)
                        .textFieldStyle(.roundedBorder)

                    if !storage.recentClients.isEmpty {
                        Menu {
                            Menu("Remove…") {
                                ForEach(storage.recentClients, id: \.self) { name in
                                    Button("Remove \(name)", role: .destructive) {
                                        storage.removeRecentClient(name)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 20, height: 20)
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }
                }

                if !clientSuggestions.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(clientSuggestions.prefix(3), id: \.self) { name in
                            Button {
                                client = name
                            } label: {
                                Text(name)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.primary.opacity(0.08))
                                    )
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                    .transition(.opacity)
                }
            }
        }
    }

    private var taskField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Task")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("What are you working on?", text: $task)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var focusAppField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Focus apps (optional, comma-separated)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("e.g. Arc, Terminal", text: $focusApp)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Duration")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(presetDurations, id: \.self) { mins in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedDuration = mins
                        }
                    } label: {
                        Text(mins == 0 ? "Open" : "\(mins)m")
                            .font(.system(.callout, design: .rounded).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedDuration == mins
                                        ? AnyShapeStyle(accentGradient)
                                        : AnyShapeStyle(Color.primary.opacity(0.06)))
                            )
                            .foregroundColor(selectedDuration == mins ? .white : .primary)
                            .scaleEffect(selectedDuration == mins ? 1.04 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: selectedDuration)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 6) {
                Button {
                    selectedDuration = -1
                } label: {
                    Text("Custom:")
                        .font(.caption)
                        .foregroundColor(selectedDuration == -1 ? .primary : .secondary)
                }
                .buttonStyle(.plain)

                TextField("mins", text: $customDuration)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 56)
                    .onChange(of: customDuration) { _, _ in
                        selectedDuration = -1
                    }

                Text("minutes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var startedAgoPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Started")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 6) {
                ForEach(presetStartedAgo, id: \.self) { mins in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            startedMinutesAgo = mins
                        }
                    } label: {
                        Text(mins == 0 ? "Now" : "\(mins)m ago")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(startedMinutesAgo == mins
                                        ? AnyShapeStyle(accentGradient)
                                        : AnyShapeStyle(Color.primary.opacity(0.06)))
                            )
                            .foregroundColor(startedMinutesAgo == mins ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 6) {
                Button {
                    startedMinutesAgo = -1
                } label: {
                    Text("At:")
                        .font(.caption)
                        .foregroundColor(startedMinutesAgo == -1 ? .primary : .secondary)
                }
                .buttonStyle(.plain)

                hourMinuteFields

                Spacer()
            }
        }
    }

    private var hourMinuteFields: some View {
        let cal = Calendar.current
        let hour = Binding<Int>(
            get: { cal.component(.hour, from: customStartedAt) },
            set: { newHour in
                var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: customStartedAt)
                comps.hour = max(0, min(23, newHour))
                if let d = cal.date(from: comps) { customStartedAt = d }
                startedMinutesAgo = -1
            }
        )
        let minute = Binding<Int>(
            get: { cal.component(.minute, from: customStartedAt) },
            set: { newMin in
                var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: customStartedAt)
                comps.minute = max(0, min(59, newMin))
                if let d = cal.date(from: comps) { customStartedAt = d }
                startedMinutesAgo = -1
            }
        )

        return HStack(spacing: 4) {
            TextField("", value: hour, formatter: NumberFormatter())
                .textFieldStyle(.roundedBorder)
                .frame(width: 40)
                .multilineTextAlignment(.center)

            Text(":").font(.system(.body, design: .rounded))

            TextField("", value: minute, formatter: NumberFormatter())
                .textFieldStyle(.roundedBorder)
                .frame(width: 40)
                .multilineTextAlignment(.center)

            Text("(24h)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var startButton: some View {
        Button {
            timerManager.start(
                client: client.trimmingCharacters(in: .whitespaces),
                task: task.trimmingCharacters(in: .whitespaces),
                duration: effectiveDuration,
                focusAppName: focusApp.trimmingCharacters(in: .whitespaces),
                startedAt: effectiveStartDate
            )
        } label: {
            Text(willLogCompleted ? "Log Session" : "Start Timer")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(canStart
                            ? AnyShapeStyle(accentGradient)
                            : AnyShapeStyle(Color.primary.opacity(0.08)))
                )
                .foregroundColor(canStart ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .disabled(!canStart)
    }
}
