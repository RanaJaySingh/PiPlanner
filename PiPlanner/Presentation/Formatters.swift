import Foundation

/// Rupee formatting with Indian digit grouping and no decimals (₹1,50,000).
enum MoneyFormat {
    private static let indianLocale = Locale(identifier: "en_IN")

    private static let currencyStyle = Decimal.FormatStyle.Currency(code: "INR", locale: indianLocale)
        .precision(.fractionLength(0))

    private static let groupedStyle = Decimal.FormatStyle(locale: indianLocale)
        .precision(.fractionLength(0))

    /// "₹1,50,000"
    static func rupees(_ amount: Decimal) -> String {
        let magnitude = abs(amount).rounded()
        let formatted = magnitude.formatted(currencyStyle)
        return amount < 0 ? "\u{2212}\(formatted)" : formatted
    }

    /// "+₹50,000" or "−₹8,000"
    static func signedRupees(_ amount: Decimal) -> String {
        amount < 0 ? rupees(amount) : "+\(rupees(amount))"
    }

    /// "1,50,000" without the symbol, for the amount field.
    static func grouped(_ amount: Decimal) -> String {
        amount.rounded().formatted(groupedStyle)
    }
}

/// Percentages as shown in the mockups: "60%", "62.5%".
enum PercentFormat {
    private static let style = Decimal.FormatStyle(locale: Locale(identifier: "en_US_POSIX"))
        .precision(.fractionLength(0...2))
        .grouping(.never)

    static func percent(_ value: Decimal) -> String {
        "\(value.formatted(style))%"
    }

    /// Text for an editable field, without the % sign.
    static func editable(_ value: Decimal) -> String {
        value == 0 ? "" : value.formatted(style)
    }
}

/// Dates shown in history rows and goal forms.
enum DateFormat {
    private static let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    /// "Oct 2026"
    static func month(_ month: YearMonth) -> String {
        "\(monthNames[month.month - 1]) \(month.year)"
    }

    /// "Oct 2026 – Sep 2030"
    static func range(from start: YearMonth, to end: YearMonth) -> String {
        "\(month(start)) – \(month(end))"
    }

    /// "5 Oct", or "Today" when `date` is today.
    static func day(_ date: Date, relativeTo now: Date, calendar: Calendar) -> String {
        if calendar.isDate(date, inSameDayAs: now) {
            return String(localized: "Today")
        }
        let components = calendar.dateComponents([.day, .month], from: date)
        let day = components.day ?? 1
        let monthIndex = (components.month ?? 1) - 1
        return "\(day) \(monthNames[monthIndex])"
    }

    /// "7:42 pm"
    static func time(_ date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: date)
    }
}
