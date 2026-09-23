import Foundation

@main
struct DurationParserTests {
    static func expectSuccess(_ input: String, _ expected: Int) {
        switch DurationParser.parse(input) {
        case .success(let actual) where actual == expected:
            return
        default:
            fputs("Expected \(input) to parse as \(expected) seconds.\n", stderr)
            exit(1)
        }
    }

    static func expectFailure(_ input: String) {
        if case .failure = DurationParser.parse(input) {
            return
        }
        fputs("Expected \(input) to be rejected.\n", stderr)
        exit(1)
    }

    static func main() {
        expectSuccess("15m", 900)
        expectSuccess("1.5h", 5400)
        expectSuccess("90s", 90)
        expectSuccess("45", 2700)
        expectFailure("1h later")
        expectFailure("0m")
        expectFailure("8d")
        expectFailure("1h 30m")
        print("DurationParser tests passed")
    }
}
