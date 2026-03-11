import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @State private var notionAPIKey = ""
    @State private var notionDatabaseID = ""
    @State private var soundEnabled = true
    @State private var openAtLogin = SMAppService.mainApp.status == .enabled
    @State private var showSaved = false

    private let storage = StorageService.shared

    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.system(.headline, design: .rounded))
                .padding(.top, 16)
                .padding(.bottom, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    notionSection
                    Divider()
                    preferencesSection
                    saveButton
                    Spacer(minLength: 16)
                    quitButton
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear {
            notionAPIKey = storage.notionAPIKey
            notionDatabaseID = storage.notionDatabaseID
            soundEnabled = storage.soundEnabled
        }
    }

    // MARK: - Sections

    private var notionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Notion Integration", systemImage: "link")
                .font(.subheadline.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SecureField("secret_...", text: $notionAPIKey)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Database ID")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Paste database ID here", text: $notionDatabaseID)
                    .textFieldStyle(.roundedBorder)
            }

            Text("Properties: Client (title), Task (text), Planned (min) (number), Actual (min) (number), Date (date), Status (select: Completed/Stopped).")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Preferences", systemImage: "gearshape")
                .font(.subheadline.weight(.semibold))

            Toggle("Play sound on completion", isOn: $soundEnabled)
                .font(.callout)

            Toggle("Open at login", isOn: $openAtLogin)
                .font(.callout)
                .onChange(of: openAtLogin) { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        openAtLogin = !newValue
                    }
                }
        }
    }

    private var saveButton: some View {
        Button {
            storage.notionAPIKey = notionAPIKey
            storage.notionDatabaseID = notionDatabaseID
            storage.soundEnabled = soundEnabled
            showSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSaved = false
            }
        } label: {
            HStack(spacing: 6) {
                if showSaved {
                    Image(systemName: "checkmark")
                    Text("Saved!")
                } else {
                    Text("Save Settings")
                }
            }
            .font(.system(.callout, design: .rounded).weight(.medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(showSaved ? Color.green : Color.accentColor)
            )
            .foregroundColor(.white)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: showSaved)
    }

    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit Menu Bar Timer")
                .font(.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundColor(.red)
        }
        .buttonStyle(.plain)
    }
}
