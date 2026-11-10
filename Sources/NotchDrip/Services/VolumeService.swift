import CoreAudio
import SwiftUI

@MainActor
final class VolumeService: ObservableObject {
    @Published var level: Double = 0.5
    @Published var isMuted = false
    @Published var isAvailable = false
    private var timer: Timer?

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        guard let device = defaultOutputDevice() else {
            isAvailable = false
            return
        }
        isAvailable = true
        if let value = channelVolume(device: device) {
            level = value
        }
        isMuted = channelMuted(device: device)
    }

    func setLevel(_ value: Double) {
        guard let device = defaultOutputDevice() else { return }
        let clamped = Float(max(0, min(1, value)))
        setChannelVolume(device: device, value: clamped)
        level = Double(clamped)
    }

    func toggleMute() {
        guard let device = defaultOutputDevice() else { return }
        let muted: UInt32 = isMuted ? 0 : 1
        setChannelMute(device: device, value: muted)
        isMuted = !isMuted
    }

    private func defaultOutputDevice() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var device = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, nil, &size, &device) == noErr else { return nil }
        return device
    }

    private func readChannel(device: AudioDeviceID, channel: UInt32, value: inout Float32) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: channel
        )
        var size = UInt32(MemoryLayout<Float32>.size)
        return AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr
    }

    private func channelVolume(device: AudioDeviceID) -> Double? {
        var left: Float32 = 0
        var right: Float32 = 0
        guard readChannel(device: device, channel: 1, value: &left) else { return nil }
        if !readChannel(device: device, channel: 2, value: &right) {
            right = left
        }
        return Double((left + right) / 2)
    }

    private func setChannelVolume(device: AudioDeviceID, value: Float32) {
        var volume = value
        for channel: UInt32 in [1, 2] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: channel
            )
            _ = AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<Float32>.size), &volume)
        }
    }

    private func channelMuted(device: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 1
        )
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &muted) == noErr else { return false }
        return muted != 0
    }

    private func setChannelMute(device: AudioDeviceID, value: UInt32) {
        var muted = value
        for channel: UInt32 in [1, 2] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: channel
            )
            _ = AudioObjectSetPropertyData(device, &address, 0, nil, UInt32(MemoryLayout<UInt32>.size), &muted)
        }
    }
}
