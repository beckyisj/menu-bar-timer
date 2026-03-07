import SwiftUI

struct SessionHistoryView: View {
    @State private var entries: [TimeEntry] = []
    private let storage = StorageService.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("History")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if !entries.isEmpty {
                    Button("Clear") {
                        storage.clearEntries()
                        entries = []
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if entries.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 28))
                        .foregroundStyle(.tertiary)
                    Text("No sessions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(entries) { entry in
                            SessionRow(entry: entry)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            entries = storage.loadEntries()
        }
    }
}

struct SessionRow: View {
    let entry: TimeEntry

    private var statusColor: Color {
        switch entry.status {
        case .completed: return Color(red: 0.2, green: 0.8, blue: 0.55)
        case .stopped: return .orange
        case .running, .paused: return Color(red: 0.35, green: 0.5, blue: 0.95)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Colored left border
            RoundedRectangle(cornerRadius: 1.5)
                .fill(statusColor)
                .frame(width: 3)
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.client)
                        .font(.system(.callout, design: .rounded).weight(.medium))
                        .lineLimit(1)

                    if !entry.task.isEmpty {
                        Text(entry.task)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(entry.formattedActualDuration)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .monospacedDigit()

                    Text(formatDate(entry.startedAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 10)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.04))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func formatDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: date)
        } else {
            let f = DateFormatter()
            f.dateFormat = "MMM d, h:mm a"
            return f.string(from: date)
        }
    }
}
