import SwiftUI

struct HistoryPage: View {
    @EnvironmentObject var store: JournalStore
    let openDay: (Date) -> Void
    #if DEBUG && targetEnvironment(simulator)
    @State private var weekOffset = ScreenshotLaunch.screen == .weeklyTrends ? -1 : 0
    #else
    @State private var weekOffset = 0
    #endif
    private let english = Locale(identifier: "en_US")

    private var days: [Date] {
        let cal = Calendar(identifier: .iso8601)
        let monday = cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? Date()
        return (0..<7).compactMap { cal.date(byAdding: .day, value: weekOffset * 7 + $0, to: monday) }
    }
    var body: some View {
        let groups = days.map { store.journal.day($0) }
        let maximum = max(groups.compactMap { $0.value(\.kcal) }.max() ?? 0, 1)
        let logged = groups.filter { !$0.entries.isEmpty }
        let records = groups.flatMap(\.entries)
        DarkPage {
            BrandHeading()
            PageHeading(title: "Trends", subtitle: "See the rhythm of your week.")
            HStack {
                Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left").frame(width: 42, height: 42) }
                    .accessibilityLabel("Previous week")
                Spacer()
                if let first = days.first, let last = days.last {
                    Text(first.formatted(.dateTime.locale(english).day().month(.abbreviated)) + " – " +
                         last.formatted(.dateTime.locale(english).day().month(.abbreviated).year()))
                        .font(.headline)
                }
                Spacer()
                Button { weekOffset += 1 } label: { Image(systemName: "chevron.right").frame(width: 42, height: 42) }
                    .accessibilityLabel("Next week").disabled(weekOffset == 0)
            }
            HStack(spacing: 12) {
                weekMetric("Days logged", value: "\(logged.count) / 7", icon: "calendar", color: Ink.blue)
                weekMetric("Portions", value: "\(records.count)", icon: "fork.knife", color: Ink.green)
            }
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Energy this week").font(.headline)
                    Spacer()
                    Text("kcal").font(.caption).foregroundStyle(Ink.muted)
                }
                HStack(alignment: .bottom, spacing: 7) {
                    ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                        let kcal = groups[index].value(\.kcal)
                        Button { openDay(date) } label: {
                            VStack(spacing: 8) {
                                Spacer(minLength: 0)
                                if !groups[index].entries.isEmpty {
                                    Text(number(kcal)).font(.system(size: 10, weight: .semibold, design: .default))
                                        .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
                                }
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(groups[index].entries.isEmpty ? Ink.border : (Calendar.current.isDateInToday(date) ? Ink.green : Ink.blue))
                                    .frame(height: max(4, 100 * (kcal ?? 0) / maximum))
                                Text(date.formatted(.dateTime.locale(english).weekday(.narrow)))
                                    .font(.caption).foregroundStyle(Ink.muted)
                            }
                        }.accessibilityLabel(date.formatted(.dateTime.locale(english).day().month()) + ", " + number(kcal) + " kcal")
                            .disabled(date > Date()).frame(maxWidth: .infinity)
                    }
                }.frame(height: 150)
                Divider()
                Text("Tap a day to explore its meals.")
                    .font(.footnote).foregroundStyle(Ink.muted)
            }.padding(20).rhythmPanel(radius: 22)
            SectionHeading(title: "Daily log", mark: "Journal")
            ForEach(days.reversed(), id: \.self) { date in
                if date <= .now {
                    let summary = store.journal.day(date)
                    Button { openDay(date) } label: {
                        HStack(spacing: 12) {
                            Text(date.formatted(.dateTime.locale(english).day())).font(.title2.bold().monospacedDigit())
                                .foregroundStyle(Ink.blue).frame(width: 43, height: 46).background(Ink.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(date.formatted(.dateTime.locale(english).weekday(.wide)).capitalized(with: english)).font(.headline)
                                Text(summary.entries.isEmpty ? "No entries" : "Portions: \(summary.entries.count)")
                                    .foregroundStyle(Ink.muted).font(.caption)
                            }
                            Spacer()
                            Text(summary.entries.isEmpty ? "" : number(summary.value(\.kcal)) + " kcal")
                                .font(.subheadline.monospacedDigit())
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Ink.muted)
                        }.padding(14).rhythmPanel(radius: 18).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func weekMetric(_ title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            FoodSymbol(icon: icon, color: color, size: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(value).font(.title3.bold().monospacedDigit())
                Text(title).font(.caption).foregroundStyle(Ink.muted)
            }
            Spacer(minLength: 0)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16).rhythmPanel(radius: 18)
    }

}

struct GoalPage: View {
    @EnvironmentObject var store: JournalStore
    @State private var goal = ""
    @State private var saved = false
    @FocusState private var editingGoal: Bool
    var body: some View {
        DarkPage {
            BrandHeading()
            PageHeading(title: "Your rhythm", subtitle: "A journal that works your way.")
            VStack(alignment: .leading, spacing: 14) {
                FoodSymbol(icon: "scope", color: Ink.blue, size: 52)
                Text("Personal target").font(.title2.bold())
                Text("Set a daily calorie target, or leave it blank to track totals only.")
                    .font(.subheadline).foregroundStyle(Ink.muted)
                HStack {
                    TextField("No target", text: $goal).keyboardType(.numberPad).focused($editingGoal)
                        .accessibilityLabel("Personal calorie target")
                    Text("kcal").foregroundStyle(Ink.muted)
                }.font(.title2.bold()).padding(13).background(Ink.ground, in: RoundedRectangle(cornerRadius: 12))
                Button {
                    guard valid else { return }
                    saved = store.change { $0.target = Double(goal) }
                    if saved { editingGoal = false }
                } label: { ActionLabel(title: saved ? "Saved" : "Save target", icon: "checkmark") }
                    .buttonStyle(.plain).disabled(!valid).opacity(valid ? 1 : 0.45)
                if !valid { Text("Enter a whole number from 1 to 20,000.").font(.caption).foregroundStyle(Ink.error) }
            }.padding(20).rhythmPanel(radius: 22)
            SectionHeading(title: "Made for your day", mark: "Your journal")
            HStack(alignment: .top, spacing: 13) {
                FoodSymbol(icon: "rectangle.grid.2x2", color: Ink.green)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your day, at a glance").font(.headline)
                    Text("Your journal stays on this device. Add a Home Screen widget to see today’s calories and portions.")
                        .font(.subheadline).foregroundStyle(Ink.muted)
                }
            }.padding(18).rhythmPanel()
            Link(destination: URL(string: "https://world.openfoodfacts.org/")!) {
                Label("Open Food Facts catalog", systemImage: "arrow.up.right.square")
            }
            Text("Nutrient totals scale with portion weight. A dash means the label has no value for that nutrient.")
                .font(.footnote).foregroundStyle(Ink.muted)
        }
        .onAppear { goal = store.journal.target.map { String(Int($0)) } ?? ""; saved = false }
        .onChange(of: goal) { _, _ in saved = false }
        .onDisappear { editingGoal = false }
    }
    private var valid: Bool { goal.isEmpty || Int(goal).map { (1...20_000).contains($0) } == true }
}
