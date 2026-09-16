import AppKit
import Foundation

let canvasSize = NSSize(width: 256, height: 256)
let output = NSImage(size: canvasSize)
output.lockFocus()

NSColor(calibratedWhite: 0.96, alpha: 1).setFill()
NSBezierPath(roundedRect: NSRect(origin: .zero, size: canvasSize), xRadius: 36, yRadius: 36).fill()

let icon = CapybaraStatusIcon.image
icon.isTemplate = false
icon.draw(
    in: NSRect(x: 32, y: 32, width: 192, height: 192),
    from: NSRect(origin: .zero, size: icon.size),
    operation: .sourceOver,
    fraction: 1
)

output.unlockFocus()

guard let tiff = output.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("无法渲染图标预览")
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try png.write(to: outputURL, options: .atomic)
print(outputURL.path)

