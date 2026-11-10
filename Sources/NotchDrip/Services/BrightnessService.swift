import IOKit
import IOKit.graphics
import SwiftUI

@MainActor
final class BrightnessService: ObservableObject {
    @Published var level: Double = 0.75
    @Published var isAvailable = false
    private var timer: Timer?

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        if let value = readBrightness() {
            level = Double(value)
            isAvailable = true
        } else {
            isAvailable = false
        }
    }

    func setLevel(_ value: Double) {
        let clamped = Float(max(0, min(1, value)))
        guard writeBrightness(clamped) else { return }
        level = Double(clamped)
    }

    private func displayService() -> io_service_t {
        IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"))
    }

    private func readBrightness() -> Float? {
        let service = displayService()
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var value: Float = 0
        guard IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &value) == kIOReturnSuccess else { return nil }
        return value
    }

    private func writeBrightness(_ value: Float) -> Bool {
        let service = displayService()
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }
        return IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, value) == kIOReturnSuccess
    }
}
