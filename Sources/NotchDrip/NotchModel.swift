import SwiftUI

enum NotchKind: String, CaseIterable {
    case music
    case volume
    case brightness
    case notification

    var title: String {
        switch self {
        case .music: return "Musik"
        case .volume: return "Volume"
        case .brightness: return "Brightness"
        case .notification: return "Notifikasi"
        }
    }

    var expandedSize: CGSize {
        switch self {
        case .music: return CGSize(width: 430, height: 148)
        case .volume, .brightness: return CGSize(width: 380, height: 110)
        case .notification: return CGSize(width: 380, height: 180)
        }
    }
}

@MainActor
final class NotchModel: ObservableObject {
    @Published var isExpanded = false
    @Published var kind: NotchKind = .music
    @Published var isPinned = false
    let music = MusicService()
    let volume = VolumeService()
    let brightness = BrightnessService()
    let notifications = NotificationService()
    private var collapseTask: Task<Void, Never>?

    func show(_ kind: NotchKind) {
        collapseTask?.cancel()
        self.kind = kind
        isExpanded = true
        guard !isPinned else { return }
        collapseTask = Task {
            try? await Task.sleep(for: .seconds(3.8))
            guard !Task.isCancelled else { return }
            isExpanded = false
        }
    }

    func hide() {
        collapseTask?.cancel()
        isExpanded = false
    }

    func toggle(_ kind: NotchKind) {
        if isExpanded && self.kind == kind {
            hide()
        } else {
            show(kind)
        }
    }

    func start() {
        music.start()
        volume.start()
        brightness.start()
        notifications.start()
    }
}
