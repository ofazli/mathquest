import XCTest
@testable import MathQuest

final class SolutionStepsTests: XCTestCase {

    func testMultiplicationComesBeforeAddition() {
        XCTAssertEqual(QuestionGenerator.solutionSteps(numbers: [12, 3, 5], operators: ["+", "×"]),
                       ["3 × 5 = 15", "12 + 15 = 27"])
    }

    func testPowersRunRightToLeft() {
        XCTAssertEqual(QuestionGenerator.solutionSteps(numbers: [2, 3, 2], operators: ["^", "^"]),
                       ["3 ^ 2 = 9", "2 ^ 9 = 512"])
    }

    func testDecimalResultsShowTwoPlacesWithoutTrailingZeros() {
        XCTAssertEqual(QuestionGenerator.solutionSteps(numbers: [7, 2], operators: ["÷"]), ["7 ÷ 2 = 3.5"])
        XCTAssertEqual(QuestionGenerator.decimalText(2.5), "2.5")
        XCTAssertEqual(QuestionGenerator.decimalText(2.25), "2.25")
        XCTAssertEqual(QuestionGenerator.decimalText(4.0), "4")
    }

    func testInvalidExpressionsGiveNoSteps() {
        XCTAssertNil(QuestionGenerator.solutionSteps(numbers: [10, 0], operators: ["÷"]))
        XCTAssertNil(QuestionGenerator.solutionSteps(numbers: [1, 2], operators: ["+", "+"]))
    }

    /// Every calculation question the app can generate: if it has steps, the last step must reach the answer.
    func testEveryGeneratedStepListEndsAtTheAnswer() {
        var generator = QuestionGenerator()
        var checked = 0
        for topic in CurriculumCatalog.topics {
            for grade in topic.grades {
                for _ in 0..<20 {
                    let question = generator.makeQuestion(topic: topic, grade: grade)
                    guard let steps = question.steps, let last = steps.last else { continue }
                    checked += 1
                    let finalText = (last.components(separatedBy: " = ").last ?? "").replacingOccurrences(of: "%", with: "")
                    XCTAssertEqual(Double(finalText), Double(question.answer),
                                   "steps end at \(finalText) but the answer is \(question.answer): \(question.prompt)")
                    XCTAssertFalse(steps.isEmpty)
                }
            }
        }
        XCTAssertGreaterThan(checked, 0, "some generated questions should carry verified steps")
    }

    func testPercentStepsAreArithmeticallyCorrect() {
        for (count, total, percent) in [(75, 100, 75), (10, 40, 25), (2, 20, 10)] {
            let question = QuestionGenerator().percentOfTotalQuestion(count: count, total: total, percent: percent)
            XCTAssertEqual(question.steps?.count, 3)
            XCTAssertEqual(Double(count) / Double(total) * 100, Double(percent))
            XCTAssertNotNil(question.explanation)
            XCTAssertEqual(question.reminder, "Percent means \"out of 100\".")
        }
    }

    func testRelativeFrequencyExampleArithmeticIsCorrect() throws {
        var generator = QuestionGenerator()
        let dataTopic = try XCTUnwrap(CurriculumCatalog.topics.first { $0.id == "data" })
        var found: Question?
        for _ in 0..<2000 where found == nil {
            let question = generator.makeQuestion(topic: dataTopic, grade: 5)
            if question.prompt == "Which table entry is a relative frequency?" { found = question }
        }
        let question = try XCTUnwrap(found, "the relative frequency question should be generated")
        XCTAssertEqual(question.answer, "The category count divided by the total, often shown as a fraction or percent")
        XCTAssertEqual(8.0 / 20.0, 0.4)
        XCTAssertTrue(try XCTUnwrap(question.example).contains("8 ÷ 20 = 0.4 = 40%"))
        XCTAssertTrue(try XCTUnwrap(question.example).contains("Illustrative example"))
        XCTAssertNil(question.steps, "a concept question does not invent calculation steps")
    }
}
