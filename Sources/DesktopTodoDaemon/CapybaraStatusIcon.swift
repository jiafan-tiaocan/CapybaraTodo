import AppKit

enum CapybaraStatusIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            let ink = NSColor.black
            ink.setStroke()
            ink.setFill()

            // 侧身全身轮廓：楔形长头、桶状身体、无尾和短腿共同建立物种识别。
            let body = NSBezierPath()
            body.move(to: NSPoint(x: 1.4, y: 10.2))
            body.line(to: NSPoint(x: 2.2, y: 11.8))
            body.curve(
                to: NSPoint(x: 5.4, y: 12.9),
                controlPoint1: NSPoint(x: 3.0, y: 12.7),
                controlPoint2: NSPoint(x: 4.3, y: 13.1)
            )
            body.curve(
                to: NSPoint(x: 8.0, y: 11.3),
                controlPoint1: NSPoint(x: 6.2, y: 12.8),
                controlPoint2: NSPoint(x: 7.1, y: 11.7)
            )
            body.line(to: NSPoint(x: 14.2, y: 11.3))
            body.curve(
                to: NSPoint(x: 16.3, y: 8.0),
                controlPoint1: NSPoint(x: 15.6, y: 11.0),
                controlPoint2: NSPoint(x: 16.3, y: 9.7)
            )
            body.curve(
                to: NSPoint(x: 15.3, y: 4.2),
                controlPoint1: NSPoint(x: 16.4, y: 6.4),
                controlPoint2: NSPoint(x: 16.0, y: 5.1)
            )
            body.line(to: NSPoint(x: 15.3, y: 2.6))
            body.line(to: NSPoint(x: 13.8, y: 2.6))
            body.line(to: NSPoint(x: 13.5, y: 4.1))
            body.line(to: NSPoint(x: 8.4, y: 4.1))
            body.line(to: NSPoint(x: 8.0, y: 2.5))
            body.line(to: NSPoint(x: 6.5, y: 2.5))
            body.line(to: NSPoint(x: 6.4, y: 4.5))
            body.curve(
                to: NSPoint(x: 3.2, y: 5.3),
                controlPoint1: NSPoint(x: 5.3, y: 4.7),
                controlPoint2: NSPoint(x: 4.1, y: 4.9)
            )
            body.line(to: NSPoint(x: 1.4, y: 7.0))
            body.close()
            body.lineWidth = 1.25
            body.lineJoinStyle = .round
            body.lineCapStyle = .round
            body.stroke()

            // 小耳贴近头顶，不使用熊类的大圆耳。
            let ear = NSBezierPath(ovalIn: NSRect(x: 5.0, y: 12.2, width: 1.7, height: 1.8))
            ear.lineWidth = 1.0
            ear.stroke()

            // 一条向上拱的短弧，表达安静但有生命力的眯眼。
            let eye = NSBezierPath()
            eye.move(to: NSPoint(x: 3.1, y: 10.0))
            eye.curve(
                to: NSPoint(x: 4.6, y: 10.0),
                controlPoint1: NSPoint(x: 3.5, y: 10.6),
                controlPoint2: NSPoint(x: 4.2, y: 10.6)
            )
            eye.lineWidth = 1.05
            eye.lineCapStyle = .round
            eye.stroke()

            // 钝鼻位于楔形头最前端；卡皮巴拉没有可见尾巴。
            NSBezierPath(roundedRect: NSRect(x: 1.0, y: 8.0, width: 1.25, height: 1.1), xRadius: 0.5, yRadius: 0.5).fill()

            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "眯眼卡皮巴拉待办"
        return image
    }()
}
