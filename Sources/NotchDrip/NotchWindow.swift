import AppKit
import SwiftUI

final class NotchWindow: NSPanel {
    init(model: NotchModel, geometry: NotchGeometry) {
        let screen = NSScreen.main
        let frame = NSRect(
            x: geometry.centerX - 230,
            y: (screen?.frame.maxY ?? 900) - 240,
            width: 460,
            height: 240
        )
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isFloatingPanel = true
        contentView = NSHostingView(rootView: NotchView(model: model, geometry: geometry))
    }
}
