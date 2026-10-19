// Renders every assets/branding/*.svg to a 1024px PNG next to it (macOS only).
// Run from the repo root, then regenerate platform icons:
//   swift scripts/render_brand_icons.swift && dart run flutter_launcher_icons
import AppKit

let size = 1024
let dir = URL(fileURLWithPath: "assets/branding")
let svgs = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
  .filter { $0.pathExtension == "svg" }

for svg in svgs {
  guard let image = NSImage(contentsOf: svg) else { fatalError("Cannot read \(svg.path)") }
  let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
    bytesPerRow: 0, bitsPerPixel: 0)!
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
  image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
  NSGraphicsContext.current = nil
  let png = svg.deletingPathExtension().appendingPathExtension("png")
  try rep.representation(using: .png, properties: [:])!.write(to: png)
  print("Rendered \(png.lastPathComponent)")
}
