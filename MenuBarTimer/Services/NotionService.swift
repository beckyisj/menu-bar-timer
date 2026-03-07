import Foundation

class NotionService {
    static let shared = NotionService()

    private let storage = StorageService.shared

    @Published var lastError: String?

    func logEntry(_ entry: TimeEntry) {
        guard !storage.notionAPIKey.isEmpty,
              !storage.notionDatabaseID.isEmpty else { return }

        let databaseID = Self.extractDatabaseID(from: storage.notionDatabaseID)
        guard !databaseID.isEmpty,
              let url = URL(string: "https://api.notion.com/v1/pages") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(storage.notionAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-06-28", forHTTPHeaderField: "Notion-Version")

        let plannedMins = entry.plannedDuration / 60.0
        let actualMins = entry.actualDuration / 60.0

        // Build name: "Task for Client" or just "Client" if no task
        let name: String
        if entry.task.isEmpty {
            name = entry.client
        } else {
            name = "\(entry.task) for \(entry.client)"
        }

        let body: [String: Any] = [
            "parent": ["database_id": databaseID],
            "properties": [
                "Name": [
                    "title": [["text": ["content": name]]]
                ],
                "Client": [
                    "multi_select": [["name": entry.client]]
                ],
                "Planned (min)": [
                    "number": round(plannedMins * 10) / 10
                ],
                "Actual (min)": [
                    "number": round(actualMins * 10) / 10
                ],
                "Date": [
                    "date": ["start": Self.formatISO(entry.completedAt ?? Date())]
                ],
                "Status": [
                    "select": ["name": entry.status == .completed ? "Completed" : "Stopped"]
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                let msg = "Network error: \(error.localizedDescription)"
                print("[Notion] \(msg)")
                DispatchQueue.main.async { self?.lastError = msg }
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("[Notion] Entry logged successfully")
                    DispatchQueue.main.async { self?.lastError = nil }
                } else {
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "no body"
                    let msg = "HTTP \(httpResponse.statusCode)"
                    print("[Notion] \(msg): \(body)")
                    DispatchQueue.main.async { self?.lastError = msg }
                }
            }
        }.resume()
    }

    /// Extracts the 32-char database ID from a full Notion URL or returns the raw string if it's already an ID.
    /// Handles: https://www.notion.so/workspace/abc123...?v=... or just abc123...
    private static func extractDatabaseID(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = URL(string: trimmed), url.scheme == "https" {
            let path = url.path
            let segments = path.split(separator: "/")
            if let last = segments.last {
                let raw = String(last)
                let hex = raw.components(separatedBy: "-").last ?? raw
                if hex.count == 32, hex.allSatisfy({ $0.isHexDigit }) {
                    return formatUUID(hex)
                }
            }
            return ""
        }

        let cleaned = trimmed.replacingOccurrences(of: "-", with: "")
        if cleaned.count == 32, cleaned.allSatisfy({ $0.isHexDigit }) {
            return formatUUID(cleaned)
        }

        return trimmed
    }

    private static func formatUUID(_ hex: String) -> String {
        let h = hex
        let i = h.index(h.startIndex, offsetBy: 8)
        let j = h.index(i, offsetBy: 4)
        let k = h.index(j, offsetBy: 4)
        let l = h.index(k, offsetBy: 4)
        return "\(h[h.startIndex..<i])-\(h[i..<j])-\(h[j..<k])-\(h[k..<l])-\(h[l...])"
    }

    private static func formatISO(_ date: Date) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: date)
    }
}
