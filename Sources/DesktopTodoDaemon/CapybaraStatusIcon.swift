import AppKit

enum CapybaraStatusIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            let ink = NSColor.black

            // 两只短耳：小而圆，避免缩小后和头顶轮廓粘成一块。
            ink.setFill()
            NSBezierPath(ovalIn: NSRect(x: 3.8, y: 12.1, width: 2.25, height: 2.25)).fill()
            NSBezierPath(ovalIn: NSRect(x: 9.1, y: 12.4, width: 2.0, height: 2.0)).fill()

            // 卡皮巴拉最有识别度的是长而钝的鼻口，轮廓向右平缓延伸。
            let head = NSBezierPath()
            head.move(to: NSPoint(x: 3.0, y: 12.1))
            head.curve(
                to: NSPoint(x: 10.9, y: 12.8),
                controlPoint1: NSPoint(x: 4.8, y: 13.4),
                controlPoint2: NSPoint(x: 8.7, y: 13.5)
            )
            head.curve(
                to: NSPoint(x: 15.8, y: 10.2),
                controlPoint1: NSPoint(x: 13.2, y: 12.6),
                controlPoint2: NSPoint(x: 15.3, y: 11.6)
            )
            head.curve(
                to: NSPoint(x: 14.2, y: 6.1),
                controlPoint1: NSPoint(x: 16.5, y: 8.8),
                controlPoint2: NSPoint(x: 15.7, y: 6.8)
            )
            head.curve(
                to: NSPoint(x: 5.2, y: 4.2),
                controlPoint1: NSPoint(x: 11.9, y: 4.8),
                controlPoint2: NSPoint(x: 7.5, y: 3.8)
            )
            head.curve(
                to: NSPoint(x: 2.1, y: 8.2),
                controlPoint1: NSPoint(x: 3.1, y: 5.0),
                controlPoint2: NSPoint(x: 1.5, y: 6.6)
            )
            head.curve(
                to: NSPoint(x: 3.0, y: 12.1),
                controlPoint1: NSPoint(x: 1.9, y: 9.8),
                controlPoint2: NSPoint(x: 2.2, y: 11.2)
            )
            head.close()
            head.lineWidth = 1.45
            head.lineJoinStyle = .round
            ink.setStroke()
            head.stroke()

            // 一眼一鼻即可形成表情；保持留白，避免状态栏尺寸下变成黑块。
            NSBezierPath(ovalIn: NSRect(x: 10.5, y: 9.4, width: 1.45, height: 1.45)).fill()
            NSBezierPath(ovalIn: NSRect(x: 14.0, y: 8.4, width: 1.1, height: 1.1)).fill()

            let mouth = NSBezierPath()
            mouth.move(to: NSPoint(x: 13.3, y: 6.9))
            mouth.curve(
                to: NSPoint(x: 14.8, y: 7.0),
                controlPoint1: NSPoint(x: 13.9, y: 6.6),
                controlPoint2: NSPoint(x: 14.4, y: 6.7)
            )
            mouth.lineWidth = 0.9
            mouth.lineCapStyle = .round
            mouth.stroke()

            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "卡皮巴拉待办"
        return image
    }()
}
