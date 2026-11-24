import Foundation

enum WidgetSnapshotStore {
    static let kind = "ScheduleHomeWidget"

    static var fileURL: URL? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "ScheduleWidgetAppGroup") as? String else {
            return nil
        }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent("schedule-widget-v1.json")
    }

    static func read() -> WidgetSnapshot? {
        guard let fileURL, let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
              snapshot.version == 1 else { return nil }
        return snapshot
    }
}

struct WidgetSnapshot: Decodable {
    struct Day: Decodable {
        struct Item: Decodable {
            let lead: String
            let title: String
            let done: Bool
        }

        let count: Int
        let items: [Item]
    }

    let version: Int
    let days: [String: Day]
    let weeks: [String: Int]
    let months: [String: Int]
}
