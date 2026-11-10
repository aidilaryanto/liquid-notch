import SwiftUI

struct ControlPanelView: View {
    @ObservedObject var model: NotchModel
    @ObservedObject var music: MusicService
    @ObservedObject var volume: VolumeService
    @ObservedObject var brightness: BrightnessService
    @ObservedObject var notifications: NotificationService

    init(model: NotchModel) {
        self._model = ObservedObject(wrappedValue: model)
        self._music = ObservedObject(wrappedValue: model.music)
        self._volume = ObservedObject(wrappedValue: model.volume)
        self._brightness = ObservedObject(wrappedValue: model.brightness)
        self._notifications = ObservedObject(wrappedValue: model.notifications)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NotchDrip — Inti").font(.headline)
            Text("Hover notch = notifikasi, klik notch = musik.").font(.subheadline).foregroundColor(.secondary)
            ForEach(NotchKind.allCases, id: \.self) { kind in
                Button(kind.title) { model.show(kind) }
            }
            Divider()
            Text("Musik: \(music.track.map { "\($0.title) — \($0.artist) (\($0.source))" } ?? "tidak ada")").font(.subheadline)
            Text("Volume: \(Int(volume.level * 100))% \(volume.isMuted ? "(mute)" : "")").font(.subheadline)
            Text("Brightness: \(Int(brightness.level * 100))%").font(.subheadline)
            Text("Notifikasi: \(notifications.items.count) item (\(accessLabel))").font(.subheadline)
            Text("Izin: Automation untuk Spotify/Music (ditanya saat pertama dipakai), Full Disk Access untuk notifikasi.").font(.subheadline).foregroundColor(.secondary)
            Toggle("Tahan pill (jangan auto-tutup)", isOn: $model.isPinned)
            Button("Tutup pill") { model.hide() }
            Button("Quit") { NSApplication.shared.terminate(nil) }
            Spacer()
        }
        .padding(16)
        .frame(width: 320, height: 420)
    }

    private var accessLabel: String {
        switch notifications.access {
        case .available: return "terbaca"
        case .denied: return "butuh Full Disk Access"
        case .unavailable: return "database tidak ditemukan"
        case .unknown: return "mengecek"
        }
    }
}
