import SwiftUI

@main
struct PiPlannerApp: App {
    @State private var store: LedgerStore
    @State private var router = Router()

    init() {
        let launch = LaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)
        _store = State(initialValue: launch.makeStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(router)
                .preferredColorScheme(.light)
        }
    }
}
