import Foundation

/// Everything the store and view models depend on, injected so tests and previews can swap it.
struct AppServices: Sendable {
    let clock: any AppClock
    let calendar: Calendar
    let bank: MockBank
    let grok: GrokOrchestrator

    var balance: any BalanceFetching { bank }

    static func live() -> AppServices {
        AppServices(
            clock: SystemClock(),
            calendar: .current,
            bank: MockBank(accounts: []),
            grok: GrokOrchestrator(provider: GrokClientProvider(settings: .standard))
        )
    }
}
