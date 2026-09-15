import AppKit

let destination = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: destination, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let n = base * scale
        let size = CGFloat(n)
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        let tile = NSBezierPath(roundedRect: NSRect(x: size * 0.06, y: size * 0.06, width: size * 0.88, height: size * 0.88), xRadius: size * 0.21, yRadius: size * 0.21)
        NSGradient(starting: NSColor(srgbRed: 0.18, green: 0.34, blue: 0.92, alpha: 1), ending: NSColor(srgbRed: 0.38, green: 0.56, blue: 1, alpha: 1))!.draw(in: tile, angle: 50)
        NSColor.white.setFill()
        NSBezierPath(roundedRect: NSRect(x: size * 0.32, y: size * 0.21, width: size * 0.36, height: size * 0.59), xRadius: size * 0.18, yRadius: size * 0.18).fill()
        NSColor(srgbRed: 0.25, green: 0.43, blue: 0.96, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: size * 0.475, y: size * 0.58, width: size * 0.05, height: size * 0.12), xRadius: size * 0.025, yRadius: size * 0.025).fill()
        image.unlockFocus()
        let bitmap = NSBitmapImageRep(data: image.tiffRepresentation!)!
        let data = bitmap.representation(using: .png, properties: [:])!
        let suffix = scale == 2 ? "@2x" : ""
        try data.write(to: URL(fileURLWithPath: "\(destination)/icon_\(base)x\(base)\(suffix).png"))
    }
}
