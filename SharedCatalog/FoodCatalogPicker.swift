import SwiftUI

struct FoodCatalogPicker: View {
    let onPick: (FoodProduct) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var library = FoodCatalog.merge(FoodCatalog.saved, FoodCatalog.bundled)
    @State private var networkResults: [FoodProduct] = []
    @State private var status: String?
    @State private var loading = false
    @State private var request: Task<Void, Never>?
    @State private var generation = UUID()
    @State private var scanner = false
    @State private var manual = false
    @FocusState private var focused: Bool

    #if DEBUG && targetEnvironment(simulator)
    init(onPick: @escaping (FoodProduct) -> Void) {
        self.onPick = onPick
        _manual = State(initialValue: ScreenshotLaunch.screen == .barcodeScanner)
    }
    #endif

    private var query: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var visible: [FoodProduct] { FoodCatalog.merge(networkResults, FoodCatalog.local(query, in: library)) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Ink.blue)
                        TextField("Name, brand or barcode", text: Binding(get: { text }, set: { text = $0; invalidate() }))
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($focused).submitLabel(.search).onSubmit { search(query) }
                        if !text.isEmpty {
                            Button { text = ""; invalidate() } label: { Image(systemName: "xmark.circle.fill") }
                                .buttonStyle(.plain).accessibilityLabel("Clear search")
                        }
                    }.padding(.vertical, 9)
                    Button { search(query) } label: {
                        Label("Search Open Food Facts", systemImage: "globe")
                            .font(.subheadline.weight(.semibold)).padding(.vertical, 6)
                    }.disabled(query.count < 2 || loading)
                }.listRowBackground(Ink.panel).listRowSeparatorTint(Ink.border)
                Section {
                    Button { focused = false; scanner = true } label: {
                        HStack(spacing: 12) {
                            FoodSymbol(icon: "barcode.viewfinder", color: Ink.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scan a barcode").font(.headline).foregroundStyle(Ink.text)
                                Text("Find the label on your package").font(.caption).foregroundStyle(Ink.muted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Ink.muted)
                        }.padding(.vertical, 5)
                    }.buttonStyle(.plain)
                }.listRowBackground(Ink.panel)
                if loading {
                    HStack { ProgressView().tint(Ink.blue); Text("Searching the catalog…").foregroundStyle(Ink.muted) }
                        .listRowBackground(Ink.panel)
                }
                if let status { Text(status).font(.callout).foregroundStyle(Ink.muted).listRowBackground(Ink.panel) }
                if !visible.isEmpty {
                    Section {
                        ForEach(visible) { product in
                            Button {
                                FoodCatalog.remember([product])
                                dismiss()
                                onPick(product)
                            } label: {
                                HStack(spacing: 13) {
                                    thumbnail(product)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(product.name).font(.subheadline.weight(.semibold)).foregroundStyle(Ink.text).lineLimit(2)
                                        if !product.brand.isEmpty {
                                            Text(product.brand).font(.caption).foregroundStyle(Ink.muted).lineLimit(1)
                                        }
                                        Text(number(product.kcal) + " kcal / 100 g").font(.caption2).foregroundStyle(Ink.blue)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "plus").font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Ink.blue).frame(width: 28, height: 28)
                                        .background(Ink.blue.opacity(0.12), in: Circle())
                                }.padding(.vertical, 6).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    } header: {
                        Text(networkResults.isEmpty ? "On this device" : "Search results").foregroundStyle(Ink.muted)
                    }.listRowBackground(Ink.panel).listRowSeparatorTint(Ink.border)
                } else if !loading && status == nil {
                    Text("No matches on this device. Search Open Food Facts or enter the details from the label.")
                        .font(.callout).foregroundStyle(Ink.muted).listRowBackground(Ink.panel)
                }
                Section {
                    Button { focused = false; manual = true } label: {
                        Label("Enter label by hand", systemImage: "square.and.pencil").font(.subheadline.weight(.semibold)).padding(.vertical, 5)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Product data comes from Open Food Facts contributors. Check the package for the current ingredients.")
                        Link("Open Food Facts · Data ODbL · Photos CC BY-SA", destination: URL(string: "https://world.openfoodfacts.org/terms-of-use")!)
                    }.foregroundStyle(Ink.muted)
                }.listRowBackground(Ink.panel)
            }
            .scrollContentBackground(.hidden).background(Ink.ground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Food catalog").navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Ink.ground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .onDisappear { request?.cancel() }
            .sheet(isPresented: $scanner) {
                FoodScanner { scanned in
                    scanner = false
                    text = scanned
                    search(scanned)
                }
            }
            .navigationDestination(isPresented: $manual) {
                ManualFoodEntry(initialName: FoodCatalog.barcode(query) == nil ? query : "") { product in
                    FoodCatalog.remember([product])
                    dismiss()
                    onPick(product)
                }
            }
        }
    }

    @ViewBuilder private func thumbnail(_ product: FoodProduct) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(Ink.elevated)
            Image(systemName: "carrot").foregroundStyle(Ink.blue)
            if let url = product.imageURL, url.scheme == "https" {
                AsyncImage(url: url) { phase in
                    if let image = phase.image { image.resizable().scaledToFit().background(.white) }
                }
            }
        }.frame(width: 50, height: 54).clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityHidden(true)
    }

    private func invalidate() {
        request?.cancel()
        generation = UUID()
        loading = false
        status = nil
        networkResults = []
    }
    private func search(_ raw: String) {
        let term = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard term.count >= 2 else { return }
        invalidate()
        let token = generation
        focused = false
        loading = true
        request = Task { @MainActor in
            defer { if generation == token { loading = false } }
            do {
                let products = try await FoodCatalog.remote(term)
                guard !Task.isCancelled, generation == token else { return }
                networkResults = products
                FoodCatalog.remember(products)
                library = FoodCatalog.merge(products, library)
                status = products.isEmpty ? "No matches in Open Food Facts." : nil
            } catch {
                guard !Task.isCancelled, generation == token else { return }
                status = (error as? CatalogIssue)?.errorDescription ??
                    "Couldn’t reach the catalog. Use a saved product or enter the label by hand."
            }
        }
    }
}

private struct ManualFoodEntry: View {
    @State private var name: String
    @State private var brand = ""
    @State private var kcal = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var ingredients = ""
    let onSave: (FoodProduct) -> Void
    init(initialName: String, onSave: @escaping (FoodProduct) -> Void) {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.screen == .barcodeScanner {
            let product = ScreenshotLaunch.oats
            func labelValue(_ value: Double?) -> String {
                value.map { $0.formatted(.number.locale(Locale(identifier: "en_US")).grouping(.never).precision(.fractionLength(0...3))) } ?? ""
            }
            _name = State(initialValue: product.name)
            _brand = State(initialValue: product.brand)
            _kcal = State(initialValue: labelValue(product.kcal))
            _protein = State(initialValue: labelValue(product.protein))
            _carbs = State(initialValue: labelValue(product.carbs))
            _fat = State(initialValue: labelValue(product.fat))
            _ingredients = State(initialValue: product.ingredients ?? "")
        } else {
            _name = State(initialValue: initialName)
        }
        #else
        _name = State(initialValue: initialName)
        #endif
        self.onSave = onSave
    }
    private func number(_ text: String) -> Double? { Double(text.replacingOccurrences(of: ",", with: ".")) }
    private func valid(_ input: String, limit: Double) -> Bool {
        input.isEmpty || number(input).map { $0.isFinite && (0...limit).contains($0) } == true
    }
    var body: some View {
        Form {
            Section("Product") { TextField("Product name", text: $name); TextField("Brand", text: $brand) }.listRowBackground(Ink.panel)
            Section {
                field("Energy, kcal", $kcal)
                field("Protein, g", $protein)
                field("Carbohydrates, g", $carbs)
                field("Fat, g", $fat)
            } header: { Text("Per 100 g") } footer: { Text("Leave a field empty if the value is missing from the label.") }.listRowBackground(Ink.panel)
            Section("Ingredients") { TextField("Ingredient list from the package", text: $ingredients, axis: .vertical).lineLimit(2...6) }.listRowBackground(Ink.panel)
            Button("Use this product") {
                let product = FoodProduct(id: "manual-" + UUID().uuidString,
                                          name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                          brand: brand.trimmingCharacters(in: .whitespacesAndNewlines),
                                          kcal: number(kcal), protein: number(protein), carbs: number(carbs), fat: number(fat),
                                          ingredients: ingredients.isEmpty ? nil : ingredients)
                onSave(product)
            }.listRowBackground(Ink.panel).disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                       !valid(kcal, limit: 1000) || !valid(protein, limit: 100) ||
                       !valid(carbs, limit: 100) || !valid(fat, limit: 100))
        }.scrollContentBackground(.hidden).background(Ink.ground)
            .navigationTitle("New product").navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Ink.ground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
    private func field(_ label: String, _ value: Binding<String>) -> some View {
        LabeledContent(label) {
            TextField("—", text: value).multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                .accessibilityLabel(label)
        }
    }
}
