import SwiftUI

enum Ink {
    static let ground = Color(red: 0.043, green: 0.071, blue: 0.125)
    static let panel = Color(red: 0.078, green: 0.129, blue: 0.216)
    static let elevated = Color(red: 0.110, green: 0.169, blue: 0.263)
    static let border = Color(red: 0.157, green: 0.224, blue: 0.322)
    static let blue = Color(red: 0.302, green: 0.616, blue: 1)
    static let green = Color(red: 0.208, green: 0.855, blue: 0.612)
    static let muted = Color(red: 0.627, green: 0.694, blue: 0.796)
    static let amber = Color(red: 1, green: 0.792, blue: 0.510)
    static let purple = Color(red: 0.706, green: 0.635, blue: 1)
    static let error = Color(red: 1, green: 0.573, blue: 0.608)
    static let text = Color(red: 0.953, green: 0.969, blue: 1)
}

extension View {
    func rhythmPanel(radius: CGFloat = 20) -> some View {
        background(Ink.panel, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Ink.border.opacity(0.7), lineWidth: 1))
    }
}

extension Meal {
    var color: Color {
        switch self {
        case .breakfast: Ink.amber
        case .lunch: Ink.green
        case .dinner: Ink.purple
        case .snack: Ink.blue
        }
    }
}

struct Overline: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1.7)
    }
}

struct FoodSymbol: View {
    var icon: String
    var color: Color = Ink.blue
    var size: CGFloat = 42
    var body: some View {
        Image(systemName: icon).font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(color).frame(width: size, height: size)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: size * 0.3))
            .accessibilityHidden(true)
    }
}

struct BrandHeading: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "leaf.fill").font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white).frame(width: 39, height: 39)
                .background(LinearGradient(colors: [Ink.blue, Color(red: 0.17, green: 0.35, blue: 0.81)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("PockeMoon").font(.system(size: 16, weight: .bold))
                Text("FOOD JOURNAL").font(.system(size: 8, weight: .semibold)).tracking(1.7).foregroundStyle(Ink.muted)
            }
        }
    }
}

struct PageHeading: View {
    var title: String
    var subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 34, weight: .bold)).tracking(-1)
            Text(subtitle).font(.subheadline).foregroundStyle(Ink.muted)
        }.padding(.vertical, 3)
    }
}

struct EnergyCard: View {
    var day: DaySummary
    var goal: Double?
    private var progress: Double { min(max((day.value(\.kcal) ?? 0) / max(goal ?? 1, 1), 0), 1) }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Daily energy", systemImage: "flame.fill").font(.subheadline.weight(.semibold)).foregroundStyle(Ink.blue)
                Spacer()
                Text("\(day.entries.count) portions").font(.caption.weight(.medium)).foregroundStyle(Ink.muted)
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(number(day.value(\.kcal))).font(.system(size: 53, weight: .bold)).tracking(-2)
                        .monospacedDigit().lineLimit(1).minimumScaleFactor(0.45)
                    Text(day.incomplete ? "kcal · reported values" : "kcal from your portions")
                        .font(.subheadline).foregroundStyle(Ink.muted)
                }.frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle().stroke(Ink.elevated, lineWidth: 8)
                    if goal != nil {
                        Circle().trim(from: 0, to: progress)
                            .stroke(AngularGradient(colors: [Ink.blue, Ink.green], center: .center, startAngle: .zero, endAngle: .degrees(360)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    } else {
                        Circle().stroke(Ink.blue.opacity(0.25), lineWidth: 1).padding(12)
                    }
                    Image(systemName: "fork.knife").font(.system(size: 27, weight: .medium)).foregroundStyle(Ink.blue)
                }.frame(width: 88, height: 88).padding(5).accessibilityHidden(true)
            }
            Rectangle().fill(Ink.border).frame(height: 1)
            HStack(spacing: 7) {
                Image(systemName: goal == nil ? "leaf" : "scope").foregroundStyle(Ink.green)
                Text(goal.map { "Personal target · " + number($0) + " kcal" } ?? "A little awareness, every day.")
                    .font(.caption).foregroundStyle(Ink.muted)
                Spacer(minLength: 0)
            }
        }
        .padding(20).rhythmPanel(radius: 24)
    }
}

struct MacroRow: View {
    var day: DaySummary
    var body: some View {
        HStack(spacing: 9) {
            tile("Protein", day.value(\.protein), Ink.blue)
            tile("Fat", day.value(\.fat), Ink.amber)
            tile("Carbs", day.value(\.carbs), Ink.purple)
        }
        if day.incomplete {
            Label("Some labels have missing values. Totals include the nutrients reported.", systemImage: "info.circle")
                .font(.caption).foregroundStyle(Ink.muted)
        }
    }
    private func tile(_ name: String, _ amount: Double?, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) { Circle().fill(color).frame(width: 5, height: 5); Text(name).font(.caption).foregroundStyle(Ink.muted) }
            Text(number(amount, precision: 1) + " g").font(.system(size: 20, weight: .semibold)).monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.55)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(13).rhythmPanel(radius: 16)
    }
}

struct SectionHeading: View {
    var title: String
    var mark: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(size: 20, weight: .semibold)); Spacer()
            Text(mark).font(.caption).foregroundStyle(Ink.muted)
        }
    }
}

struct DarkPage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) { content }
                .padding(.horizontal, 22).padding(.top, 16).padding(.bottom, 28).frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
        }.foregroundStyle(Ink.text).background(Ink.ground.ignoresSafeArea()).scrollDismissesKeyboard(.interactively)
    }
}

struct ActionLabel: View {
    var title: String, icon: String
    var body: some View {
        Label(title, systemImage: icon).font(.system(size: 16, weight: .bold)).frame(maxWidth: .infinity)
            .padding(.vertical, 17).foregroundStyle(Ink.ground)
            .background(Ink.green, in: RoundedRectangle(cornerRadius: 16))
    }
}
