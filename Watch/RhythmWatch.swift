import SwiftUI
import WatchConnectivity

final class WristStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var packet = WristPacket.empty
    @Published var notice: String?
    private let key = "rhythm.wrist.packet"
    private var lastReceived: Date?
    private let pendingKey = "rhythm.wrist.pending"
    private var pending: [String: Data] {
        get { UserDefaults.standard.dictionary(forKey: pendingKey) as? [String: Data] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: pendingKey) }
    }
    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(WristPacket.self, from: data) { packet = saved; lastReceived = saved.date }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    private func receive(_ context: [String: Any]) {
        guard let data = context["rhythm"] as? Data,
              let next = try? JSONDecoder().decode(WristPacket.self, from: data) else { return }
        DispatchQueue.main.async {
            if let last = self.lastReceived, last > next.date { return }
            self.lastReceived = next.date
            let received = Set((next.acknowledged ?? []).map(\.uuidString)).intersection(self.pending.keys)
            if !received.isEmpty {
                self.pending = self.pending.filter { !received.contains($0.key) }
                self.notice = "Portion logged on your iPhone."
            }
            self.packet = next
            UserDefaults.standard.set(data, forKey: self.key)
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        receive(session.receivedApplicationContext)
        refresh()
        DispatchQueue.main.async {
            for (id, data) in self.pending { self.enqueue(id, data: data) }
        }
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        receive(applicationContext)
    }
    func sessionReachabilityDidChange(_ session: WCSession) {
        refresh()
    }
    func refresh() {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated,
              WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["snapshot": true], replyHandler: { [weak self] reply in
            self?.receive(reply)
        }, errorHandler: { _ in })
    }
    private func enqueue(_ id: String, data: Data) {
        guard pending[id] != nil else { return }
        let session = WCSession.default
        if !session.outstandingUserInfoTransfers.contains(where: { $0.userInfo["action"] as? String == id }) {
            session.transferUserInfo(["repeat": data, "action": id])
        }
        notice = "Portion queued. Your iPhone will log it when it syncs."
    }
    func repeatEntry(_ item: Portion) {
        let entry = item.repeated()
        guard WCSession.isSupported(), WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(entry) else {
            notice = "Connection unavailable. Try again in a moment."
            return
        }
        let id = entry.id.uuidString
        pending[id] = data
        let session = WCSession.default
        guard session.isReachable else { enqueue(id, data: data); return }
        notice = "Sending portion to iPhone…"
        session.sendMessage(["repeat": data], replyHandler: { reply in
            self.receive(reply)
            DispatchQueue.main.async {
                if reply["accepted"] as? Bool == true {
                    self.pending[id] = nil
                    self.notice = "Portion logged on your iPhone."
                } else {
                    self.enqueue(id, data: data)
                }
            }
        }, errorHandler: { _ in
            DispatchQueue.main.async { self.enqueue(id, data: data) }
        })
        // A reachable session can lose its reply while either app moves to the background.
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            self.enqueue(id, data: data)
        }
    }

}

@main
struct RhythmWatch: App {
    @StateObject var store = WristStore()
    @State private var selected: Portion?
    @Environment(\.scenePhase) var scenePhase
    let blue = Color(red: 0.302, green: 0.616, blue: 1)
    let green = Color(red: 0.208, green: 0.855, blue: 0.612)
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("FOOD JOURNAL", systemImage: "leaf.fill").font(.caption2.bold()).foregroundStyle(blue)
                        TimelineView(.everyMinute) { context in
                            let current = Calendar.current.isDate(store.packet.date, inSameDayAs: context.date)
                            let kcal = current ? store.packet.kcal : 0
                            Text(number(kcal) + " kcal").font(.system(.title2, design: .default).bold())
                            Text("Today · portions: \(current ? store.packet.count : 0)")
                                .font(.footnote).foregroundStyle(.secondary)
                            if let goal = store.packet.target { ProgressView(value: min((kcal ?? 0) / goal, 1)).tint(green) }
                            if current && store.packet.partial {
                                Text("Includes known values only").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        Divider()
                        if let notice = store.notice {
                            Label(notice, systemImage: "applewatch.radiowaves.left.and.right")
                                .font(.footnote).foregroundStyle(blue).accessibilityIdentifier("transfer-status")
                        }
                        Text("Repeat a portion").font(.headline)
                        if store.packet.recent.isEmpty {
                            Text("Log your first portion in the iPhone journal.")
                                .font(.footnote).foregroundStyle(.secondary)
                        } else {
                            ForEach(store.packet.recent) { item in
                                Button { selected = item } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name).font(.headline).lineLimit(2)
                                        Text(number(item.grams, precision: 1) + " g · " + item.meal.title)
                                            .font(.caption2).foregroundStyle(.secondary)
                                    }.frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.background(Color(red: 0.043, green: 0.071, blue: 0.125)).navigationTitle("PockeMoon")
                .onAppear { store.refresh() }
                .onChange(of: scenePhase) { _, phase in if phase == .active { store.refresh() } }
                .sheet(item: $selected) { item in
                    ScrollView {
                        Text(item.name).font(.headline)
                        Text(item.meal.title + " · " + number(item.grams, precision: 1) + " g").font(.caption)
                        Button("Log for today") { selected = nil; store.repeatEntry(item) }.tint(green)
                        Button("Cancel") { selected = nil }
                    }
                }
            }
        }
    }
}
