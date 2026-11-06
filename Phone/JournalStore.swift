import SwiftUI
import WidgetKit

final class JournalStore: NSObject, ObservableObject {
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

}
