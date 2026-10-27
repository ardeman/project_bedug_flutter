import SwiftUI
import WidgetKit

/// One day's ayah, as shared by `buildDailyAyahWidgetData` in Flutter.
struct AyahDay: Decodable {
    let date: String
    let link: String
    let arabic: String
    /// Empty for Arabic, whose readers read the text itself.
    let translation: String
    let reference: String
    let why: String
}

struct AyahWidgetData: Decodable {
    let days: [AyahDay]
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

    static func load() -> AyahWidgetData? {
        guard let text = UserDefaults(suiteName: "group.com.ardeman.bedug")?
            .string(forKey: "ayah_widget"), let bytes = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: bytes)
    }

    /// The `yyyy-MM-dd` key Flutter writes for [date]'s local day.
    static func key(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

struct AyahEntry: TimelineEntry {
    let date: Date
    let data: AyahWidgetData?

    var day: AyahDay? {
        let key = AyahWidgetData.key(for: date)
        return data?.days.first { $0.date == key }
    }
}

struct AyahProvider: TimelineProvider {
    func placeholder(in context: Context) -> AyahEntry {
        AyahEntry(date: Date(), data: AyahWidgetData.load())
    }

    func getSnapshot(in context: Context, completion: @escaping (AyahEntry) -> Void) {
        completion(placeholder(in: context))
    }

    /// One entry now and one at each midnight the shared days cover; after
    /// the last, the widget asks to open Bedug.
    func getTimeline(in context: Context, completion: @escaping (Timeline<AyahEntry>) -> Void) {
        let data = AyahWidgetData.load()
        let calendar = Calendar.current
        var entries = [AyahEntry(date: Date(), data: data)]
        var midnight = calendar.startOfDay(for: Date())
        for _ in 0..<(data?.days.count ?? 0) {
            guard let next = calendar.date(byAdding: .day, value: 1, to: midnight) else { break }
            midnight = next
            entries.append(AyahEntry(date: midnight, data: data))
        }
        completion(Timeline(entries: entries, policy: .never))
    }
}

struct AyahWidgetView: View {
    let entry: AyahEntry
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

    private var arabicReader: Bool { entry.data?.locale == "ar" }

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemLarge ? 10 : 6) {
            HStack {
                Text(entry.data?.title ?? "Bedug")
                if family != .systemSmall, let day = entry.day {
                    Spacer(minLength: 8)
                    Text(day.reference).foregroundStyle(.secondary)
                }
            }
            .font(.caption).lineLimit(1).minimumScaleFactor(0.7)
            if let day = entry.day {
                if family != .systemSmall {
                    Text(day.why).font(.caption2).foregroundStyle(accent).widgetAccentable()
                        .lineLimit(2)
                }
                // Small widgets keep to the meaning; Arabic readers read the text.
                if family != .systemSmall || arabicReader {
                    Text(day.arabic)
                        .font(family == .systemLarge ? .title3 : .body)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                        .lineLimit(family == .systemLarge ? 6 : arabicReader ? 4 : 2)
                }
                if !day.translation.isEmpty {
                    Text(day.translation)
                        .font(family == .systemSmall ? .caption : .footnote)
                        .lineLimit(family == .systemLarge ? 8 : family == .systemSmall ? 5 : 3)
                }
                Spacer(minLength: 0)
                if family == .systemSmall {
                    Text(day.reference).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            } else {
                Spacer(minLength: 0)
                Text(entry.data?.refresh ?? AppLanguage.string("Open Bedug to load the verse of the day."))
                    .font(.footnote).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(renderingMode == .fullColor
                         ? color(dark ? entry.data?.darkText : entry.data?.lightText) : .primary)
        .widgetURL(entry.day.flatMap { URL(string: $0.link) })
        .containerBackground(for: .widget) {
            if let data = entry.data {
                color(dark ? data.darkBackground : data.lightBackground)
            } else {
                Color(uiColor: .systemBackground)
            }
        }
        .environment(\.locale, Locale(identifier: entry.data?.locale ?? "id"))
        .environment(\.layoutDirection, arabicReader ? .rightToLeft : .leftToRight)
    }
}

struct BedugAyahWidget: Widget {
    let kind = "BedugAyahWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AyahProvider()) { entry in
            AyahWidgetView(entry: entry)
        }
        .configurationDisplayName(AppLanguage.string("Verse of the day"))
        .description(AppLanguage.string("A verse from the Quran each day, with why it was picked."))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
