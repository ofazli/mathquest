import XCTest
import Foundation
@testable import MathQuest

final class DecimalFormattingTests: XCTestCase {
    private let generator = QuestionGenerator()

    func testTenthsKeepOneDecimalAndTrimNothingMeaningful() {
        XCTAssertEqual(generator.formatDecimal(0.7, maxPlaces: 1, minPlaces: 1), "0.7")
        XCTAssertEqual(generator.formatDecimal(2.0, maxPlaces: 1, minPlaces: 1), "2.0")
    }

    func testMoneyKeepsTwoDecimals() {
        XCTAssertEqual(generator.formatDecimal(2.5, maxPlaces: 2, minPlaces: 2), "2.50")
        XCTAssertEqual(generator.formatDecimal(2.0, maxPlaces: 2, minPlaces: 2), "2.00")
    }

    func testExtraZerosAreTrimmedWhenMinimumAllows() {
        XCTAssertEqual(generator.formatDecimal(0.7, maxPlaces: 2, minPlaces: 0), "0.7")
        XCTAssertEqual(generator.formatDecimal(3.0, maxPlaces: 2, minPlaces: 0), "3")
        XCTAssertEqual(generator.formatDecimal(2.25, maxPlaces: 2, minPlaces: 0), "2.25")
    }

    func testNoFloatingPointNoiseInDisplay() {
        // 0.1 + 0.2 is not exactly 0.3 in binary floating point; the display must still be "0.3".
        XCTAssertEqual(generator.formatDecimal(0.1 + 0.2, maxPlaces: 1, minPlaces: 1), "0.3")
    }
}

final class ModeQuestionTests: XCTestCase {
    private let generator = QuestionGenerator()

    /// The example from the request: 0.7 appears three times, 1.5 twice, 2.3 and 3.1 once.
    func testSpecExampleHasSingleCorrectAnswerAndDataBasedDistractors() throws {
        let question = try XCTUnwrap(generator.modeQuestion(values: [15, 7, 15, 7, 23, 7, 31], places: 1, story: "s"))
        XCTAssertEqual(question.answer, "0.7")
        XCTAssertEqual(Set(question.choices), ["0.7", "1.5", "2.3", "3.1"])
        XCTAssertEqual(question.choices.count, 4)
        XCTAssertEqual(question.prompt, "Find the mode of 1.5, 0.7, 1.5, 0.7, 2.3, 0.7, 3.1.")
    }

    func testExampleExplanationStatesTheCounts() throws {
        let question = try XCTUnwrap(generator.modeQuestion(values: [15, 7, 15, 7, 23, 7, 31], places: 1, story: "s"))
        let explanation = try XCTUnwrap(question.explanation)
        XCTAssertTrue(explanation.contains("0.7 appears 3 times"))
        XCTAssertTrue(explanation.contains("1.5 appears 2 times"))
        XCTAssertTrue(explanation.contains("the mode is 0.7"))
    }

    func testEveryWrongChoiceHasFeedbackThatDoesNotCallItTheMode() throws {
        let question = try XCTUnwrap(generator.modeQuestion(values: [15, 7, 15, 7, 23, 7, 31], places: 1, story: "s"))
        let feedback = try XCTUnwrap(question.choiceFeedback)
        XCTAssertEqual(Set(feedback.keys), Set(question.choices).subtracting([question.answer]))
        for (_, feedback) in feedback {
            XCTAssertFalse(feedback.isEmpty)
        }
    }

    func testMeanMisconceptionIsIncludedWhenExactAndDistinct() throws {
        // Values 3.0, 3.0, 3.0, 5.0, 6.0: the mean is exactly 4.0 (20 / 5), which is not in the data.
        let question = try XCTUnwrap(generator.modeQuestion(values: [30, 30, 30, 50, 60], places: 1, story: "s"))
        XCTAssertTrue(question.choices.contains("4.0"))
        XCTAssertEqual(question.choiceFeedback?["4.0"]?.hasPrefix("That is the mean"), true)
    }

    func testNoSingleModeReturnsNil() {
        XCTAssertNil(generator.modeQuestion(values: [1, 1, 2, 2], places: 0, story: "s"), "a tie has no single mode")
        XCTAssertNil(generator.modeQuestion(values: [5, 5, 5], places: 0, story: "s"), "too few distinct values for three distractors")
    }

    func testRandomDecimalModeQuestionsAreValid() {
        for _ in 0..<300 {
            let question = generator.modeQuestionWithRetry(values: 2...25, places: 1, story: "s")
            assertModeQuestionIsValid(question, decimalPlaces: 1)
        }
    }

    func testRandomIntegerModeQuestionsAreValid() {
        for _ in 0..<300 {
            let question = generator.modeQuestionWithRetry(values: 2...9, places: 0, story: "s")
            assertModeQuestionIsValid(question, decimalPlaces: 0)
        }
    }

    private func assertModeQuestionIsValid(_ question: Question, decimalPlaces: Int, file: StaticString = #filePath, line: UInt = #line) {
        // Exactly one correct option, four distinct options after formatting.
        XCTAssertEqual(question.choices.count, 4, file: file, line: line)
        XCTAssertEqual(Set(question.choices).count, 4, "duplicate choice after formatting", file: file, line: line)
        XCTAssertEqual(question.choices.filter { $0 == question.answer }.count, 1, file: file, line: line)

        // Precision: answer and every choice use the question's decimal places, with no extra zeros.
        for choice in question.choices {
            XCTAssertEqual(decimalDigits(choice), decimalPlaces, "\(choice) has the wrong precision", file: file, line: line)
        }

        // Distractors come from the data, or are the mean or median of the data.
        let values = dataValues(from: question)
        XCTAssertNotNil(values, file: file, line: line)
        guard let values else { return }
        let display: (Int) -> String = { self.generator.formatDecimal(Double($0) / pow(10, Double(decimalPlaces)), maxPlaces: decimalPlaces, minPlaces: decimalPlaces) }
        var counts: [Int: Int] = [:]
        values.forEach { counts[$0, default: 0] += 1 }
        let top = counts.values.max() ?? 0
        let mode = counts.keys.first { counts[$0] == top }!
        XCTAssertEqual(question.answer, display(mode), "the answer must be the most frequent value", file: file, line: line)

        let sorted = values.sorted()
        var allowed = Set(counts.keys.map(display))
        if values.reduce(0, +) % values.count == 0 { allowed.insert(display(values.reduce(0, +) / values.count)) }
        if values.count % 2 == 1 { allowed.insert(display(sorted[values.count / 2])) }
        for choice in question.choices {
            XCTAssertTrue(allowed.contains(choice), "\(choice) is not from the data, mean or median", file: file, line: line)
        }

        // The chart must match the data exactly.
        guard case .frequencyChart(let chart) = question.visual else {
            return XCTFail("mode question needs a frequency chart", file: file, line: line)
        }
        XCTAssertTrue(chart.isValid, file: file, line: line)
        XCTAssertEqual(chart.bars.reduce(0) { $0 + $1.count }, values.count, file: file, line: line)
        for bar in chart.bars {
            let key = counts.keys.first { display($0) == bar.label }
            XCTAssertEqual(key.flatMap { counts[$0] }, bar.count, "bar \(bar.label)", file: file, line: line)
        }
        XCTAssertTrue(question.explanation?.contains("most often") ?? false, file: file, line: line)
    }

    /// Recovers the scaled data values from the chart, which lists every distinct value with its count.
    private func dataValues(from question: Question) -> [Int]? {
        guard case .frequencyChart(let chart) = question.visual else { return nil }
        let places = decimalDigits(question.answer)
        let scale = pow(10.0, Double(places))
        return chart.bars.flatMap { bar -> [Int] in
            let value = Int((Double(bar.label) ?? 0) * scale).magnitude
            return Array(repeating: Int(value), count: bar.count)
        }
    }

    private func decimalDigits(_ text: String) -> Int {
        guard let dot = text.firstIndex(of: ".") else { return 0 }
        return text.distance(from: text.index(after: dot), to: text.endIndex)
    }
}
