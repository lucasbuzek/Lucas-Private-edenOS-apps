import SwiftUI
import SWAYcoreKit
import SWAYAppKit

@main struct SWAYApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model).preferredColorScheme(.dark).tint(SwayTheme.violet)
        }
    }
}
