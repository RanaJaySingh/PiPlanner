import Foundation

/// Turns one customer sentence into a structured reply. Mock and live clients share this contract.
protocol GrokClient: Sendable {
    func reply(to request: GrokRequest) async throws -> GrokReply
}

enum GrokMode: String, CaseIterable, Hashable, Sendable {
    /// Offline drafts for the demo sentences. The default, so the demo never depends on the network.
    case mock
    /// xAI chat completions with the same JSON contract.
    case live
    /// Simulates Grok being unavailable; every action still runs through forms.
    case off
}

/// Grok preferences. Mode and model live in UserDefaults; the API key lives in the Keychain.
struct GrokSettings: Sendable {
    static let standard = GrokSettings(suiteName: nil)
    static let defaultModel = "grok-4"

    private enum Key {
        static let mode = "grok.mode"
        static let model = "grok.model"
        static let keychainAccount = "xai-api-key"
    }

    private let suiteName: String?
    private let keychain = KeychainStore(service: "com.piplanner.grok")

    init(suiteName: String?) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    var mode: GrokMode {
        get { defaults.string(forKey: Key.mode).flatMap(GrokMode.init(rawValue:)) ?? .mock }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.mode) }
    }

    var model: String {
        get { defaults.string(forKey: Key.model) ?? Self.defaultModel }
        nonmutating set { defaults.set(newValue, forKey: Key.model) }
    }

    var apiKey: String? {
        get { keychain.read(account: Key.keychainAccount) }
        nonmutating set {
            if let newValue, !newValue.isEmpty {
                keychain.write(newValue, account: Key.keychainAccount)
            } else {
                keychain.delete(account: Key.keychainAccount)
            }
        }
    }
}

/// Supplies the Grok client for a call, or nil when Grok is unavailable.
protocol GrokClientProviding: Sendable {
    func makeClient() -> (any GrokClient)?
}

/// Picks the client for the current mode at call time, so Settings changes apply immediately.
struct GrokClientProvider: GrokClientProviding {
    let settings: GrokSettings
    var session: URLSession = .shared

    /// Nil when Grok is off, or live without a key.
    func makeClient() -> (any GrokClient)? {
        switch settings.mode {
        case .mock:
            return MockGrokClient()
        case .live:
            guard let key = settings.apiKey else { return nil }
            return LiveXAIClient(apiKey: key, model: settings.model, session: session)
        case .off:
            return nil
        }
    }
}
