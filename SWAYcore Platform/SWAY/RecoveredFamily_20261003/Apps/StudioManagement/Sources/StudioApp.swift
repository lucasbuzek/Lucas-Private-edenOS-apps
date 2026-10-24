import SwiftUI
import SWAYStudioKit

@main struct StudioApp: App {
    @StateObject private var model = StudioModel()
    var body: some Scene {
        WindowGroup { StudioRoot().environmentObject(model) }
        #if os(macOS)
        .commands { CommandGroup(replacing: .newItem) { Button("New Class…") { model.nav = .schedule; model.showNewClass = true }.keyboardShortcut("n") } }
        #endif
    }
}

@MainActor final class StudioModel: ObservableObject {
    enum Nav: String, CaseIterable, Identifiable { case today = "Today", schedule = "Schedule", people = "People", memberships = "Memberships", billing = "Billing", admin = "Admin"; var id: String { rawValue } }
    @Published var nav: Nav? = .today
    @Published var rev = 0                      // bumps on every successful mutation to refresh views
    @Published var error: String?
    @Published var showNewClass = false
    let store: StudioStore
    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("SWAYcoreStudio")
        store = (try? StudioStore(url: dir.appendingPathComponent("studio.json"))) ?? (try! StudioStore())
    }
    func run(_ f: () throws -> Void) { do { try f(); rev += 1; error = nil } catch { self.error = Self.describe(error) } }
    static func describe(_ e: Error) -> String {
        switch e as? StudioError {
        case .classFull?: return "This class is full."
        case .alreadyEnrolled?: return "Already enrolled."
        case .noActiveMembership?: return "This member has no active membership."
        case .instructorConflict?: return "That instructor already teaches at this time."
        case .inactiveInstructor?: return "That instructor is inactive."
        case .overpayment?: return "Payment is more than the balance."
        case .notEnrolled?: return "Not on the roster."
        case .notFound(let s)?: return "Not found: \(s)"
        case .invalid(let s)?: return "Invalid: \(s)"
        case nil: return e.localizedDescription
        }
    }
    var today: String { Day.string(Date()) }
}

func money(_ cents: Int) -> String { String(format: "$%.2f", Double(cents) / 100) }
