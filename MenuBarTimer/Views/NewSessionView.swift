import SwiftUI

struct NewSessionView: View {
    @EnvironmentObject var timerManager: TimerManager
    @Binding var client: String
    @Binding var task: String
    @Binding var focusApp: String
    @Binding var selectedDuration: Int
    @Binding var customDuration: String

    private let presetDurations = [15, 30, 45, 60, 0] // 0 = open-ended
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
            Text("Focus app (optional)")
                .font(.caption)
                .foregroundColor(.secondary)
            TextField("e.g. Notion, Cursor, Figma", text: $focusApp)
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

    private var startButton: some View {
        Button {
            timerManager.start(
                client: client.trimmingCharacters(in: .whitespaces),
                task: task.trimmingCharacters(in: .whitespaces),
                duration: effectiveDuration,
                focusAppName: focusApp.trimmingCharacters(in: .whitespaces)
            )
        } label: {
            Text("Start Timer")
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
