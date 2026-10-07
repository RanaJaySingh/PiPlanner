import SwiftUI

/// Month and year wheels in a fitted sheet, for goal start and end dates.
struct PiMonthPickerSheet: View {
    let title: Text
    @Binding var selection: YearMonth
    let range: ClosedRange<YearMonth>

    @Environment(\.dismiss) private var dismiss
    @State private var month: Int
    @State private var year: Int

    /// A calendar without a locale returns "M01"…"M12".
    private static let monthNames: [String] = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .autoupdatingCurrent
        return calendar.shortMonthSymbols
    }()

    init(title: Text, selection: Binding<YearMonth>, range: ClosedRange<YearMonth>) {
        self.title = title
        _selection = selection
        self.range = range
        _month = State(initialValue: selection.wrappedValue.month)
        _year = State(initialValue: selection.wrappedValue.year)
    }

    var body: some View {
        PiSheet {
            PiSheetHeader(title) { dismiss() }
            HStack(spacing: 0) {
                Picker("Month", selection: $month) {
                    ForEach(1...12, id: \.self) { value in
                        Text(verbatim: Self.monthNames[value - 1]).tag(value)
                    }
                }
                Picker("Year", selection: $year) {
                    ForEach(range.lowerBound.year...range.upperBound.year, id: \.self) { value in
                        Text(verbatim: String(value)).tag(value)
                    }
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
            Button("Done") {
                selection = clamped(YearMonth(year: year, month: month))
                dismiss()
            }
            .buttonStyle(.piPrimary)
        }
    }

    private func clamped(_ value: YearMonth) -> YearMonth {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

#Preview {
    @Previewable @State var month = YearMonth(year: 2030, month: 9)
    Color.clear.sheet(isPresented: .constant(true)) {
        PiMonthPickerSheet(
            title: Text("End"),
            selection: $month,
            range: YearMonth(year: 2026, month: 10)...YearMonth(year: 2046, month: 12)
        )
    }
}
