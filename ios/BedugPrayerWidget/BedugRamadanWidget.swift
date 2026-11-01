import SwiftUI
import WidgetKit

/// One fast of the week Flutter shares under `prayer_widget`'s `ramadan`.
struct RamadanFast: Decodable {
    let title: String
    /// Maghrib the evening before, when sahur's countdown begins.
    let since: Double
    let imsak: Double
    let fajr: Double
    let iftar: Double

    var sinceDate: Date { Date(timeIntervalSince1970: since / 1000) }
    var imsakDate: Date { Date(timeIntervalSince1970: imsak / 1000) }
    var fajrDate: Date { Date(timeIntervalSince1970: fajr / 1000) }
    var iftarDate: Date { Date(timeIntervalSince1970: iftar / 1000) }
}

struct RamadanWidgetData: Decodable {
    let fasts: [RamadanFast]
    /// The end of the week the fasts cover.
    let until: Double?
    let title: String
    let untilImsak: String
    let untilIftar: String
    let imsak: String
    let fajr: String
    let maghrib: String
    /// When the next Ramadan begins, with `{date}` for [nextStart].
    let next: String?
    let nextStart: Double?
}

/// What the widget counts down to at its entry's date.
struct RamadanPhase {
    let fast: RamadanFast
    let isSahur: Bool

    var start: Date { isSahur ? fast.sinceDate : fast.imsakDate }
    var target: Date { isSahur ? fast.imsakDate : fast.iftarDate }
    var symbol: String { isSahur ? "moon.stars" : "sunset" }
}

struct RamadanEntry: TimelineEntry {
    let date: Date
    let data: PrayerWidgetData?

    var ramadan: RamadanWidgetData? { data?.ramadan }

    var phase: RamadanPhase? {
        for fast in ramadan?.fasts ?? [] {
            if fast.sinceDate <= date && date < fast.imsakDate {
                return RamadanPhase(fast: fast, isSahur: true)
            }
            if fast.imsakDate <= date && date < fast.iftarDate {
                return RamadanPhase(fast: fast, isSahur: false)
            }
        }
        return nil
    }

    /// True once the shared week has run out, so only the app can say more.
    var expired: Bool {
        guard let until = ramadan?.until else { return ramadan == nil }
        return date >= Date(timeIntervalSince1970: until / 1000)
    }

    /// When the next Ramadan begins, its date in the app's language.
    var nextText: String? {
        guard let next = ramadan?.next, let start = ramadan?.nextStart else { return nil }
        let date = Date(timeIntervalSince1970: start / 1000)
        let style = Date.FormatStyle(date: .long, time: .omitted)
            .locale(Locale(identifier: data?.locale ?? "id"))
        return next.replacingOccurrences(of: "{date}", with: date.formatted(style))
    }

    /// The phase's label and its time: "Until iftar · 17:58".
    func detail(_ phase: RamadanPhase) -> Text {
        let ramadan = ramadan
        return phase.isSahur
            ? Text("\(ramadan?.imsak ?? "") \(Text(phase.target, style: .time)) · \(ramadan?.fajr ?? "") \(Text(phase.fast.fajrDate, style: .time))")
            : Text("\(ramadan?.maghrib ?? "") \(Text(phase.target, style: .time))")
    }

    func label(_ phase: RamadanPhase) -> String {
        (phase.isSahur ? ramadan?.untilImsak : ramadan?.untilIftar) ?? ""
    }
}

struct RamadanProvider: TimelineProvider {
    func placeholder(in context: Context) -> RamadanEntry {
        RamadanEntry(date: .now, data: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (RamadanEntry) -> Void) {
        completion(RamadanEntry(date: .now, data: PrayerWidgetData.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RamadanEntry>) -> Void) {
        let now = Date.now
        let data = PrayerWidgetData.load()
        var entries = [RamadanEntry(date: now, data: data)]
        // Each fast switches at sahur's start, imsak and iftar; the week's end
        // asks for the app to be opened.
        var boundaries = (data?.ramadan?.fasts ?? []).flatMap {
            [$0.sinceDate, $0.imsakDate, $0.iftarDate]
        }
        if let until = data?.ramadan?.until {
            boundaries.append(Date(timeIntervalSince1970: until / 1000))
        }
        for date in Set(boundaries).sorted() where date > now {
            entries.append(RamadanEntry(date: date, data: data))
        }
        completion(Timeline(entries: entries, policy: .never))
    }
}

struct RamadanWidgetView: View {
    let entry: RamadanEntry
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
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.phase?.fast.title ?? entry.ramadan?.title ?? "Bedug")
                .font(.caption).lineLimit(1)
            if let phase = entry.phase {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.label(phase))
                            .font(family == .systemSmall ? .headline : .title3.bold())
                            .foregroundStyle(accent).widgetAccentable()
                        Text(timerInterval: entry.date...phase.target, countsDown: true)
                            .font((family == .systemSmall ? Font.title2 : .title).monospacedDigit().weight(.semibold))
                        entry.detail(phase).font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if family != .systemSmall {
                        ProgressView(timerInterval: min(phase.start, entry.date)...phase.target,
                                     countsDown: true) {
                            EmptyView()
                        } currentValueLabel: {
                            Image(systemName: phase.symbol).foregroundStyle(accent)
                        }
                        .progressViewStyle(.circular).tint(accent).widgetAccentable()
                        .frame(width: 70, height: 70)
                        .accessibilityHidden(true)
                    }
                }
                if family == .systemSmall {
                    ProgressView(timerInterval: min(phase.start, entry.date)...phase.target,
                                 countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.linear).tint(accent).widgetAccentable()
                }
            } else {
                Spacer(minLength: 0)
                Image(systemName: "moon.stars").font(.title2)
                    .foregroundStyle(accent).widgetAccentable()
                Text(entry.expired ? entry.data?.refresh ?? "" : entry.nextText ?? "")
                    .font(.callout).minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(renderingMode == .fullColor
            ? color(dark ? entry.data?.darkText : entry.data?.lightText) : .primary)
        .containerBackground(for: .widget) {
            if let data = entry.data {
                color(dark ? data.darkBackground : data.lightBackground)
            } else {
                Color(uiColor: .systemBackground)
            }
        }
        .ramadanEnvironment(entry.data)
    }
}

// Lock screen accessories render in the system's vibrant or accented style,
// so they use `.primary` and rely on `widgetAccentable()` for emphasis.
struct LockScreenRamadanView: View {
    let entry: RamadanEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let phase = entry.phase {
                switch family {
                case .accessoryCircular:
                    ZStack {
                        ring(phase)
                        VStack(spacing: 0) {
                            Image(systemName: phase.symbol).font(.caption)
                                .widgetAccentable()
                            Text(phase.target, style: .time)
                                .font(.caption2.monospacedDigit())
                                .lineLimit(1).minimumScaleFactor(0.6)
                        }
                        // Keep the time inside the ring's stroke.
                        .padding(8)
                    }
                case .accessoryInline:
                    Label {
                        Text("\(entry.label(phase)) \(Text(phase.target, style: .time))")
                    } icon: {
                        Image(systemName: phase.symbol)
                    }
                default:
                    HStack(spacing: 8) {
                        ZStack {
                            ring(phase)
                            Image(systemName: phase.symbol).font(.body)
                                .widgetAccentable()
                        }
                        .frame(width: 44, height: 44)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(entry.label(phase)) · \(Text(phase.target, style: .time))")
                                .font(.headline).widgetAccentable()
                            // Timer text doesn't shrink to fit, so it uses a size that fits
                            // a multi-hour countdown. It claims the full width; pin it leading.
                            Text(timerInterval: entry.date...phase.target, countsDown: true)
                                .font(.body.weight(.semibold).monospacedDigit())
                                .multilineTextAlignment(.leading)
                            Text(phase.fast.title)
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                switch family {
                case .accessoryCircular:
                    ZStack {
                        AccessoryWidgetBackground()
                        Image(systemName: "moon.stars").font(.title3)
                    }
                case .accessoryInline:
                    Label(entry.ramadan?.title ?? "Bedug", systemImage: "moon.stars")
                default:
                    Text(entry.expired ? entry.data?.refresh ?? "Bedug" : entry.nextText ?? "")
                        .font(.caption).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .containerBackground(for: .widget) {
            if family == .accessoryCircular { AccessoryWidgetBackground() } else { Color.clear }
        }
        .ramadanEnvironment(entry.data)
    }

    private func ring(_ phase: RamadanPhase) -> some View {
        ProgressView(timerInterval: min(phase.start, entry.date)...phase.target,
                     countsDown: true) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.circular).widgetAccentable()
        .accessibilityLabel(Text(timerInterval: entry.date...phase.target, countsDown: true))
    }
}

private extension View {
    func ramadanEnvironment(_ data: PrayerWidgetData?) -> some View {
        environment(\.locale, Locale(identifier: data?.locale ?? "id"))
            .environment(\.layoutDirection, data?.locale == "ar" ? .rightToLeft : .leftToRight)
    }
}

struct RamadanWidgetFamilyView: View {
    let entry: RamadanEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            LockScreenRamadanView(entry: entry)
        default:
            RamadanWidgetView(entry: entry)
        }
    }
}

struct BedugRamadanWidget: Widget {
    let kind = "BedugRamadanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RamadanProvider()) { entry in
            RamadanWidgetFamilyView(entry: entry)
        }
        .configurationDisplayName(AppLanguage.string("Ramadan"))
        .description(AppLanguage.string("Counts down to imsak while you eat sahur and to iftar while you fast."))
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
