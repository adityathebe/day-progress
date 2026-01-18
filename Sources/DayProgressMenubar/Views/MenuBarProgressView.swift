import AppKit
import SwiftUI

struct MenuBarProgressView: View {
    let progress: Double
    let percentText: String

    var body: some View {
        HStack(spacing: 0) {
            Image(nsImage: MenuBarProgressImageProvider.image(progress: progress))
                .renderingMode(.template)

            Text(percentText)
                .monospacedDigit()
                .padding(.leading, 2)
        }
    }
}

enum MenuBarProgressImageProvider {
    static func image(progress: Double, size: NSSize = NSSize(width: 28, height: 12)) -> NSImage {
        let clamped = min(max(progress, 0), 1)
        let rect = NSRect(origin: .zero, size: size)
        let fillWidth = rect.width * clamped
        let radius = rect.height / 2.0

        let image = NSImage(size: size)
        image.isTemplate = true

        image.lockFocus()
        let context = NSGraphicsContext.current
        context?.imageInterpolation = .high

        NSColor.white.withAlphaComponent(0.35).setStroke()
        let outline = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        outline.lineWidth = 1
        outline.stroke()

        if fillWidth > 0 {
            NSColor.white.setFill()
            context?.saveGraphicsState()
            outline.addClip()
            let fillRect = NSRect(x: rect.minX, y: rect.minY, width: fillWidth, height: rect.height)
            let fillPath = NSBezierPath(rect: fillRect)
            fillPath.fill()
            context?.restoreGraphicsState()
        }

        image.unlockFocus()
        return image
    }
}
