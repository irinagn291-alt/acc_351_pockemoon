import Foundation

enum Meal: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: Self { self }
    var title: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        }
    }
    var symbol: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "moon.stars"
        case .snack: "takeoutbag.and.cup.and.straw"
        }
    }
    static var current: Self {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: .breakfast
        case 11..<16: .lunch
        case 16..<22: .dinner
        default: .snack
        }
    }
}

struct Nutrients: Codable, Equatable {
    var kcal: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    var fiber: Double?

    func scaled(_ factor: Double) -> Self {
        .init(kcal: kcal.map { $0 * factor }, protein: protein.map { $0 * factor },
              carbs: carbs.map { $0 * factor }, fat: fat.map { $0 * factor },
              fiber: fiber.map { $0 * factor })
    }
}

struct Portion: Identifiable, Codable, Equatable {
    var id = UUID()
    var code: String
    var name: String
    var brand: String
    var per100: Nutrients
    var grams: Double
    var meal: Meal
    var date: Date

    var nutrients: Nutrients { per100.scaled(grams / 100) }

    func repeated(at date: Date = Date()) -> Self {
        var copy = self
        copy.id = UUID()
        copy.date = date
        return copy
    }
}

struct DaySummary {
    let entries: [Portion]
    func value(_ key: KeyPath<Nutrients, Double?>) -> Double? {
        if entries.isEmpty { return 0 }
        let known = entries.compactMap { $0.nutrients[keyPath: key] }
        return known.isEmpty ? nil : known.reduce(0, +)
    }
    var incomplete: Bool {
        entries.contains { let n = $0.per100; return n.kcal == nil || n.protein == nil || n.carbs == nil || n.fat == nil }
    }
}

struct Journal: Codable {
    var entries: [Portion] = []
    var target: Double?
    func day(_ date: Date) -> DaySummary {
        .init(entries: entries.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.sorted { $0.date > $1.date })
    }
    var recent: [Portion] {
        var seen = Set<String>()
        return Array(entries.sorted { $0.date > $1.date }.filter { seen.insert($0.code).inserted }.prefix(5))
    }
}

enum JournalFiles {
    static let group = "group.app.rationrhythm.journal"
    static func location() throws -> URL {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return dir.appendingPathComponent("rhythm-journal.json")
    }
    static func load() throws -> Journal {
        let url = try location()
        guard FileManager.default.fileExists(atPath: url.path) else { return Journal() }
        return try JSONDecoder().decode(Journal.self, from: Data(contentsOf: url))
    }
    static func save(_ journal: Journal) throws {
        try JSONEncoder().encode(journal).write(to: location(), options: .atomic)
    }
}

func number(_ value: Double?, precision: Int = 0) -> String {
    guard let value, value.isFinite else { return "—" }
    return value.formatted(.number.locale(Locale(identifier: "en_US")).precision(.fractionLength(0...precision)))
}
