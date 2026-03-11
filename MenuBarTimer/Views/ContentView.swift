import SwiftUI

enum AppTab {
    case timer
    case history
    case settings
}

struct ContentView: View {
    @EnvironmentObject var timerManager: TimerManager
    @State private var selectedTab: AppTab = .timer

    // Persist new-session form state across tab switches
    @State private var client = ""
    @State private var task = ""
    @State private var focusApp = ""
    @State private var selectedDuration: Int = 30
    @State private var customDuration: String = ""

    var body: some View {
        ZStack {
            // Subtle warm background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.8, blue: 0.75).opacity(0.03),
                    Color(red: 0.55, green: 0.35, blue: 0.95).opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .timer:
                        if timerManager.isRunning {
                            ActiveSessionView()
                        } else {
                            NewSessionView(
                                client: $client,
                                task: $task,
                                focusApp: $focusApp,
                                selectedDuration: $selectedDuration,
                                customDuration: $customDuration
                            )
                        }
                    case .history:
                        SessionHistoryView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()
                    .opacity(0.5)

                // Tab bar with pill indicator
                HStack(spacing: 0) {
                    tabButton(icon: "timer", label: "Timer", tab: .timer)
                    tabButton(icon: "list.bullet", label: "History", tab: .history)
                    tabButton(icon: "gear", label: "Settings", tab: .settings)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
            }
        }
        .frame(width: 320, height: 480)
    }

    private func tabButton(icon: String, label: String, tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? icon + (icon == "gear" ? ".circle.fill" : "") : icon)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                Text(label)
                    .font(.caption2.weight(isSelected ? .medium : .regular))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.primary.opacity(0.07) : Color.clear)
            )
            .foregroundColor(isSelected ? .primary : .secondary)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
