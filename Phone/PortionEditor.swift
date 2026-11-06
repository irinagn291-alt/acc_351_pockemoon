import SwiftUI

struct PortionEditor: View {
    @EnvironmentObject var store: JournalStore
    @Environment(\.dismiss) var dismiss
    @State var portion: Portion
    let existing: Bool
    @State private var grams: String
    @State private var confirmDelete = false
    @FocusState private var editingWeight: Bool

    init(portion: Portion, existing: Bool) {
        _portion = State(initialValue: portion)
        _grams = State(initialValue: portion.grams.formatted(.number.locale(Locale(identifier: "en_US")).grouping(.never).precision(.fractionLength(0...3))))
        self.existing = existing
    }
    private var weight: Double? {
        let compact = grams.filter { !$0.isWhitespace }.replacingOccurrences(of: ",", with: ".")
        guard let grams = Double(compact), grams > 0, grams <= 10_000 else { return nil }
        return grams
    }
    var body: some View {
        NavigationStack {
            DarkPage {
                HStack(spacing: 10) {
                    FoodSymbol(icon: "fork.knife", color: Ink.green, size: 34)
                    Overline(existing ? "Edit portion" : "New portion").foregroundStyle(Ink.muted)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Ink.muted).frame(width: 44, height: 44)
                            .background(Ink.elevated, in: Circle())
                    }.buttonStyle(.plain).accessibilityLabel("Close")
                }
                Text(portion.name).font(.system(size: 30, weight: .bold)).tracking(-0.6)
                if !portion.brand.isEmpty { Text(portion.brand).foregroundStyle(Ink.muted) }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Portion weight").font(.headline)
                    HStack {
                        TextField("0", text: $grams).keyboardType(.decimalPad).focused($editingWeight).font(.system(size: 42, weight: .semibold)).monospacedDigit()
                            .accessibilityLabel("Portion weight in grams")
                        Text("g").foregroundStyle(Ink.muted).font(.title2)
                    }
                    HStack(spacing: 8) {
                        ForEach([50, 100, 150, 250], id: \.self) { quantity in
                            Button("\(quantity) g") { grams = String(quantity); editingWeight = false }
                                .font(.subheadline.monospacedDigit()).frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .foregroundStyle(weight == Double(quantity) ? Ink.ground : Ink.text)
                                .background(weight == Double(quantity) ? Ink.blue : Ink.elevated, in: RoundedRectangle(cornerRadius: 11))
                                .buttonStyle(.plain)
                        }
                    }
                    if weight == nil { Text("Enter a weight greater than zero and no more than 10,000 g.").font(.caption).foregroundStyle(Ink.error) }
                }.padding(18).rhythmPanel(radius: 22)
                if let weight {
                    let nutrients = portion.per100.scaled(weight / 100)
                    let protein = number(nutrients.protein, precision: 1)
                    let fat = number(nutrients.fat, precision: 1)
                    let carbs = number(nutrients.carbs, precision: 1)
                    let macroSummary = "P \(protein) g   ·   F \(fat) g   ·   C \(carbs) g"
                    VStack(alignment: .leading, spacing: 12) {
                      HStack {
                        Text("Portion energy").font(.headline)
                        Spacer(); Text(number(nutrients.kcal) + " kcal").bold().foregroundStyle(Ink.blue)
                    }
                    Text(macroSummary)
                        .font(.subheadline.monospacedDigit()).foregroundStyle(Ink.muted)
                    }.padding(18).rhythmPanel()
                }
                Text("Meal & time").font(.headline).padding(.top, 4)
                Picker("Meal", selection: $portion.meal) { ForEach(Meal.allCases) { Text($0.title).tag($0) } }
                    .pickerStyle(.segmented)
                DatePicker("Date and time", selection: $portion.date, in: ...Date())
                    .environment(\.locale, Locale(identifier: "en_US"))
                Button {
                    guard let weight else { return }
                    portion.grams = weight
                    if store.save(portion) { dismiss() }
                } label: { ActionLabel(title: existing ? "Save changes" : "Log portion", icon: "checkmark") }
                    .buttonStyle(.plain).disabled(weight == nil).opacity(weight == nil ? 0.4 : 1)
                if existing {
                    Button("Delete entry", role: .destructive) { confirmDelete = true }.frame(maxWidth: .infinity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { editingWeight = false }
                }
            }
            .confirmationDialog("Delete this portion from your journal?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if store.change({ journal in journal.entries.removeAll { $0.id == portion.id } }) { dismiss() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
