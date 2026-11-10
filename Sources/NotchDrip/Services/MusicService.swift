import AppKit
import SwiftUI

struct Track: Equatable {
    let title: String
    let artist: String
    let album: String
    let duration: Double
    let position: Double
    let isPlaying: Bool
    let source: String
}

@MainActor
final class MusicService: ObservableObject {
    @Published var track: Track?
    @Published var isAvailable = false
    private var timer: Timer?
    private let queue = DispatchQueue(label: "com.notchdrip.music", qos: .utility)

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        queue.async { [weak self] in
            guard let self else { return }
            let found = self.queryPlayer(appName: "Spotify", bundleId: "com.spotify.client")
                ?? self.queryPlayer(appName: "Music", bundleId: "com.apple.Music")
            Task { @MainActor in
                self.track = found
                self.isAvailable = found != nil
            }
        }
    }

    func togglePlayPause() {
        guard let app = activeAppName() else { return }
        runCommand(appName: app, command: "playpause")
        refresh()
    }

    func nextTrack() {
        guard let app = activeAppName() else { return }
        runCommand(appName: app, command: "next track")
        refresh()
    }

    func previousTrack() {
        guard let app = activeAppName() else { return }
        runCommand(appName: app, command: "previous track")
        refresh()
    }

    private func activeAppName() -> String? {
        if let source = track?.source {
            return source
        }
        if isRunning(bundleId: "com.spotify.client") {
            return "Spotify"
        }
        if isRunning(bundleId: "com.apple.Music") {
            return "Music"
        }
        return nil
    }

    private nonisolated func isRunning(bundleId: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId }
    }

    private nonisolated func runScript(_ source: String) -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else { return nil }
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }

    private nonisolated func queryPlayer(appName: String, bundleId: String) -> Track? {
        guard isRunning(bundleId: bundleId) else { return nil }
        let script = """
        tell application "\(appName)"
            if player state is playing then
                return "playing|" & (name of current track) & "|" & (artist of current track) & "|" & (album of current track) & "|" & (duration of current track) & "|" & (player position)
            else if player state is paused then
                return "paused|" & (name of current track) & "|" & (artist of current track) & "|" & (album of current track) & "|" & (duration of current track) & "|" & (player position)
            else
                return "stopped"
            end if
        end tell
        """
        guard let output = runScript(script) else { return nil }
        let parts = output.components(separatedBy: "|")
        guard parts.count == 6, parts[0] != "stopped" else { return nil }
        return Track(
            title: parts[1],
            artist: parts[2],
            album: parts[3],
            duration: Double(parts[4]) ?? 0,
            position: Double(parts[5]) ?? 0,
            isPlaying: parts[0] == "playing",
            source: appName
        )
    }

    private func runCommand(appName: String, command: String) {
        guard isRunning(bundleId: appName == "Spotify" ? "com.spotify.client" : "com.apple.Music") else { return }
        queue.async { [weak self] in
            _ = self?.runScript("tell application \"\(appName)\" to \(command)")
        }
    }
}
