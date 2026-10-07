import Foundation

/// xAI chat completions client. Sends the request as JSON and expects a `GrokReply` JSON object back.
struct LiveXAIClient: GrokClient {
    enum ClientError: Error {
        case badStatus(Int)
        case emptyResponse
    }

    static let endpoint = URL(string: "https://api.x.ai/v1/chat/completions")

    let apiKey: String
    let model: String
    var session: URLSession = .shared
    var timeout: TimeInterval = 15

    func reply(to request: GrokRequest) async throws -> GrokReply {
        guard let endpoint = Self.endpoint else { throw ClientError.emptyResponse }

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let userContent = String(decoding: try encoder.encode(request), as: UTF8.self)

        let body = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: Self.systemPrompt),
                .init(role: "user", content: userContent),
            ],
            responseFormat: .init(type: "json_object"),
            temperature: 0
        )

        var urlRequest = URLRequest(url: endpoint, timeoutInterval: timeout)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: urlRequest)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ClientError.badStatus(http.statusCode)
        }

        let completion = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = completion.choices.first?.message.content, let json = content.data(using: .utf8) else {
            throw ClientError.emptyResponse
        }
        return try JSONDecoder().decode(GrokReply.self, from: json)
    }

    static let systemPrompt = """
    You are Grok inside PiPlanner, a goal-based savings ledger. You never move money and never compute \
    rupee figures yourself beyond what the context gives you; the PiPlanner engine checks everything.
    Reply with ONE JSON object and nothing else, with this shape:
    {"kind": "goals" | "entry_goal" | "transfer" | "answer" | "follow_up" | "unsupported",
     "goals": [{"name": String, "target": Number, "end": "YYYY-MM", "start": "YYYY-MM", "percent": Number}],
     "entry_split": [{"goal": String, "percent": Number}],
     "transfer": {"from": String, "to": String, "amount": Number},
     "message": String}
    Rules:
    - "goals": the customer describes goals. Start is context.today.
    - "entry_goal": surface is "ask", context.open_entry_amount is set, and the customer adds one goal for this amount. \
    Include that goal in "goals" and a full "entry_split" over existing goals plus the new one, summing to 100.
    - "transfer": the customer moves saved money between two existing goals by name.
    - "answer": a question. Answer in at most three sentences using only numbers from the context, formatted like ₹1,50,000.
    - "follow_up": a target amount or end month is missing. Ask one short question in "message".
    - "unsupported": anything about payments, shopping or other accounts.
    """
}

private struct ChatRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Encodable {
        let type: String
    }

    let model: String
    let messages: [Message]
    let responseFormat: ResponseFormat
    let temperature: Double
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}
