import Foundation
import Testing
@testable import PiPlanner

/// Serves canned responses and keeps the last request, so the live client is tested offline.
final class StubURLProtocol: URLProtocol {
    struct Response {
        let status: Int
        let body: Data
    }

    // Only touched by the serialized suite below.
    nonisolated(unsafe) static var response = Response(status: 200, body: Data())
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastBody = request.httpBody ?? request.httpBodyStream.map(Self.read)
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.response.status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4_096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            data.append(buffer, count: count)
        }
        return data
    }
}

@Suite("Live xAI client", .serialized)
struct LiveXAIClientTests {
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }()

    private var request: GrokRequest {
        let ledger = Fixture.ledger(.afterCustomCredit)
        let context = GrokOrchestrator.context(ledger: ledger, asOf: Fixture.october, calendar: Fixture.calendar)
        return GrokRequest(utterance: "Move 5k from Emergency to Car", surface: .ask, context: context, followUpCount: 0)
    }

    private func completion(content: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["choices": [["message": ["content": content]]]])
    }

    @Test("Posts the request with the key and decodes the JSON reply")
    func success() async throws {
        StubURLProtocol.response = .init(status: 200, body: try completion(content: """
        {"kind":"transfer","transfer":{"from":"Emergency","to":"Car","amount":5000}}
        """))
        let client = LiveXAIClient(apiKey: "test-key", model: "grok-test", session: session)

        let reply = try await client.reply(to: request)

        #expect(reply.kind == .transfer)
        #expect(reply.transfer == .init(from: "Emergency", to: "Car", amount: 5_000))
        let sent = try #require(StubURLProtocol.lastRequest)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url == LiveXAIClient.endpoint)
        #expect(sent.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        let body = try #require(StubURLProtocol.lastBody.flatMap { String(data: $0, encoding: .utf8) })
        #expect(body.contains("grok-test"))
        #expect(body.contains("json_object"))
        #expect(!body.contains("HDFC") && !body.contains("4821"))
    }

    @Test("Decodes entry_split in snake case")
    func entrySplit() async throws {
        StubURLProtocol.response = .init(status: 200, body: try completion(content: """
        {"kind":"entry_goal","goals":[{"name":"Vacation","target":50000,"end":"2027-03"}],
         "entry_split":[{"goal":"Car","percent":50},{"goal":"Emergency","percent":30},{"goal":"Vacation","percent":20}]}
        """))
        let reply = try await LiveXAIClient(apiKey: "k", model: "m", session: session).reply(to: request)
        #expect(reply.kind == .entryGoal)
        #expect(reply.entrySplit?.map(\.percent) == [50, 30, 20])
    }

    @Test("A non-2xx status is an error, which the orchestrator turns into unavailable")
    func badStatus() async throws {
        StubURLProtocol.response = .init(status: 401, body: Data("{}".utf8))
        let client = LiveXAIClient(apiKey: "bad", model: "m", session: session)
        await #expect(throws: LiveXAIClient.ClientError.self) {
            try await client.reply(to: request)
        }

        let orchestrator = GrokOrchestrator(provider: StubGrokProvider(client: client))
        let outcome = await orchestrator.respond(
            to: "How are my goals doing?",
            surface: .ask,
            ledger: Fixture.ledger(.afterCustomCredit),
            followUpCount: 0,
            asOf: Fixture.october,
            calendar: Fixture.calendar
        )
        #expect(outcome == .unavailable)
    }

    @Test("Malformed content is an error rather than a guess")
    func malformed() async throws {
        StubURLProtocol.response = .init(status: 200, body: try completion(content: "Sure! Here is your plan."))
        await #expect(throws: (any Error).self) {
            try await LiveXAIClient(apiKey: "k", model: "m", session: session).reply(to: request)
        }
    }
}
