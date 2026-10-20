import SwiftUI
import WidgetKit

struct Prayer: Decodable {
    let name: String
    let time: Double
    var date: Date { Date(timeIntervalSince1970: time / 1000) }
}

struct PrayerWidgetData: Decodable {
    let prayers: [Prayer]
    let intervalStart: Double?
    let showAnalog: Bool?
    let showSchedule: Bool?
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

    var upcoming: [Prayer] {
        Array((data?.prayers ?? []).filter { $0.date > date }.prefix(5))
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
        let now = Date.now
        let data = PrayerWidgetData.load()
        var entries = [entry(at: now, data: data)]
        // At each boundary select the following prayer; the final entry expires
        // the schedule instead of repeating yesterday's times indefinitely.
        for prayer in data?.prayers ?? [] where prayer.date > now {
            entries.append(entry(at: prayer.date, data: data))
        }
        completion(Timeline(entries: entries, policy: .never))
    }

    private func entry(at date: Date, data: PrayerWidgetData?) -> PrayerEntry {
        PrayerEntry(date: date, data: data,
                    prayer: data?.prayers.first(where: { $0.date > date }))
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
                Text(entry.data?.title ?? "Bedug")
                if family != .systemSmall {
                    Spacer(minLength: 8)
                    Text(entry.data?.location ?? "")
                }
            }
            .font(.caption).lineLimit(1).minimumScaleFactor(0.7)
            if let prayer = entry.prayer {
                if family == .systemSmall {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prayer.name).font(.headline)
                                .foregroundStyle(accent).widgetAccentable()
                            Text(prayer.date, style: .time).font(.caption)
                        }
                        .lineLimit(1).minimumScaleFactor(0.65)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if entry.data?.showAnalog != false {
                            countdownDial(until: prayer.date, diameter: 48)
                        }
                    }
                    Text(timerInterval: entry.date...prayer.date, countsDown: true)
                        .font(.title2.monospacedDigit())
                        .lineLimit(1).minimumScaleFactor(0.7)
                } else if family == .systemLarge && entry.data?.showSchedule == false {
                    VStack(spacing: 8) {
                        if entry.data?.showAnalog != false {
                            countdownDial(until: prayer.date, diameter: 144)
                        }
                        Text(prayer.name).font(.title.bold())
                            .foregroundStyle(accent).widgetAccentable()
                        Text(prayer.date, style: .time).font(.title3)
                        Text(timerInterval: entry.date...prayer.date, countsDown: true)
                            .font(.system(.largeTitle, design: .rounded).bold().monospacedDigit())
                    }
                    .lineLimit(1).minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(prayer.name).font(family == .systemLarge ? .title.bold() : .title2.bold())
                                .foregroundStyle(accent).widgetAccentable()
                            Text(prayer.date, style: .time).font(.callout)
                            Text(timerInterval: entry.date...prayer.date, countsDown: true)
                                .font(.title2.monospacedDigit())
                        }
                        .lineLimit(1).minimumScaleFactor(0.65)
                        Spacer(minLength: 0)
                        if entry.data?.showAnalog != false {
                            countdownDial(until: prayer.date, diameter: family == .systemLarge ? 96 : 70)
                        }
                    }
                }
                if family == .systemSmall {
                    Text(entry.data?.location ?? "").font(.caption).lineLimit(1)
                } else if family == .systemLarge && entry.data?.showSchedule != false {
                    // Distribute the schedule across the remaining widget height.
                    VStack(spacing: 0) {
                        ForEach(Array(entry.upcoming.enumerated()), id: \.offset) { index, item in
                            HStack {
                                Text(item.name)
                                Spacer(minLength: 8)
                                Text(item.date, style: .time).monospacedDigit()
                            }
                            .font(.subheadline.weight(index == 0 ? .bold : .regular))
                            .foregroundStyle(index == 0 ? accent : .primary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .padding(.horizontal, 10)
                            .frame(maxHeight: .infinity)
                            .background(accent.opacity(index == 0 ? 0.12 : 0),
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else if entry.data?.showSchedule != false {
                    HStack(spacing: 4) {
                        ForEach(Array(entry.upcoming.enumerated()), id: \.offset) { index, item in
                            VStack(spacing: 2) {
                                Text(item.name).font(.caption2.weight(index == 0 ? .bold : .regular))
                                Text(item.date, style: .time).font(.caption2.monospacedDigit())
                            }
                            .lineLimit(1).minimumScaleFactor(0.65)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(index == 0 ? accent : .primary)
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

    private func countdownDial(until end: Date, diameter: CGFloat = 70) -> some View {
        ZStack {
            // WidgetKit advances the native timer without timeline polling.
            ProgressView(timerInterval: min(entry.countdownStart, entry.date)...end,
                         countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                Image(systemName: "moonphase.waning.crescent")
                    .font(.title3).foregroundStyle(accent)
            }
            .progressViewStyle(.circular).tint(accent).widgetAccentable()
            ForEach(0..<12) { tick in
                Capsule().fill(accent.opacity(0.4))
                    .frame(width: 2, height: tick % 3 == 0 ? 5 : 3)
                    .offset(y: -(diameter / 2 - 4))
                    .rotationEffect(.degrees(Double(tick) * 30))
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityLabel(Text(timerInterval: entry.date...end, countsDown: true))
    }
}

@main
struct BedugPrayerWidget: Widget {
    let kind = "BedugPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Bedug")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
