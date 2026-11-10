import AppKit
import SwiftUI

@main
struct NotchDripApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchWindow: NotchWindow?
    private var panelWindow: NSWindow?
    private let model = NotchModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        model.start()
        let geometry = NotchGeometry.measure(screen: NSScreen.main)
        let notch = NotchWindow(model: model, geometry: geometry)
        notch.orderFrontRegardless()
        notchWindow = notch
        let panel = NSWindow(
            contentRect: NSRect(x: 100, y: 300, width: 320, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "NotchDrip — Inti"
        panel.contentView = NSHostingView(rootView: ControlPanelView(model: model))
        panel.makeKeyAndOrderFront(nil)
        panelWindow = panel
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let updated = NotchGeometry.measure(screen: NSScreen.main)
            let replacement = NotchWindow(model: self.model, geometry: updated)
            self.notchWindow?.orderOut(nil)
            replacement.orderFrontRegardless()
            self.notchWindow = replacement
        }
    }
}
