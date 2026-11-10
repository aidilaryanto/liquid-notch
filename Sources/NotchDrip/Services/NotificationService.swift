import AppKit
import SQLite3
import SwiftUI

struct NotificationItem: Identifiable, Equatable {
    let id: Int
    let bundleIdentifier: String
    let appName: String
    let title: String
    let subtitle: String
    let body: String
    let date: Date
}

enum NotificationAccess {
    case unknown
    case available
    case denied
    case unavailable
}

@MainActor
final class NotificationService: ObservableObject {
    @Published var items: [NotificationItem] = []
    @Published var access: NotificationAccess = .unknown
    private var timer: Timer?
    private var nameCache: [String: String] = [:]
    private var iconCache: [String: NSImage] = [:]

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        guard let dbPath = databasePath() else {
            access = .unavailable
            return
        }
        switch readRecent(dbPath: dbPath) {
        case .denied:
            access = .denied
        case .ok(let found):
            access = .available
            items = found
        }
    }

    func icon(bundleId: String) -> NSImage? {
        if let cached = iconCache[bundleId] {
            return cached
        }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return nil }
        let image = NSWorkspace.shared.icon(forFile: url.path)
        iconCache[bundleId] = image
        return image
    }

    func openApp(bundleId: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return }
        NSWorkspace.shared.open(url)
    }

    private enum ReadResult {
        case denied
        case ok([NotificationItem])
    }

    private func databasePath() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let modern = home + "/Library/Group Containers/group.com.apple.usernoted/db2/db"
        if FileManager.default.fileExists(atPath: modern) {
            return modern
        }
        return legacyDatabasePath()
    }

    private func legacyDatabasePath() -> String? {
        var buffer = [CChar](repeating: 0, count: Int(PATH_MAX))
        guard confstr(_CS_DARWIN_USER_DIR, &buffer, buffer.count) > 0 else { return nil }
        let dir = String(cString: buffer)
        let path = dir + "com.apple.notificationcenter/db2/db"
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    private func readRecent(dbPath: String) -> ReadResult {
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK, let db else { return .denied }
        defer { sqlite3_close(db) }
        let threshold = Date().timeIntervalSinceReferenceDate - 7 * 86400
        let sql = "SELECT r.rec_id, a.identifier, r.delivered_date, r.data FROM record r JOIN app a ON r.app_id = a.app_id WHERE r.delivered_date > \(threshold) ORDER BY r.delivered_date DESC LIMIT 20"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return .denied }
        defer { sqlite3_finalize(statement) }
        var found: [NotificationItem] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let recId = Int(sqlite3_column_int(statement, 0))
            guard let rawId = sqlite3_column_text(statement, 1) else { continue }
            let bundleId = String(cString: UnsafeRawPointer(rawId).assumingMemoryBound(to: CChar.self))
            let delivered = sqlite3_column_double(statement, 2)
            guard let blob = sqlite3_column_blob(statement, 3) else { continue }
            let size = Int(sqlite3_column_bytes(statement, 3))
            let data = Data(bytes: blob, count: size)
            let (title, subtitle, body) = parsePlist(data)
            if title.isEmpty && body.isEmpty { continue }
            found.append(NotificationItem(
                id: recId,
                bundleIdentifier: bundleId,
                appName: appDisplayName(bundleId: bundleId),
                title: title,
                subtitle: subtitle,
                body: body,
                date: Date(timeIntervalSinceReferenceDate: delivered)
            ))
        }
        return .ok(found)
    }

    private func parsePlist(_ data: Data) -> (String, String, String) {
        guard let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let req = plist["req"] as? [String: Any] else { return ("", "", "") }
        let title = req["titl"] as? String ?? ""
        let subtitle = req["subt"] as? String ?? ""
        let body = req["body"] as? String ?? ""
        return (title, subtitle, body)
    }

    private func appDisplayName(bundleId: String) -> String {
        if let cached = nameCache[bundleId] {
            return cached
        }
        var name = bundleId
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId),
           let bundle = Bundle(url: url) {
            if let display = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
                name = display
            } else if let short = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                name = short
            } else {
                name = url.deletingPathExtension().lastPathComponent
            }
        }
        nameCache[bundleId] = name
        return name
    }
}
