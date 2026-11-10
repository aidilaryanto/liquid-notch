import AppKit

struct NotchGeometry {
    let width: CGFloat
    let height: CGFloat
    let centerX: CGFloat

    static func measure(screen: NSScreen?) -> NotchGeometry {
        guard let screen else {
            return NotchGeometry(width: 200, height: 32, centerX: 720)
        }
        let top = screen.safeAreaInsets.top
        guard top > 0 else {
            return NotchGeometry(width: 200, height: 32, centerX: screen.frame.midX)
        }
        let leftWidth = screen.auxiliaryTopLeftArea?.width ?? 0
        let rightWidth = screen.auxiliaryTopRightArea?.width ?? 0
        let width = screen.frame.width - leftWidth - rightWidth
        return NotchGeometry(width: width, height: top, centerX: screen.frame.midX)
    }
}
