import SwiftUI
import WatchConnectivity
import WidgetKit

final class JournalStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var journal = Journal()
    @Published var problem: String?
    private var writable = true

    override init() {
        super.init()
        #if DEBUG && targetEnvironment(simulator)
        if let screen = ScreenshotLaunch.screen {
            journal = ScreenshotLaunch.journal(for: screen)
            return
        }
        #endif
        do { journal = try JournalFiles.load() }
        catch {
            writable = false
            problem = "Couldn’t open your journal. Restart the app to try again."
        }
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    @discardableResult
    func change(_ edit: (inout Journal) -> Void) -> Bool {
        guard writable else {
            problem = "Journal storage is unavailable. Restart the app to try again."
            return false
        }
        var next = journal
        edit(&next)
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.screen != nil {
            journal = next
            return true
        }
        #endif
        do {
            try JournalFiles.save(next)
            journal = next
            WidgetCenter.shared.reloadTimelines(ofKind: "RationRhythm.Day")
            sendPacket()
            return true
        } catch {
            problem = "Couldn’t save your changes. Check available storage and try again."
            return false
        }
    }

    func save(_ portion: Portion) -> Bool {
        change { journal in
            if let index = journal.entries.firstIndex(where: { $0.id == portion.id }) {
                journal.entries[index] = portion
            } else {
                journal.entries.append(portion)
            }
        }
    }

    func sendPacket() {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.screen != nil { return }
        #endif
        guard WCSession.isSupported(), WCSession.default.activationState == .activated,
              let data = try? JSONEncoder().encode(journal.watchPacket) else { return }
        try? WCSession.default.updateApplicationContext(["rhythm": data])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async { self.sendPacket() }
    }
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.sendPacket() }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    private func acceptRepeat(_ data: Data) -> Bool {
        guard let portion = try? JSONDecoder().decode(Portion.self, from: data),
              portion.grams > 0, portion.grams <= 10_000 else { return false }
        if journal.entries.contains(where: { $0.id == portion.id }) ||
            journal.recentWatchActions?.contains(portion.id) == true { return true }
        return change { journal in
            journal.entries.append(portion)
            journal.recentWatchActions = Array(((journal.recentWatchActions ?? []) + [portion.id]).suffix(512))
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            if let data = message["repeat"] as? Data, !self.acceptRepeat(data) {
                replyHandler(["accepted": false])
                return
            }
            guard let data = try? JSONEncoder().encode(self.journal.watchPacket) else {
                replyHandler(["accepted": false])
                return
            }
            replyHandler(["accepted": true, "rhythm": data])
        }
    }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        if let data = userInfo["repeat"] as? Data {
            DispatchQueue.main.async { _ = self.acceptRepeat(data) }
        }
    }
}
