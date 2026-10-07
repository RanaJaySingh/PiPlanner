import Foundation

/// Pulls amounts, months, percentages and goal names out of a plain-language sentence.
/// Used by the mock client; the live client gets the same information from Grok.
struct UtteranceParser: Sendable {
    let today: YearMonth

    // MARK: - Amounts

    /// "₹10 lakh" → 10,00,000, "5k" → 5,000, "₹50,000" → 50,000. Bare numbers such as years are ignored.
    func amounts(in text: String) -> [Decimal] {
        // Digit groups must be 2 or 3 wide, so the comma in "by 2030, 20%" is not part of a number.
        matches(of: #"(₹\s*)?(\d+(?:,\d{2,3})*(?:\.\d+)?)\s*(lakhs?|lacs?|crores?|cr|thousand|k|l)?\b(\s*%)?"#, in: text).compactMap { groups in
            guard groups[4] == nil else { return nil }
            let hasSymbol = groups[1] != nil
            let digits = groups[2] ?? ""
            let unit = groups[3]?.lowercased()
            guard hasSymbol || unit != nil || digits.contains(",") else { return nil }
            guard let base = Decimal(string: digits.replacingOccurrences(of: ",", with: ""), locale: Locale(identifier: "en_US_POSIX")) else {
                return nil
            }
            return (base * multiplier(for: unit)).rounded()
        }
    }

    private func multiplier(for unit: String?) -> Decimal {
        switch unit {
        case "k", "thousand": 1_000
        case "l", "lakh", "lakhs", "lac", "lacs": 100_000
        case "cr", "crore", "crores": 10_000_000
        default: 1
        }
    }

    // MARK: - Dates

    /// "by Sep 2030" → Sep 2030, "by March" → the next March, "in a year" → 11 months after this one.
    func endMonth(in text: String) -> YearMonth? {
        let monthPattern = #"\b(jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|aug(?:ust)?|sep(?:t(?:ember)?)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?)\b(?:\s+(\d{4}))?"#
        if let groups = matches(of: monthPattern, in: text).first, let name = groups[1], let month = monthNumber(name) {
            if let yearText = groups[2], let year = Int(yearText) {
                return YearMonth(year: year, month: month)
            }
            return today.adding(months: 1).next(month: month)
        }

        let relativePattern = #"\bin\s+(a|an|one|two|three|four|five|\d+)\s+(years?|months?)\b"#
        if let groups = matches(of: relativePattern, in: text).first, let countText = groups[1], let unit = groups[2] {
            let count = wordNumber(countText)
            let months = unit.hasPrefix("year") ? count * 12 : count
            return months > 0 ? today.adding(months: months - 1) : nil
        }
        return nil
    }

    private func monthNumber(_ name: String) -> Int? {
        let prefixes = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
        return prefixes.firstIndex { name.lowercased().hasPrefix($0) }.map { $0 + 1 }
    }

    private func wordNumber(_ text: String) -> Int {
        switch text.lowercased() {
        case "a", "an", "one": 1
        case "two": 2
        case "three": 3
        case "four": 4
        case "five": 5
        default: Int(text) ?? 0
        }
    }

    // MARK: - Percentages and names

    func percent(in text: String) -> Decimal? {
        matches(of: #"(\d+(?:\.\d+)?)\s*%"#, in: text).first
            .flatMap { $0[1] }
            .flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
    }

    /// The canonical goal name for the first keyword found, e.g. "Goa trip" or "Emergency".
    func goalName(in text: String) -> String? {
        let table: [(pattern: String, name: String)] = [
            ("goa", "Goa trip"),
            ("vacation", "Vacation"),
            ("holiday", "Vacation"),
            ("trip", "Trip"),
            ("car", "Car"),
            ("emergency", "Emergency"),
            ("home|house|flat", "Home"),
            ("bike|scooter", "Bike"),
            ("wedding", "Wedding"),
            ("education|college|school", "Education"),
            ("laptop", "Laptop"),
            ("phone", "Phone"),
        ]
        return table.first { !matches(of: #"\b(\#($0.pattern))s?\b"#, in: text).isEmpty }?.name
    }

    /// Words naming an existing goal, matched by prefix: "emerg" finds "Emergency".
    func goalNamed(_ word: String, among names: [String]) -> String? {
        let lowered = word.lowercased()
        return names.first { $0.lowercased() == lowered }
            ?? names.first { $0.lowercased().hasPrefix(lowered) || lowered.hasPrefix($0.lowercased()) }
    }

    /// "A ₹10 lakh car by Sep 2030 and a ₹2 lakh emergency fund" → two clauses.
    func clauses(of text: String) -> [String] {
        let separators = #"\s+and\s+|\s+plus\s+|[;,]\s+(?=\D)"#
        guard let regex = try? NSRegularExpression(pattern: separators, options: [.caseInsensitive]) else { return [text] }
        let range = NSRange(text.startIndex..., in: text)
        let marked = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "\u{1F}")
        return marked.split(separator: "\u{1F}").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    func isQuestion(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let starters = ["what", "why", "how", "when", "can", "should", "is", "will", "do", "does"]
        return trimmed.hasSuffix("?") || starters.contains { trimmed.hasPrefix($0 + " ") }
    }

    /// Payments and spending, which PiPlanner never does: "Send ₹5,000 to Ravi", "Pay my rent".
    func asksToMoveMoneyOut(_ text: String) -> Bool {
        !matches(of: #"\b(pay|send|withdraw|invest|buy|spend|upi)\b"#, in: text).isEmpty
    }

    /// "Move 5k from Emergency to Car" → ("Emergency", "Car").
    func transferEndpoints(in text: String) -> (from: String, to: String)? {
        guard !matches(of: #"\b(move|transfer|shift)\b"#, in: text).isEmpty,
              let groups = matches(of: #"\bfrom\s+([A-Za-z][\w ]*?)\s+to\s+([A-Za-z][\w ]*?)\s*[.!?]?$"#, in: text).first,
              let from = groups[1], let to = groups[2] else {
            return nil
        }
        return (from, to)
    }

    // MARK: - Regex

    /// Capture groups of every match; index 0 is the whole match, missing groups are nil.
    private func matches(of pattern: String, in text: String) -> [[String?]] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).map { result in
            (0..<result.numberOfRanges).map { index in
                Range(result.range(at: index), in: text).map { String(text[$0]) }
            }
        }
    }
}
