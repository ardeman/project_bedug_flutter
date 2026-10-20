import SwiftUI
import WidgetKit

struct Prayer: Decodable {
    let name: String
    let time: Double
    var date: Date { Date(timeIntervalSince1970: time / 1000) }
}

struct PrayerWidgetData: Decodable {
    let prayers: [Prayer]
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

    private var dark: Bool {
        entry.data?.themeMode == 2 || (entry.data?.themeMode == 0 && colorScheme == .dark)
    }

    private func color(_ value: UInt32?) -> Color {
        guard let value else { return .primary }
        return Color(.sRGB, red: Double((value >> 16) & 255) / 255,
                     green: Double((value >> 8) & 255) / 255,
                     blue: Double(value & 255) / 255, opacity: 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.data?.title ?? "Bedug")
                .font(.caption).lineLimit(1)
            if let prayer = entry.prayer {
                HStack(alignment: .firstTextBaseline) {
                    Text(prayer.name).font(.title2.bold())
                    Spacer(minLength: 4)
                    Text(prayer.date, style: .time).font(.callout)
                }
                .lineLimit(1).minimumScaleFactor(0.65)
                .foregroundStyle(renderingMode == .fullColor
                    ? color(dark ? entry.data?.darkAccent : entry.data?.lightAccent) : .primary)
                .widgetAccentable()
                Text(timerInterval: entry.date...prayer.date, countsDown: true)
                    .font(.title2.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.7)
                Text(entry.data?.location ?? "").font(.caption).lineLimit(1)
            } else if let data = entry.data {
                Text(data.refresh).font(.callout).minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
}

@main
struct BedugPrayerWidget: Widget {
    let kind = "BedugPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
            PrayerWidgetView(entry: entry)
        }
        .configurationDisplayName("Bedug")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
