import Foundation

struct DurationParseError: Error {
    let message: String
}

enum DurationParser {
    static let defaultDuration = 30 * 60
    static let maximumDuration = 7 * 24 * 60 * 60

    static func parse(_ argument: String) -> Result<Int, DurationParseError> {
        let input = argument.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^([0-9]+(?:\\.[0-9]+)?)(h|m|s)?$"

        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: input,
                range: NSRange(input.startIndex..., in: input)
              ),
              let numberRange = Range(match.range(at: 1), in: input),
              let value = Double(input[numberRange]),
              value.isFinite else {
            return .failure(DurationParseError(message: "時間は 15m、1h、90s のように指定してください。"))
        }

        let unit: String
        if match.range(at: 2).location == NSNotFound {
            unit = "m"
        } else if let unitRange = Range(match.range(at: 2), in: input) {
            unit = String(input[unitRange])
        } else {
            return .failure(DurationParseError(message: "時間の単位を解釈できませんでした。"))
        }

        let seconds: Double
        switch unit {
        case "h": seconds = value * 3600
        case "m": seconds = value * 60
        case "s": seconds = value
        default: return .failure(DurationParseError(message: "時間の単位は h、m、s のいずれかです。"))
        }

        guard seconds > 0, seconds <= Double(maximumDuration) else {
            return .failure(DurationParseError(message: "時間は1秒以上、7日以内で指定してください。"))
        }
        return .success(Int(seconds))
    }
}
