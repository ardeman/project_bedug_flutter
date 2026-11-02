// Export the phone preview's Material glyphs from the installed Flutter SDK.
// Usage: swift scripts/export_site_icons.swift /path/to/flutter
import Foundation
import CoreText

let sdk = URL(fileURLWithPath: CommandLine.arguments[1])
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let names = [
    "bedtime_outlined", "wb_sunny_outlined", "wb_cloudy_outlined",
    "wb_twilight", "dark_mode_outlined", "access_time_filled",
    "mosque_outlined", "menu_book_outlined", "settings_outlined",
    "location_on_outlined", "refresh", "timer_outlined",
]
let definitions = try String(contentsOf: sdk.appendingPathComponent("packages/flutter/lib/src/material/icons.dart"), encoding: .utf8)
let fonts = sdk.appendingPathComponent("bin/cache/artifacts/material_fonts")
let provider = CGDataProvider(url: fonts.appendingPathComponent("MaterialIcons-Regular.otf") as CFURL)!
let graphicsFont = CGFont(provider)!
let font = CTFontCreateWithGraphicsFont(graphicsFont, 24, nil, nil)
var icons: [String: String] = [:]
func number(_ value: CGFloat) -> String {
    String(format: "%.4f", Double(value)).replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
}
for name in names {
    let regex = try NSRegularExpression(pattern: "static const IconData \(name) = IconData\\(\\s*(0x[0-9a-f]+)")
    let match = regex.firstMatch(in: definitions, range: NSRange(definitions.startIndex..., in: definitions))!
    let code = String(definitions[Range(match.range(at: 1), in: definitions)!])
    let scalar = UnicodeScalar(UInt32(code.dropFirst(2), radix: 16)!)!
    // CoreText maps supplementary-plane scalars through their UTF-16 pair.
    let characters = Array(String(scalar).utf16)
    var glyphs = [CGGlyph](repeating: 0, count: characters.count)
    CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count)
    precondition(glyphs[0] != 0, "Missing glyph: \(name)")
    var transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 24)
    let path = CTFontCreatePathForGlyph(font, glyphs[0], &transform)!
    var commands: [String] = []
    path.applyWithBlock { pointer in
        let element = pointer.pointee
        func point(_ i: Int) -> String {
            "\(number(element.points[i].x)) \(number(element.points[i].y))"
        }
        switch element.type {
        case .moveToPoint: commands.append("M\(point(0))")
        case .addLineToPoint: commands.append("L\(point(0))")
        case .addQuadCurveToPoint: commands.append("Q\(point(0)) \(point(1))")
        case .addCurveToPoint: commands.append("C\(point(0)) \(point(1)) \(point(2))")
        case .closeSubpath: commands.append("Z")
        @unknown default: fatalError("Unsupported path element")
        }
    }
    icons[name] = commands.joined(separator: " ")
}
let output = root.appendingPathComponent("site/static/vendor/material-icons")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let data = try JSONSerialization.data(withJSONObject: icons, options: [.prettyPrinted, .sortedKeys])
try data.write(to: output.appendingPathComponent("paths.json"))
let license = try Data(contentsOf: fonts.appendingPathComponent("MaterialIcons_LICENSE.txt"))
try license.write(to: output.appendingPathComponent("LICENSE"))
print("Exported \(icons.count) Material icons")
