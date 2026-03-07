import Foundation

class StorageService {
    static let shared = StorageService()

    private let entriesKey = "timeEntries"
    private let notionAPIKeyKey = "notionAPIKey"
    private let notionDatabaseIDKey = "notionDatabaseID"
    private let soundEnabledKey = "soundEnabled"
    private let recentClientsKey = "recentClients"

    private let defaults = UserDefaults.standard

    private init() {
        defaults.register(defaults: [soundEnabledKey: true])
    }

    // MARK: - Time Entries

    func saveEntries(_ entries: [TimeEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: entriesKey)
        }
    }

    func loadEntries() -> [TimeEntry] {
        guard let data = defaults.data(forKey: entriesKey),
              let entries = try? JSONDecoder().decode([TimeEntry].self, from: data) else {
            return []
        }
        return entries
    }

    func addEntry(_ entry: TimeEntry) {
        var entries = loadEntries()
        entries.insert(entry, at: 0)
        if entries.count > 200 {
            entries = Array(entries.prefix(200))
        }
        saveEntries(entries)
        addRecentClient(entry.client)
    }

    func clearEntries() {
        defaults.removeObject(forKey: entriesKey)
    }

    // MARK: - Settings

    var notionAPIKey: String {
        get { defaults.string(forKey: notionAPIKeyKey) ?? "" }
        set { defaults.set(newValue, forKey: notionAPIKeyKey) }
    }

    var notionDatabaseID: String {
        get { defaults.string(forKey: notionDatabaseIDKey) ?? "" }
        set { defaults.set(newValue, forKey: notionDatabaseIDKey) }
    }

    var soundEnabled: Bool {
        get { defaults.bool(forKey: soundEnabledKey) }
        set { defaults.set(newValue, forKey: soundEnabledKey) }
    }

    // MARK: - Recent Clients

    func addRecentClient(_ client: String) {
        guard !client.isEmpty else { return }
        var clients = recentClients
        clients.removeAll { $0.lowercased() == client.lowercased() }
        clients.insert(client, at: 0)
        if clients.count > 10 {
            clients = Array(clients.prefix(10))
        }
        defaults.set(clients, forKey: recentClientsKey)
    }

    var recentClients: [String] {
        defaults.stringArray(forKey: recentClientsKey) ?? []
    }
}
