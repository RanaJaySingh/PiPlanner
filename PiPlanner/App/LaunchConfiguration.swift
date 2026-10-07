import Foundation

/// Launch arguments for UI tests and demo rehearsals.
///
/// `-ui-testing` pins the clock to the demo evening (5 Oct 2026, 7:42 pm) and uses the offline Grok.
/// `-demo-stage <stage>` starts part-way through Rahul's demo, e.g. `-demo-stage afterOpening`.
struct LaunchConfiguration {
    let isUITesting: Bool
    let stage: DemoScenario.Stage

    init(arguments: [String]) {
        isUITesting = arguments.contains("-ui-testing")
        if let index = arguments.firstIndex(of: "-demo-stage"), arguments.indices.contains(index + 1),
           let stage = DemoScenario.Stage(argument: arguments[index + 1]) {
            self.stage = stage
        } else {
            stage = .welcome
        }
    }

    @MainActor
    func makeStore() -> LedgerStore {
        guard isUITesting || stage != .welcome else {
            return LedgerStore(services: .live())
        }
        let settings = GrokSettings(suiteName: "com.piplanner.uitests")
        settings.mode = .mock
        let ledger = DemoScenario.ledger(at: stage)
        let services = AppServices(
            clock: isUITesting ? FixedClock(now: DemoScenario.now) : SystemClock(),
            calendar: isUITesting ? DemoScenario.calendar : .current,
            bank: DemoScenario.bank(for: ledger, at: stage),
            grok: GrokOrchestrator(provider: GrokClientProvider(settings: settings))
        )
        return LedgerStore(
            services: services,
            ledger: ledger,
            grokSettings: settings,
            lastBalanceUpdate: stage == .welcome ? nil : services.clock.now
        )
    }
}

extension DemoScenario.Stage {
    init?(argument: String) {
        guard let stage = Self.allCases.first(where: { String(describing: $0) == argument }) else { return nil }
        self = stage
    }
}
