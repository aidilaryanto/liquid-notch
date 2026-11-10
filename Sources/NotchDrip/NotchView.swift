import SwiftUI

struct NotchView: View {
    @ObservedObject var model: NotchModel
    @ObservedObject var music: MusicService
    @ObservedObject var volume: VolumeService
    @ObservedObject var brightness: BrightnessService
    @ObservedObject var notifications: NotificationService
    let geometry: NotchGeometry

    init(model: NotchModel, geometry: NotchGeometry) {
        self._model = ObservedObject(wrappedValue: model)
        self._music = ObservedObject(wrappedValue: model.music)
        self._volume = ObservedObject(wrappedValue: model.volume)
        self._brightness = ObservedObject(wrappedValue: model.brightness)
        self._notifications = ObservedObject(wrappedValue: model.notifications)
        self.geometry = geometry
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black)
                    .frame(width: geometry.width, height: geometry.height)
                if model.isExpanded {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 96, height: 34)
                        .offset(y: geometry.height - 6)
                        .transition(.scale(scale: 0.2, anchor: .top).combined(with: .opacity))
                }
                if model.isExpanded {
                    expandedCard
                        .offset(y: geometry.height + 26)
                        .transition(.scale(scale: 0.25, anchor: .top).combined(with: .opacity))
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0), value: model.isExpanded)
        .animation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0), value: model.kind)
        .onHover { hovering in
            if hovering && !model.isExpanded {
                model.show(.notification)
            }
        }
        .onTapGesture {
            model.toggle(.music)
        }
    }

    private var expandedCard: some View {
        let size = model.kind.expandedSize
        return ZStack {
            RoundedRectangle(cornerRadius: size.height > 120 ? 26 : size.height / 2, style: .continuous)
                .fill(Color.black)
                .frame(width: size.width, height: size.height)
            content
                .frame(width: size.width - 32, height: size.height - 16, alignment: .leading)
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private var content: some View {
        switch model.kind {
        case .music:
            musicCard
        case .volume:
            HStack(spacing: 10) {
                Button { volume.toggleMute() } label: {
                    Circle().fill(Color.blue).frame(width: 38, height: 38)
                        .overlay(Text(volume.isMuted ? "✕" : "♪").foregroundColor(.white))
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Volume · \(Int(volume.level * 100))%").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    Slider(value: Binding(get: { volume.level }, set: { volume.setLevel($0) }), in: 0...1)
                        .tint(.white)
                }
            }
        case .brightness:
            HStack(spacing: 10) {
                Circle().fill(Color.orange).frame(width: 38, height: 38)
                    .overlay(Text("☀").foregroundColor(.white))
                VStack(alignment: .leading, spacing: 6) {
                    Text("Brightness · \(Int(brightness.level * 100))%").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    Slider(value: Binding(get: { brightness.level }, set: { brightness.setLevel($0) }), in: 0...1)
                        .tint(.white)
                }
            }
        case .notification:
            notificationCard
        }
    }

    private var musicCard: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
                .overlay(Text("♪").font(.title2).foregroundColor(.white))
            if let track = music.track {
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title).font(.system(size: 12, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    Text("\(track.artist) · \(track.source)").font(.system(size: 11)).foregroundColor(.white.opacity(0.75)).lineLimit(1)
                    ProgressView(value: track.position, total: max(track.duration, 1)).tint(.white).frame(height: 4)
                    HStack(spacing: 16) {
                        Button("⏮") { music.previousTrack() }.buttonStyle(.plain)
                        Button(track.isPlaying ? "⏸" : "▶") { music.togglePlayPause() }.buttonStyle(.plain)
                        Button("⏭") { music.nextTrack() }.buttonStyle(.plain)
                    }
                    .font(.system(size: 15)).foregroundColor(.white.opacity(0.9))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tidak ada musik").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                    Text("Putar lagu di Spotify atau Music").font(.system(size: 11)).foregroundColor(.white.opacity(0.75))
                }
            }
        }
    }

    private var notificationCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if notifications.access == .denied {
                Text("Notifikasi butuh Full Disk Access").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text("System Settings → Privacy & Security → Full Disk Access → NotchDrip").font(.system(size: 11)).foregroundColor(.white.opacity(0.75))
            } else if notifications.items.isEmpty {
                Text("Belum ada notifikasi").font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                Text("Notifikasi 7 hari terakhir akan muncul di sini").font(.system(size: 11)).foregroundColor(.white.opacity(0.75))
            } else {
                ForEach(notifications.items.prefix(3)) { item in
                    Button { notifications.openApp(bundleId: item.bundleIdentifier) } label: {
                        HStack(alignment: .top, spacing: 8) {
                            if let icon = notifications.icon(bundleId: item.bundleIdentifier) {
                                Image(nsImage: icon).resizable().frame(width: 28, height: 28)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text("\(item.appName) · \(item.date.formatted(date: .omitted, time: .shortened))").font(.system(size: 10, weight: .bold)).foregroundColor(.white.opacity(0.75))
                                Text(item.title).font(.system(size: 12, weight: .bold)).foregroundColor(.white).lineLimit(1)
                                if !item.body.isEmpty {
                                    Text(item.body).font(.system(size: 11)).foregroundColor(.white.opacity(0.75)).lineLimit(2)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
