import SwiftUI

@main
struct RationRhythmApp: App {
    @StateObject private var store = JournalStore()
    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG && targetEnvironment(simulator)
                if ScreenshotLaunch.screen != nil {
                    JournalHome()
                        .transaction { $0.disablesAnimations = true; $0.animation = nil }
                } else {
                    JournalHome()
                }
                #else
                JournalHome()
                #endif
            }.environmentObject(store).preferredColorScheme(.dark).tint(Ink.blue)
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
enum ScreenshotLaunch {
    enum Screen: String, CaseIterable {
        case dailyJournal = "daily-journal", foodCatalog = "food-catalog"
        case barcodeScanner = "barcode-scanner", portionEditor = "portion-editor"
        case weeklyTrends = "weekly-trends"
    }

    static let screen: Screen? = {
        let process = ProcessInfo.processInfo
        let args = process.arguments
        func value(after flag: String) -> String? {
            guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return nil }
            return args[index + 1]
        }
        if args.contains("-ReviewScreen") {
            return value(after: "-ReviewScreen").flatMap(Screen.init(rawValue:))
        }
        let envFlag = process.environment["APPSTORE_SCREENSHOTS"]
        guard args.contains("-AppStoreScreenshots") ||
                (envFlag != nil && envFlag != "0" && envFlag?.lowercased() != "false" && envFlag != "") else { return nil }
        let rawIndex = value(after: "-AppStoreScreenshotScreen") ?? process.environment["APPSTORE_SCREENSHOT_SCREEN"] ?? "0"
        guard let index = Int(rawIndex), Screen.allCases.indices.contains(index) else { return nil }
        return Screen.allCases[index]
    }()

    static func portion(_ product: FoodProduct, grams: Double, meal: Meal, date: Date) -> Portion {
        Portion(code: product.id, name: product.name, brand: product.brand,
                per100: .init(kcal: product.kcal, protein: product.protein, carbs: product.carbs,
                              fat: product.fat, fiber: product.fiber),
                grams: grams, meal: meal, date: date)
    }

    static var oats: FoodProduct { FoodCatalog.bundled.first { $0.id == "3168930003632" }! }
    static var nutella: FoodProduct { FoodCatalog.bundled.first { $0.id == "3017620422003" }! }

    static func journal(for screen: Screen) -> Journal {
        var journal = Journal()
        if screen == .dailyJournal {
            journal.target = 2_100
            journal.entries = [portion(oats, grams: 150, meal: .breakfast, date: .now),
                               portion(nutella, grams: 100, meal: .lunch, date: .now)]
        } else if screen == .weeklyTrends {
            let calendar = Calendar(identifier: .iso8601)
            let monday = calendar.dateInterval(of: .weekOfYear, for: .now)!.start
            journal.entries = (0..<5).map { day in
                let date = calendar.date(byAdding: .day, value: day - 7, to: monday)!
                return portion(day.isMultiple(of: 2) ? oats : nutella,
                               grams: [150.0, 100, 250, 150, 100][day],
                               meal: day.isMultiple(of: 2) ? .breakfast : .lunch, date: date)
            }
        }
        return journal
    }
}

#endif

enum JournalTab { case day, history, settings }

struct JournalHome: View {
    @EnvironmentObject var store: JournalStore
    @Environment(\.scenePhase) var phase
    @State private var tab = JournalTab.day
    @State private var day = Date()
    @State private var picking = false
    @State private var draft: Portion?
    @State private var nextPortion: Portion?
    @State private var showingDate = false

    #if DEBUG && targetEnvironment(simulator)
    init() {
        let screen = ScreenshotLaunch.screen
        _tab = State(initialValue: screen == .weeklyTrends ? .history : .day)
        _picking = State(initialValue: screen == .foodCatalog || screen == .barcodeScanner)
        if screen == .portionEditor {
            _draft = State(initialValue: ScreenshotLaunch.portion(ScreenshotLaunch.oats, grams: 150,
                                                                  meal: .breakfast, date: .now))
        }
    }
    #endif

    var body: some View {
        TabView(selection: $tab) {
            dashboard.tabItem { Label("Journal", systemImage: "fork.knife.circle") }.tag(JournalTab.day)
            HistoryPage { selected in day = selected; tab = .day }.tabItem {
                Label("Trends", systemImage: "chart.bar.xaxis")
            }.tag(JournalTab.history)
            GoalPage().tabItem { Label("Profile", systemImage: "person.crop.circle") }.tag(JournalTab.settings)
        }
        .toolbarBackground(Ink.ground, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(isPresented: $picking, onDismiss: {
            if let nextPortion { draft = nextPortion; self.nextPortion = nil }
        }) {
            FoodCatalogPicker { product in
                nextPortion = Portion(code: product.id, name: product.name, brand: product.brand,
                                      per100: .init(kcal: product.kcal, protein: product.protein, carbs: product.carbs,
                                                    fat: product.fat, fiber: product.fiber),
                                      grams: 100, meal: .current, date: timeOnSelectedDay())
            }
        }
        .sheet(item: $draft) { portion in
            PortionEditor(portion: portion, existing: store.journal.entries.contains { $0.id == portion.id })
        }
        .sheet(isPresented: $showingDate) {
            VStack {
                DatePicker("Journal date", selection: $day, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical).environment(\.locale, Locale(identifier: "en_US"))
                Button("Done") { showingDate = false }.buttonStyle(.borderedProminent)
            }.padding().presentationDetents([.medium, .large]).presentationBackground(Ink.panel)
        }
        .alert("Journal", isPresented: Binding(get: { store.problem != nil }, set: { if !$0 { store.problem = nil } })) {
            Button("OK") { store.problem = nil }
        } message: { Text(store.problem ?? "") }
        .onChange(of: phase) { _, phase in if phase == .active { store.sendPacket() } }
    }

    private func timeOnSelectedDay() -> Date {
        let cal = Calendar.current
        let now = cal.dateComponents([.hour, .minute, .second], from: Date())
        let chosen = cal.date(bySettingHour: now.hour ?? 12, minute: now.minute ?? 0, second: now.second ?? 0, of: day) ?? day
        return min(chosen, Date())
    }

    private var dashboard: some View {
        let summary = store.journal.day(day)
        return DarkPage {
            HStack {
                BrandHeading()
                Spacer()
                Button { showingDate = true } label: {
                    HStack(spacing: 5) {
                        Text(day.formatted(.dateTime.locale(Locale(identifier: "en_US")).day().month(.abbreviated)))
                        Image(systemName: "chevron.down")
                    }.font(.caption.weight(.semibold)).padding(.vertical, 12).padding(.horizontal, 11)
                        .foregroundStyle(Ink.text).rhythmPanel(radius: 12)
                }.accessibilityLabel("Choose date")
            }
            PageHeading(title: Calendar.current.isDateInToday(day) ? "Today’s nutrition" : "Daily journal",
                        subtitle: "Good habits, one portion at a time.")
            EnergyCard(day: summary, goal: store.journal.target)
            MacroRow(day: summary)
            Button { picking = true } label: { ActionLabel(title: "Add food", icon: "plus") }
                .buttonStyle(.plain)
            SectionHeading(title: "Meal timeline", mark: "Your day").padding(.top, 8)
            if summary.entries.isEmpty {
                HStack(spacing: 14) {
                    FoodSymbol(icon: "fork.knife", color: Ink.green, size: 46)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your first portion").font(.headline)
                        Text("Search for a food or scan the barcode on its packaging to start your log.")
                            .foregroundStyle(Ink.muted).font(.subheadline)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                    .rhythmPanel(radius: 18)
            } else {
                ForEach(Meal.allCases) { meal in
                    let entries = summary.entries.filter { $0.meal == meal }
                    if !entries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                FoodSymbol(icon: meal.symbol, color: meal.color, size: 34)
                                Text(meal.title).font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(entries.count) " + (entries.count == 1 ? "portion" : "portions"))
                                    .font(.caption).foregroundStyle(Ink.muted)
                            }
                            ForEach(entries) { entry in
                                Button { draft = entry } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.name).font(.headline)
                                            Text(number(entry.grams, precision: 1) + " g · " + number(entry.nutrients.kcal) + " kcal")
                                                .font(.subheadline).foregroundStyle(Ink.muted)
                                        }
                                        Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(Ink.muted)
                                    }.contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityIdentifier("meal-" + entry.code)
                                if entry.id != entries.last?.id { Divider() }
                            }
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                            .rhythmPanel(radius: 20)
                    }
                }
            }
            if !store.journal.recent.isEmpty {
                SectionHeading(title: "Repeat a portion", mark: "Recent foods")
                ForEach(store.journal.recent) { item in
                    Button { draft = item.repeated(at: timeOnSelectedDay()) } label: {
                        HStack {
                            FoodSymbol(icon: "arrow.counterclockwise", color: Ink.blue, size: 34)
                            Text(item.name).font(.subheadline.weight(.medium)).lineLimit(1); Spacer()
                            Text(number(item.grams, precision: 1) + " g").font(.subheadline.monospacedDigit()).foregroundStyle(Ink.muted)
                        }.contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}
