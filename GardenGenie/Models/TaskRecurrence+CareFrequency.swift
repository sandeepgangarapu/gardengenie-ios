import Foundation

extension TaskRecurrence {

    /// Best-effort read of a care-guide frequency phrase into a repeat rule.
    ///
    /// The regional care schedule is LLM-written free text, e.g.
    /// "Every 2–3 days during dry spells", "Pinch back every 1-2 weeks",
    /// "Biweekly", "Check soil 2–3 times weekly…". Phrases that don't describe a
    /// regular cadence ("Annually after flowering", "Once in early spring",
    /// "Replenish as needed") return `nil`.
    ///
    /// When a phrase gives a range, this picks the longer interval
    /// ("every 2–3 days" → every 3 days, "2–3 times weekly" → every 4 days),
    /// so reminders lean toward fewer pings. The care-plan sheet lets the user
    /// tighten it. If several cadences appear, the first one in the text wins.
    init?(careFrequency raw: String?) {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let text = Self.normalizeFrequency(raw)
        let fullRange = NSRange(text.startIndex..., in: text)

        var best: (location: Int, value: TaskRecurrence)?
        for rule in Self.frequencyRules {
            guard let match = rule.regex.firstMatch(in: text, range: fullRange),
                  let value = rule.resolve(match, text) else { continue }
            if best == nil || match.range.location < best!.location {
                best = (match.range.location, value)
            }
        }
        guard let best else { return nil }
        self = best.value
    }

    // MARK: - Rules

    private struct FrequencyRule {
        let regex: NSRegularExpression
        let resolve: (NSTextCheckingResult, String) -> TaskRecurrence?
    }

    /// "3", "2-3", "4 to 6": group 1 is the low end, group 2 the optional high end.
    private static let rangePattern = #"(\d+)(?:\s*(?:-|to|or)\s*(\d+))?"#

    // NSRegularExpression matching is thread-safe and the rules are immutable.
    nonisolated(unsafe) private static let frequencyRules: [FrequencyRule] = [
        // "every 3 days", "every 2-3 weeks", "every week", "every 4 to 6 weeks"
        FrequencyRule(
            regex: try! NSRegularExpression(pattern: #"\bevery\s+(?:"# + rangePattern + #"\s*)?(day|week|month)s?\b"#),
            resolve: { match, text in
                let low = int(match, 1, text) ?? 1
                let high = int(match, 2, text) ?? low
                guard let unit = string(match, 3, text) else { return nil }
                return fromInterval(max(low, high), unit: unit)
            }
        ),
        // "2-3 times weekly", "1 times a week" (from "once a week"), "2 times per day"
        FrequencyRule(
            regex: try! NSRegularExpression(
                pattern: rangePattern + #"\s*times?\s*(?:(?:a|per|each|every)\s+)?(day|week|month|daily|weekly|monthly)\b"#
            ),
            resolve: { match, text in
                guard let low = int(match, 1, text), let period = string(match, 3, text) else { return nil }
                let count = max(min(low, int(match, 2, text) ?? low), 1)
                let periodDays: Double
                switch period {
                case "day", "daily": periodDays = 1
                case "week", "weekly": periodDays = 7
                default: periodDays = 30
                }
                let days = Int((periodDays / Double(count)).rounded())
                return fromDays(max(days, 1))
            }
        ),
        // Bare cadence words. "biweekly" is listed first so it wins over "weekly".
        FrequencyRule(
            regex: try! NSRegularExpression(pattern: #"\b(biweekly|daily|weekly|monthly)\b"#),
            resolve: { match, text in
                switch string(match, 1, text) {
                case "daily": return .daily
                case "weekly": return .weekly
                case "biweekly": return .biweekly
                case "monthly": return .monthly
                default: return nil
                }
            }
        ),
    ]

    // MARK: - Helpers

    /// Lowercases, folds dash variants to "-", and turns words into digits so
    /// the rules above only have to handle one spelling.
    private static func normalizeFrequency(_ raw: String) -> String {
        var text = raw.lowercased()
        for dash in ["–", "—", "‑", "−"] { text = text.replacingOccurrences(of: dash, with: "-") }
        let replacements: [(String, String)] = [
            (#"\bbi-weekly\b"#, "biweekly"),
            (#"\bfortnightly\b"#, "biweekly"),
            (#"\bevery other\b"#, "every 2"),
            (#"\b(?:a )?couple(?: of)?\b"#, "2"),
            (#"\b(?:a )?few\b"#, "3"),
            (#"\bonce\b"#, "1 times"),
            (#"\btwice\b"#, "2 times"),
            (#"\bthrice\b"#, "3 times"),
            (#"\bone\b"#, "1"), (#"\btwo\b"#, "2"), (#"\bthree\b"#, "3"),
            (#"\bfour\b"#, "4"), (#"\bfive\b"#, "5"), (#"\bsix\b"#, "6"),
            (#"\bseven\b"#, "7"), (#"\beight\b"#, "8"), (#"\bten\b"#, "10"),
        ]
        for (pattern, replacement) in replacements {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return text
    }

    private static func fromInterval(_ n: Int, unit: String) -> TaskRecurrence? {
        switch unit {
        case "day": return fromDays(n)
        case "week": return fromDays(n * 7)
        case "month": return n == 1 ? .monthly : fromDays(n * 30)
        default: return nil
        }
    }

    private static func fromDays(_ days: Int) -> TaskRecurrence? {
        switch days {
        case ...0, 366...: return nil
        case 1: return .daily
        case 7: return .weekly
        case 14: return .biweekly
        default: return .everyNDays(days)
        }
    }

    private static func string(_ match: NSTextCheckingResult, _ group: Int, _ text: String) -> String? {
        let r = match.range(at: group)
        guard r.location != NSNotFound, let range = Range(r, in: text) else { return nil }
        return String(text[range])
    }

    private static func int(_ match: NSTextCheckingResult, _ group: Int, _ text: String) -> Int? {
        string(match, group, text).flatMap(Int.init)
    }
}
