import Foundation

enum MonthDateParser {
    static func defaultDate(
        from monthString: String?,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        guard let raw = monthString?.trimmingCharacters(in: .whitespaces),
              !raw.isEmpty else { return referenceDate }

        let separators = CharacterSet(charactersIn: "-–/,")
        let firstToken = raw
            .components(separatedBy: separators)
            .first?
            .replacingOccurrences(of: " to ", with: " ", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .first ?? raw

        let lowered = firstToken.lowercased()
        let monthSymbols = calendar.monthSymbols.map { $0.lowercased() }
        let shortMonthSymbols = calendar.shortMonthSymbols.map { $0.lowercased() }

        let matchedIndex: Int? =
            monthSymbols.firstIndex { lowered.hasPrefix($0) }
            ?? shortMonthSymbols.firstIndex { lowered.hasPrefix($0) }

        guard let idx = matchedIndex else { return referenceDate }

        let monthNumber = idx + 1
        var components = calendar.dateComponents([.year], from: referenceDate)
        components.month = monthNumber
        components.day = 15

        guard let candidate = calendar.date(from: components) else { return referenceDate }
        if candidate < calendar.startOfDay(for: referenceDate) {
            components.year = (components.year ?? 0) + 1
            return calendar.date(from: components) ?? referenceDate
        }
        return candidate
    }
}
