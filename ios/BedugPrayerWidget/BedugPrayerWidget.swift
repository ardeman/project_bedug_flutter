import AppIntents
import SwiftUI
import WidgetKit

struct Prayer: Decodable {
    let key: String?
    let name: String
    let time: Double
    /// When this prayer's time ends early (Fajr at sunrise); otherwise the next prayer.
    let end: Double?
    var date: Date { Date(timeIntervalSince1970: time / 1000) }
    var endDate: Date? { end.map { Date(timeIntervalSince1970: $0 / 1000) } }

    // The sky at this prayer's time, shown in the countdown dial.
    var symbol: String {
        switch key {
        case "fajr": "moon"
        case "dhuhr": "sun.max"
        case "asr": "cloud"
        case "isha": "moon"
        default: "clock.fill"
        }
    }
}

// Google Material Icons nights_stay_outlined (CC BY 4.0).
// https://github.com/google/material-design-icons
// https://creativecommons.org/licenses/by/4.0/
// Glyph coordinates normalized from the same MaterialIcons font used by Flutter.
private struct MaghribIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.82422, y: 0.73047))
        path.addCurve(to: CGPoint(x: 0.46289, y: 0.50391), control1: CGPoint(x: 0.72070, y: 0.73047), control2: CGPoint(x: 0.55078, y: 0.67383))
        path.addCurve(to: CGPoint(x: 0.48438, y: 0.08398), control1: CGPoint(x: 0.36523, y: 0.31445), control2: CGPoint(x: 0.44141, y: 0.15039))
        path.addCurve(to: CGPoint(x: 0.08203, y: 0.50000), control1: CGPoint(x: 0.26172, y: 0.09180), control2: CGPoint(x: 0.08203, y: 0.27539))
        path.addCurve(to: CGPoint(x: 0.08398, y: 0.51758), control1: CGPoint(x: 0.08203, y: 0.50586), control2: CGPoint(x: 0.08398, y: 0.51172))
        path.addCurve(to: CGPoint(x: 0.16602, y: 0.50000), control1: CGPoint(x: 0.10938, y: 0.50586), control2: CGPoint(x: 0.13672, y: 0.50000))
        path.addCurve(to: CGPoint(x: 0.34570, y: 0.20508), control1: CGPoint(x: 0.16602, y: 0.37109), control2: CGPoint(x: 0.23828, y: 0.25977))
        path.addCurve(to: CGPoint(x: 0.38867, y: 0.54102), control1: CGPoint(x: 0.32422, y: 0.29492), control2: CGPoint(x: 0.32227, y: 0.41406))
        path.addCurve(to: CGPoint(x: 0.67188, y: 0.78516), control1: CGPoint(x: 0.45312, y: 0.66797), control2: CGPoint(x: 0.56250, y: 0.74805))
        path.addCurve(to: CGPoint(x: 0.50000, y: 0.83398), control1: CGPoint(x: 0.62109, y: 0.81641), control2: CGPoint(x: 0.56055, y: 0.83398))
        path.addCurve(to: CGPoint(x: 0.43750, y: 0.82812), control1: CGPoint(x: 0.47852, y: 0.83398), control2: CGPoint(x: 0.45703, y: 0.83203))
        path.addCurve(to: CGPoint(x: 0.36914, y: 0.89648), control1: CGPoint(x: 0.42188, y: 0.85742), control2: CGPoint(x: 0.39844, y: 0.88086))
        path.addCurve(to: CGPoint(x: 0.50000, y: 0.91797), control1: CGPoint(x: 0.41016, y: 0.91016), control2: CGPoint(x: 0.45508, y: 0.91797))
        path.addCurve(to: CGPoint(x: 0.84766, y: 0.72852), control1: CGPoint(x: 0.64453, y: 0.91797), control2: CGPoint(x: 0.77344, y: 0.84180))
        path.addCurve(to: CGPoint(x: 0.82422, y: 0.73047), control1: CGPoint(x: 0.84180, y: 0.72852), control2: CGPoint(x: 0.83203, y: 0.73047))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.29102, y: 0.66602))
        path.addLine(to: CGPoint(x: 0.28320, y: 0.66602))
        path.addCurve(to: CGPoint(x: 0.16602, y: 0.58398), control1: CGPoint(x: 0.26758, y: 0.61914), control2: CGPoint(x: 0.22070, y: 0.58398))
        path.addCurve(to: CGPoint(x: 0.04102, y: 0.70898), control1: CGPoint(x: 0.09766, y: 0.58398), control2: CGPoint(x: 0.04102, y: 0.63867))
        path.addCurve(to: CGPoint(x: 0.16602, y: 0.83398), control1: CGPoint(x: 0.04102, y: 0.77734), control2: CGPoint(x: 0.09766, y: 0.83398))
        path.addCurve(to: CGPoint(x: 0.29102, y: 0.83398), control1: CGPoint(x: 0.19336, y: 0.83398), control2: CGPoint(x: 0.26953, y: 0.83398))
        path.addCurve(to: CGPoint(x: 0.37500, y: 0.75000), control1: CGPoint(x: 0.33789, y: 0.83398), control2: CGPoint(x: 0.37500, y: 0.79492))
        path.addCurve(to: CGPoint(x: 0.29102, y: 0.66602), control1: CGPoint(x: 0.37500, y: 0.70508), control2: CGPoint(x: 0.33789, y: 0.66602))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: rect.width, y: rect.height)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

// Google Material Icons bedtime_outlined; attribution and license above MaghribIcon.
private struct FajrIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.38672, y: 0.18750))
        path.addCurve(to: CGPoint(x: 0.70508, y: 0.76172), control1: CGPoint(x: 0.31836, y: 0.50195), control2: CGPoint(x: 0.54297, y: 0.70508))
        path.addCurve(to: CGPoint(x: 0.50000, y: 0.83398), control1: CGPoint(x: 0.64844, y: 0.80664), control2: CGPoint(x: 0.57617, y: 0.83398))
        path.addCurve(to: CGPoint(x: 0.16602, y: 0.50000), control1: CGPoint(x: 0.31641, y: 0.83398), control2: CGPoint(x: 0.16602, y: 0.68359))
        path.addCurve(to: CGPoint(x: 0.38672, y: 0.18750), control1: CGPoint(x: 0.16602, y: 0.35547), control2: CGPoint(x: 0.25781, y: 0.23242))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.50000, y: 0.08398))
        path.addCurve(to: CGPoint(x: 0.08398, y: 0.50000), control1: CGPoint(x: 0.26758, y: 0.08398), control2: CGPoint(x: 0.08398, y: 0.27344))
        path.addCurve(to: CGPoint(x: 0.50000, y: 0.91602), control1: CGPoint(x: 0.08398, y: 0.73047), control2: CGPoint(x: 0.26953, y: 0.91602))
        path.addCurve(to: CGPoint(x: 0.86133, y: 0.70703), control1: CGPoint(x: 0.65430, y: 0.91602), control2: CGPoint(x: 0.78906, y: 0.83203))
        path.addCurve(to: CGPoint(x: 0.51367, y: 0.08398), control1: CGPoint(x: 0.54883, y: 0.69727), control2: CGPoint(x: 0.35742, y: 0.35547))
        path.addCurve(to: CGPoint(x: 0.50000, y: 0.08398), control1: CGPoint(x: 0.50977, y: 0.08398), control2: CGPoint(x: 0.50391, y: 0.08398))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: rect.width, y: rect.height)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

// Google Material Icons dark_mode_outlined; attribution and license above MaghribIcon.
private struct IshaIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.39062, y: 0.23047))
        path.addCurve(to: CGPoint(x: 0.37891, y: 0.31250), control1: CGPoint(x: 0.38281, y: 0.25586), control2: CGPoint(x: 0.37891, y: 0.28320))
        path.addCurve(to: CGPoint(x: 0.68750, y: 0.62109), control1: CGPoint(x: 0.37891, y: 0.48242), control2: CGPoint(x: 0.51758, y: 0.62109))
        path.addCurve(to: CGPoint(x: 0.76953, y: 0.60938), control1: CGPoint(x: 0.71680, y: 0.62109), control2: CGPoint(x: 0.74414, y: 0.61719))
        path.addCurve(to: CGPoint(x: 0.50000, y: 0.79102), control1: CGPoint(x: 0.72656, y: 0.71680), control2: CGPoint(x: 0.62305, y: 0.79102))
        path.addCurve(to: CGPoint(x: 0.20898, y: 0.50000), control1: CGPoint(x: 0.33984, y: 0.79102), control2: CGPoint(x: 0.20898, y: 0.66016))
        path.addCurve(to: CGPoint(x: 0.39062, y: 0.23047), control1: CGPoint(x: 0.20898, y: 0.37695), control2: CGPoint(x: 0.28320, y: 0.27344))
        path.closeSubpath()
        path.move(to: CGPoint(x: 0.50000, y: 0.12500))
        path.addCurve(to: CGPoint(x: 0.12500, y: 0.50000), control1: CGPoint(x: 0.29297, y: 0.12500), control2: CGPoint(x: 0.12500, y: 0.29297))
        path.addCurve(to: CGPoint(x: 0.50000, y: 0.87500), control1: CGPoint(x: 0.12500, y: 0.70703), control2: CGPoint(x: 0.29297, y: 0.87500))
        path.addCurve(to: CGPoint(x: 0.87500, y: 0.50000), control1: CGPoint(x: 0.70703, y: 0.87500), control2: CGPoint(x: 0.87500, y: 0.70703))
        path.addCurve(to: CGPoint(x: 0.87109, y: 0.44336), control1: CGPoint(x: 0.87500, y: 0.48047), control2: CGPoint(x: 0.87305, y: 0.46094))
        path.addCurve(to: CGPoint(x: 0.68750, y: 0.53711), control1: CGPoint(x: 0.83008, y: 0.50000), control2: CGPoint(x: 0.76367, y: 0.53711))
        path.addCurve(to: CGPoint(x: 0.46289, y: 0.31250), control1: CGPoint(x: 0.56250, y: 0.53711), control2: CGPoint(x: 0.46289, y: 0.43750))
        path.addCurve(to: CGPoint(x: 0.55664, y: 0.12891), control1: CGPoint(x: 0.46289, y: 0.23633), control2: CGPoint(x: 0.50000, y: 0.16992))
        path.addCurve(to: CGPoint(x: 0.50000, y: 0.12500), control1: CGPoint(x: 0.53906, y: 0.12695), control2: CGPoint(x: 0.51953, y: 0.12500))
        path.closeSubpath()
        return path.applying(CGAffineTransform(scaleX: rect.width, y: rect.height)
            .concatenating(CGAffineTransform(translationX: rect.minX, y: rect.minY)))
    }
}

private struct PrayerIcon: View {
    let prayer: Prayer
    let size: CGFloat

    var body: some View {
        Group {
            if prayer.key == "maghrib" {
                MaghribIcon().fill()
            } else if prayer.key == "isha" {
                IshaIcon().fill()
            } else if prayer.key == "fajr" {
                FajrIcon().fill()
            } else {
                Image(systemName: prayer.symbol).font(.system(size: size))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct PrayerWidgetData: Decodable {
    let prayers: [Prayer]
    let earlier: [Prayer]?
    let intervalStart: Double?
    let showAnalog: Bool?
    let showSchedule: Bool?
    let showCurrent: Bool?
    let location: String
    let locale: String
    let title: String
    let refresh: String
    let themeMode: Int
    let lightBackground: UInt32
    let darkBackground: UInt32
    let lightText: UInt32
    let darkText: UInt32
    let lightAccent: UInt32
    let darkAccent: UInt32

    static func load() -> PrayerWidgetData? {
        guard let text = UserDefaults(suiteName: "group.com.ardeman.bedug")?
            .string(forKey: "prayer_widget"), let bytes = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: bytes)
    }
}

struct PrayerEntry: TimelineEntry {
    let date: Date
    let data: PrayerWidgetData?
    let prayer: Prayer?
    /// On shows the prayer whose time it is now, with the next one beneath.
    var showCurrent = false

    /// The prayer whose time has come, if the cache reaches back to it and its
    /// time hasn't ended (none between sunrise and Dhuhr).
    var current: Prayer? {
        guard let latest = ((data?.earlier ?? []) + (data?.prayers ?? []))
            .last(where: { $0.date <= date }) else { return nil }
        if let end = latest.endDate, end <= date { return nil }
        return latest
    }

    /// The prayer to headline: the next one, or the current one when chosen.
    var headline: Prayer? {
        showCurrent ? current ?? prayer : prayer
    }

    /// True when the headline is the current prayer rather than the next.
    var showsCurrent: Bool { showCurrent && current != nil }

    /// The four prayers after the next one, which is already featured above.
    var upcoming: [Prayer] {
        Array((data?.prayers ?? []).filter { $0.date > date }.dropFirst().prefix(4))
    }

    /// Every prayer on the next prayer's day, including those already passed.
    var day: [Prayer] {
        guard let prayer else { return [] }
        return ((data?.earlier ?? []) + (data?.prayers ?? []))
            .filter { Calendar.current.isDate($0.date, inSameDayAs: prayer.date) }
    }

    /// The city without its administrative prefix, so it fits a lock screen line.
    var shortLocation: String {
        let location = data?.location ?? ""
        for prefix in ["Kota Administrasi ", "Kabupaten ", "Kab. ", "Kota "]
        where location.hasPrefix(prefix) {
            return String(location.dropFirst(prefix.count))
        }
        return location
    }

    var countdownStart: Date {
        data?.prayers.last(where: { $0.date <= date })?.date
            ?? data?.intervalStart.map { Date(timeIntervalSince1970: $0 / 1000) }
            ?? date
    }
}

struct PrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: .now, data: nil, prayer: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
        let data = PrayerWidgetData.load()
        completion(entry(at: .now, data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
        completion(Self.timeline())
    }

    static func timeline(showCurrent: Bool? = nil) -> Timeline<PrayerEntry> {
        let now = Date.now
        let data = PrayerWidgetData.load()
        let showCurrent = showCurrent ?? data?.showCurrent ?? false
        var entries = [entry(at: now, data: data, showCurrent: showCurrent)]
        // At each boundary select the following prayer; the final entry expires
        // the schedule instead of repeating yesterday's times indefinitely.
        var boundaries = (data?.prayers ?? []).map(\.date)
        // The current prayer can end before the next begins (Fajr at sunrise).
        if showCurrent {
            boundaries += ((data?.earlier ?? []) + (data?.prayers ?? [])).compactMap(\.endDate)
        }
        for date in Set(boundaries).sorted() where date > now {
            entries.append(entry(at: date, data: data, showCurrent: showCurrent))
        }
        return Timeline(entries: entries, policy: .never)
    }

    static func entry(at date: Date, data: PrayerWidgetData?, showCurrent: Bool? = nil) -> PrayerEntry {
        PrayerEntry(date: date, data: data,
                    prayer: data?.prayers.first(where: { $0.date > date }), showCurrent: showCurrent ?? data?.showCurrent ?? false)
    }

    private func entry(at date: Date, data: PrayerWidgetData?) -> PrayerEntry {
        Self.entry(at: date, data: data)
    }
}

/// The widget's Edit options: which prayer it headlines.
struct PrayerWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Next prayer"
    static let description = IntentDescription("Counts down to the next prayer, with its time and your city.")

    @Parameter(title: "Show current prayer")
    var showCurrent: Bool?
}

struct ConfigurablePrayerProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        PrayerEntry(date: .now, data: nil, prayer: nil)
    }

    func snapshot(for configuration: PrayerWidgetIntent, in context: Context) async -> PrayerEntry {
        PrayerProvider.entry(at: .now, data: PrayerWidgetData.load(), showCurrent: configuration.showCurrent)
    }

    func timeline(for configuration: PrayerWidgetIntent, in context: Context) async -> Timeline<PrayerEntry> {
        PrayerProvider.timeline(showCurrent: configuration.showCurrent)
    }
}

struct PrayerWidgetView: View {
    let entry: PrayerEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.widgetFamily) private var family

    private var dark: Bool {
        entry.data?.themeMode == 2 || (entry.data?.themeMode == 0 && colorScheme == .dark)
    }

    private func color(_ value: UInt32?) -> Color {
        guard let value else { return .primary }
        return Color(.sRGB, red: Double((value >> 16) & 255) / 255,
                     green: Double((value >> 8) & 255) / 255,
                     blue: Double(value & 255) / 255, opacity: 1)
    }

    private var accent: Color {
        renderingMode == .fullColor
            ? color(dark ? entry.data?.darkAccent : entry.data?.lightAccent) : .primary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 14 : 6) {
            HStack {
                Text(entry.showsCurrent ? AppLanguage.string("Now") : entry.data?.title ?? "Bedug")
                if family != .systemSmall {
                    Spacer(minLength: 8)
                    Text(entry.shortLocation.components(separatedBy: ",").first ?? "")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption).lineLimit(1).minimumScaleFactor(0.7)
            if let prayer = entry.prayer {
                if family == .systemSmall {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.headline?.name ?? prayer.name).font(.title.bold())
                                .foregroundStyle(accent).widgetAccentable()
                            timeLine(for: prayer).font(.caption)
                        }
                        .lineLimit(1).minimumScaleFactor(0.65)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if entry.data?.showAnalog != false {
                            countdownDial(for: prayer, diameter: 48)
                        }
                    }
                    Text(timerInterval: entry.date...prayer.date, countsDown: true)
                        .font(.title2.monospacedDigit())
                        .lineLimit(1).minimumScaleFactor(0.7)
                } else if family == .systemLarge && entry.data?.showSchedule == false {
                    VStack(spacing: 8) {
                        if entry.data?.showAnalog != false {
                            countdownDial(for: prayer, diameter: 144)
                        }
                        Text(entry.headline?.name ?? prayer.name).font(.title.bold())
                            .foregroundStyle(accent).widgetAccentable()
                        timeLine(for: prayer).font(.title3)
                        Text(timerInterval: entry.date...prayer.date, countsDown: true)
                            .font(.system(.largeTitle, design: .rounded).bold().monospacedDigit())
                    }
                    .lineLimit(1).minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.headline?.name ?? prayer.name)
                                .font(family == .systemLarge ? .title.bold() : .title2.bold())
                                .foregroundStyle(accent).widgetAccentable()
                            timeLine(for: prayer).font(.callout)
                            Text(timerInterval: entry.date...prayer.date, countsDown: true)
                                .font(.title2.monospacedDigit().weight(.semibold))
                        }
                        .lineLimit(1).minimumScaleFactor(0.65)
                        Spacer(minLength: 0)
                        if entry.data?.showAnalog != false {
                            countdownDial(for: prayer, diameter: family == .systemLarge ? 96 : 70)
                        }
                    }
                }
                if family == .systemSmall {
                    Text(entry.shortLocation.components(separatedBy: ",").first ?? "")
                        .font(.caption).lineLimit(1)
                } else if family == .systemLarge && entry.data?.showSchedule != false {
                    // Distribute the schedule across the remaining widget height.
                    VStack(spacing: 0) {
                        ForEach(entry.upcoming, id: \.time) { item in
                            HStack {
                                PrayerIcon(prayer: item, size: 17)
                                    .frame(width: 20)
                                    .accessibilityHidden(true)
                                Text(item.name)
                                Spacer(minLength: 8)
                                Text(item.date, style: .time).monospacedDigit()
                            }
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 10)
                            .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else if entry.data?.showSchedule != false {
                    HStack(spacing: 4) {
                        ForEach(entry.upcoming, id: \.time) { item in
                            VStack(spacing: 2) {
                                HStack(spacing: 2) {
                                    PrayerIcon(prayer: item, size: 11)
                                        .accessibilityHidden(true)
                                    Text(item.name)
                                }.font(.caption2)
                                Text(item.date, style: .time).font(.caption2.monospacedDigit())
                            }
                            .lineLimit(1).minimumScaleFactor(0.65)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.primary)
                        }
                    }
                }
            } else if let data = entry.data {
                Text(data.refresh).font(.callout).minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity,
               alignment: family == .systemLarge ? .topLeading : .leading)
        .foregroundStyle(renderingMode == .fullColor
            ? color(dark ? entry.data?.darkText : entry.data?.lightText) : .primary)
        .containerBackground(for: .widget) {
            if let data = entry.data {
                color(dark ? data.darkBackground : data.lightBackground)
            } else {
                Color(uiColor: .systemBackground)
            }
        }
        .environment(\.locale, Locale(identifier: entry.data?.locale ?? "id"))
        .environment(\.layoutDirection, entry.data?.locale == "ar" ? .rightToLeft : .leftToRight)
    }

    /// The next prayer's time, named when the headline is the current prayer.
    private func timeLine(for prayer: Prayer) -> Text {
        entry.showsCurrent
            ? Text("\(prayer.name) · \(Text(prayer.date, style: .time))")
            : Text(prayer.date, style: .time)
    }

    private func countdownDial(for prayer: Prayer, diameter: CGFloat = 70) -> some View {
        let end = prayer.date
        return ZStack {
            // WidgetKit advances the native timer without timeline polling.
            ProgressView(timerInterval: min(entry.countdownStart, entry.date)...end,
                         countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                PrayerIcon(prayer: prayer, size: 20).foregroundStyle(accent)
            }
            .progressViewStyle(.circular).tint(accent).widgetAccentable()
            // Draw ticks in place so WidgetKit's archived view contains no
            // rotation transforms alongside the live circular progress view.
            Path { path in
                let radius = diameter / 2 - 4
                let center = diameter / 2
                for tick in 0..<12 {
                    let angle = Double(tick) * .pi / 6 - .pi / 2
                    let halfLength: CGFloat = tick % 3 == 0 ? 2.5 : 1.5
                    path.move(to: CGPoint(
                        x: center + (radius - halfLength) * cos(angle),
                        y: center + (radius - halfLength) * sin(angle)))
                    path.addLine(to: CGPoint(
                        x: center + (radius + halfLength) * cos(angle),
                        y: center + (radius + halfLength) * sin(angle)))
                }
            }
            .stroke(accent.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: diameter, height: diameter)
        .accessibilityLabel(Text(timerInterval: entry.date...end, countsDown: true))
    }
}

// Lock screen accessories render in the system's vibrant or accented style,
// so they use `.primary` and rely on `widgetAccentable()` for emphasis.
struct LockScreenPrayerView: View {
    let entry: PrayerEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let prayer = entry.prayer {
                switch family {
                case .accessoryCircular:
                    ZStack {
                        countdownRing(for: prayer)
                        VStack(spacing: 0) {
                            PrayerIcon(prayer: prayer, size: 12)
                                .widgetAccentable()
                            Text(prayer.date, style: .time)
                                .font(.caption2.monospacedDigit())
                                .lineLimit(1).minimumScaleFactor(0.6)
                        }
                        // Keep the time inside the ring's stroke.
                        .padding(8)
                    }
                case .accessoryInline:
                    Label {
                        Text("\(prayer.name) \(Text(prayer.date, style: .time))")
                    } icon: {
                        PrayerIcon(prayer: prayer, size: 12)
                    }
                default:
                    HStack(spacing: 8) {
                        if entry.data?.showAnalog != false {
                            ZStack {
                                countdownRing(for: prayer)
                                PrayerIcon(prayer: prayer, size: 17)
                                    .widgetAccentable()
                            }
                            .frame(width: 44, height: 44)
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            // Unlike a bare countdown, the first line also names the time.
                            if let current = entry.current, entry.showsCurrent {
                                Text(current.name).font(.headline).widgetAccentable()
                            } else {
                                Text("\(prayer.name) · \(Text(prayer.date, style: .time))")
                                    .font(.headline).widgetAccentable()
                            }
                            // Timer text doesn't shrink to fit, so it uses a size that fits
                            // a multi-hour countdown. It claims the full width; pin it leading.
                            Text(timerInterval: entry.date...prayer.date, countsDown: true)
                                .font(.body.weight(.semibold).monospacedDigit())
                                .multilineTextAlignment(.leading)
                            Group {
                                if entry.showsCurrent {
                                    Text("\(prayer.name) · \(Text(prayer.date, style: .time))")
                                } else {
                                    Text(entry.shortLocation)
                                }
                            }
                            .font(.caption).foregroundStyle(.secondary)
                        }
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                Text(entry.data?.refresh ?? "Bedug").font(.caption)
                    .minimumScaleFactor(0.7)
            }
        }
        .containerBackground(for: .widget) {
            if family == .accessoryCircular { AccessoryWidgetBackground() } else { Color.clear }
        }
        .lockScreenEnvironment(entry.data)
    }

    private func countdownRing(for prayer: Prayer) -> some View {
        ProgressView(timerInterval: min(entry.countdownStart, entry.date)...prayer.date,
                     countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.circular).widgetAccentable()
        .accessibilityLabel(Text(timerInterval: entry.date...prayer.date, countsDown: true))
    }
}

// The day as a grid read down the columns: each prayer's name beside its time,
// and in the last cell a countdown whose bar fills while the next one nears.
struct LockScreenScheduleView: View {
    let entry: PrayerEntry

    // Three rows fit the accessory's height at caption size; five prayers fill
    // two columns with one cell left for the countdown.
    private let rows = 3

    var body: some View {
        Group {
            if let next = entry.prayer {
                let day = entry.day
                Grid(horizontalSpacing: 4, verticalSpacing: 0) {
                    ForEach(0..<rows, id: \.self) { row in
                        GridRow {
                            if row < day.count { cell(for: day[row], next: next) }
                            if row + rows < day.count {
                                cell(for: day[row + rows], next: next)
                            } else if row == rows - 1 {
                                countdown(to: next)
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
            } else {
                Text(entry.data?.refresh ?? "Bedug").font(.caption)
                    .minimumScaleFactor(0.7)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .lockScreenEnvironment(entry.data)
    }

    private func cell(for item: Prayer, next: Prayer) -> some View {
        let isNext = item.date == next.date
        let passed = item.date <= entry.date
        return HStack(spacing: 2) {
            Text(abbreviation(of: item.name))
            Spacer(minLength: 0)
            // A formatted time, unlike a `.time` style, sizes to its text instead
            // of reserving room, so the name and time fit a half-width cell.
            Text(item.date, format: .dateTime.hour(.defaultDigits(amPM: .narrow)).minute())
                .monospacedDigit()
        }
        .font(.caption.weight(isNext ? .bold : .medium))
        .lineLimit(1).minimumScaleFactor(0.7)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if isNext {
                AccessoryWidgetBackground()
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .widgetAccentable(isNext)
        .opacity(passed ? 0.45 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(item.name) \(Text(item.date, style: .time))"))
    }

    /// Two letters, so every cell fits at one font size; Arabic names drop
    /// their article first (الفجر reads فج).
    private func abbreviation(of name: String) -> String {
        let stem = name.hasPrefix("ال") ? name.dropFirst(2) : Substring(name)
        return String(stem.prefix(2))
    }

    private func countdown(to next: Prayer) -> some View {
        VStack(spacing: 2) {
            Text(timerInterval: entry.date...next.date, countsDown: true)
                .font(.caption.weight(.semibold).monospacedDigit())
                .multilineTextAlignment(.trailing)
                .lineLimit(1).minimumScaleFactor(0.8)
            ProgressView(timerInterval: min(entry.countdownStart, entry.date)...next.date,
                         countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            // A hairline, so it reads as a track under the countdown.
            .frame(height: 2)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetAccentable()
    }
}

// The day as a strip: each prayer's sky over its time, with the countdown
// beneath. The next prayer sits in a pill whose hairline fills while it nears;
// passed prayers fade.
struct LockScreenSkyStripView: View {
    let entry: PrayerEntry

    var body: some View {
        Group {
            if let next = entry.prayer {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(Array(entry.day.enumerated()), id: \.offset) { _, item in
                            column(for: item, next: next)
                        }
                    }
                    // A column is too narrow for a multi-hour countdown, so it spans
                    // the strip. Timer text claims the full width; center it.
                    Text(timerInterval: entry.date...next.date, countsDown: true)
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .widgetAccentable()
                }
            } else {
                Text(entry.data?.refresh ?? "Bedug").font(.caption)
                    .minimumScaleFactor(0.7)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
        .lockScreenEnvironment(entry.data)
    }

    private func column(for item: Prayer, next: Prayer) -> some View {
        let isNext = item.date == next.date
        let passed = item.date <= entry.date
        return VStack(spacing: 3) {
            PrayerIcon(prayer: item, size: 15)
                .symbolRenderingMode(.hierarchical)
                // The symbols differ in height; a shared box keeps the times level.
                .frame(height: 18)
            // One weight for every time, so the next one doesn't widen and clip.
            Text(item.date, style: .time)
                .font(.caption2.weight(.semibold).monospacedDigit())
                .lineLimit(1).minimumScaleFactor(0.7)
            Group {
                if isNext {
                    ProgressView(timerInterval: min(entry.countdownStart, entry.date)...item.date,
                                 countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.linear)
                } else {
                    Color.clear
                }
            }
            // A hairline inside the pill; the other columns keep the space so all align.
            .frame(height: 2)
            .padding(.horizontal, 5)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            if isNext {
                AccessoryWidgetBackground()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .widgetAccentable(isNext)
        .opacity(passed ? 0.4 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(item.name) \(Text(item.date, style: .time))"))
    }
}

private extension View {
    func lockScreenEnvironment(_ data: PrayerWidgetData?) -> some View {
        environment(\.locale, Locale(identifier: data?.locale ?? "id"))
            .environment(\.layoutDirection, data?.locale == "ar" ? .rightToLeft : .leftToRight)
    }
}

/// Gallery text in the app's language. WidgetKit would otherwise resolve these
/// strings in the device's language, which can differ from the one in Bedug.
enum AppLanguage {
    static func string(_ key: String) -> String {
        let code = PrayerWidgetData.load()?.locale ?? "id"
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}

struct BedugPrayerWidget: Widget {
    let kind = "BedugPrayerWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PrayerWidgetIntent.self,
                               provider: ConfigurablePrayerProvider()) { entry in
            PrayerWidgetFamilyView(entry: entry)
        }
        .configurationDisplayName(AppLanguage.string("Next prayer"))
        .description(AppLanguage.string("Counts down to the next prayer, with its time and your city."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct PrayerWidgetFamilyView: View {
    let entry: PrayerEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            LockScreenPrayerView(entry: entry)
        default:
            PrayerWidgetView(entry: entry)
        }
    }
}

struct BedugScheduleWidget: Widget {
    let kind = "BedugScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            LockScreenScheduleView(entry: entry)
        }
        .configurationDisplayName(AppLanguage.string("Today's prayers"))
        .description(AppLanguage.string("The whole day at a glance. The next prayer's bar fills as it nears."))
        .supportedFamilies([.accessoryRectangular])
    }
}

struct BedugSkyStripWidget: Widget {
    let kind = "BedugSkyStripWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            LockScreenSkyStripView(entry: entry)
        }
        .configurationDisplayName(AppLanguage.string("Prayer sky"))
        .description(AppLanguage.string("Today's prayers as the sky at each time. The next prayer's bar fills as it nears."))
        .supportedFamilies([.accessoryRectangular])
    }
}

@main
struct BedugWidgets: WidgetBundle {
    var body: some Widget {
        BedugPrayerWidget()
        BedugScheduleWidget()
        BedugSkyStripWidget()
    }
}
