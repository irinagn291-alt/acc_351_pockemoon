import SwiftUI
import WidgetKit

struct RhythmEntry: TimelineEntry {
    var date: Date
    var summary: DaySummary
    var goal: Double?
}

struct RhythmProvider: TimelineProvider {
    func placeholder(in context: Context) -> RhythmEntry {
        .init(date: .now, summary: DaySummary(entries: []), goal: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping (RhythmEntry) -> Void) {
        let state = (try? JournalFiles.load()) ?? Journal()
        completion(.init(date: .now, summary: state.day(.now), goal: state.target))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<RhythmEntry>) -> Void) {
        let state = (try? JournalFiles.load()) ?? Journal()
        let now = Date()
        let midnight = Calendar.current.dateInterval(of: .day, for: now)?.end ?? now.addingTimeInterval(3600)
        let entries = [now, midnight].map { RhythmEntry(date: $0, summary: state.day($0), goal: state.target) }
        completion(Timeline(entries: entries, policy: .after(midnight.addingTimeInterval(120))))
    }
}

struct RhythmWidgetFace: View {
    @Environment(\.widgetFamily) var family
    var entry: RhythmEntry
    let blue = Color(red: 0.302, green: 0.616, blue: 1)
    let green = Color(red: 0.208, green: 0.855, blue: 0.612)
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Label("DAILY RHYTHM", systemImage: "leaf.fill").font(.caption2.bold()).foregroundStyle(blue)
                Spacer(minLength: 1)
                Text(number(entry.summary.value(\.kcal))).font(.system(size: 37, weight: .bold))
                    .lineLimit(1).minimumScaleFactor(0.5)
                Text(entry.summary.incomplete ? "kcal · partial total" : "kcal today").font(.caption).foregroundStyle(.secondary)
                if let goal = entry.goal {
                    ProgressView(value: min((entry.summary.value(\.kcal) ?? 0) / goal, 1)).tint(green)
                }
                Spacer(minLength: 1)
                Text("Portions: \(entry.summary.entries.count)").font(.caption2.bold())
            }.frame(maxWidth: .infinity, alignment: .leading)
            if family == .systemMedium {
                Divider().overlay(.white.opacity(0.2))
                VStack(alignment: .leading, spacing: 8) {
                    Text("MACROS").font(.caption2.monospaced()).foregroundStyle(blue)
                    value("Protein", entry.summary.value(\.protein))
                    value("Fat", entry.summary.value(\.fat))
                    value("Carbs", entry.summary.value(\.carbs))
                }.frame(maxWidth: .infinity)
            }
        }.foregroundStyle(.white)
            .containerBackground(for: .widget) { Color(red: 0.043, green: 0.071, blue: 0.125) }
    }
    private func value(_ label: String, _ grams: Double?) -> some View {
        HStack {
            Text(label); Spacer(); Text(number(grams, precision: 1) + " g").bold()
        }.font(.caption2)
    }
}

@main
struct RhythmWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RationRhythm.Day", provider: RhythmProvider()) { RhythmWidgetFace(entry: $0) }
            .configurationDisplayName("PockeMoon")
            .description("Calories and macros from today’s journal entries.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
