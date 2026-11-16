import XCTest
@testable import MathQuest

final class PercentQuestionTests: XCTestCase {
    private let generator = QuestionGenerator()

    /// Every total and percent the generator can use, including the 75-out-of-100 case from the request.
    private var cases: [(count: Int, total: Int, percent: Int)] {
        [20, 40, 100].flatMap { total in
            [10, 20, 25, 50, 75].map { percent in (total * percent / 100, total, percent) }
        }
    }

    func testAnswerIsTheExactPercentAndStepsAgreeWithIt() {
        for (count, total, percent) in cases {
            XCTAssertEqual(count * 100, percent * total, "data must give an exact percent")
            let question = generator.percentOfTotalQuestion(count: count, total: total, percent: percent)
            XCTAssertEqual(question.answer, String(percent))
            let steps = question.steps ?? []
            XCTAssertEqual(steps.count, 3)
            XCTAssertTrue(steps.contains("Write the fraction: \(count) / \(total)"), "\(count)/\(total)")
            XCTAssertTrue(steps.contains("Convert to a percent: (\(count) / \(total)) × 100 = \(percent)%"))
        }
    }

    func testSpecExampleSeventyFiveOutOfOneHundred() {
        let question = generator.percentOfTotalQuestion(count: 75, total: 100, percent: 75)
        XCTAssertEqual(question.answer, "75")
        XCTAssertEqual(question.steps?[0], "Identify the values: 75 people answered \"Yes\" out of 100 people.")
        XCTAssertEqual(question.steps?[2], "Convert to a percent: (75 / 100) × 100 = 75%")
        XCTAssertEqual(question.hint, "If 75 out of 100 people answered yes, how many out of every 100 answered yes?")
    }

    func testChoicesAreDistinctAndContainTheAnswerOnce() {
        for (count, total, percent) in cases {
            let question = generator.percentOfTotalQuestion(count: count, total: total, percent: percent)
            XCTAssertEqual(question.choices.count, 4)
            XCTAssertEqual(Set(question.choices).count, 4, "duplicate choice for \(count)/\(total)")
            XCTAssertEqual(question.choices.filter { $0 == question.answer }.count, 1)
            // Every misconception feedback belongs to a wrong choice, never to the answer.
            let feedbackKeys = Set((question.choiceFeedback ?? [:]).keys)
            XCTAssertTrue(feedbackKeys.isSubset(of: Set(question.choices).subtracting([question.answer])))
        }
    }

    func testGridHighlightsExactlyThePercentOfOneHundredSquares() throws {
        for (count, total, percent) in cases {
            let question = generator.percentOfTotalQuestion(count: count, total: total, percent: percent)
            guard case .hundredGrid(let grid) = try XCTUnwrap(question.visual) else {
                return XCTFail("percent questions need a hundred grid")
            }
            XCTAssertTrue(grid.isValid)
            XCTAssertEqual(grid.highlighted, percent)
            XCTAssertTrue(grid.remainderLabel.contains("\(100 - percent)%"))
            XCTAssertTrue(grid.highlightLabel.contains("\(percent)%"))
        }
    }

    func testNumberBoardEquationGivesTheAnswer() {
        for (count, total, percent) in cases {
            let question = generator.percentOfTotalQuestion(count: count, total: total, percent: percent)
            XCTAssertEqual(question.operands, [count, 100, total])
            XCTAssertEqual(question.operators, ["×", "÷"])
            let value = QuestionGenerator.evaluateBoardExpression(numbers: question.operands.map(Double.init), operators: question.operators)
            XCTAssertEqual(value, Double(percent))
        }
    }

    func testGridRejectsOutOfRangeValues() {
        XCTAssertFalse(HundredGrid(title: "t", highlighted: 101, highlightLabel: "a", remainderLabel: "b").isValid)
        XCTAssertFalse(HundredGrid(title: "t", highlighted: -1, highlightLabel: "a", remainderLabel: "b").isValid)
        XCTAssertTrue(HundredGrid(title: "t", highlighted: 0, highlightLabel: "a", remainderLabel: "b").isValid)
    }
}

final class AnswerAttemptTests: XCTestCase {
    func testFirstTryCorrectAwardsXP() {
        var attempts = AnswerAttempts()
        XCTAssertEqual(attempts.submit(correct: true), .firstTryCorrect)
    }

    func testWrongThenRetryCorrectIsPracticeOnly() {
        var attempts = AnswerAttempts()
        XCTAssertEqual(attempts.submit(correct: false), .wrongCanRetry)
        XCTAssertTrue(attempts.canRetry)
        XCTAssertEqual(attempts.submit(correct: true), .correctAfterRetry)
    }

    func testSecondWrongAnswerEndsWithFullSolution() {
        var attempts = AnswerAttempts()
        _ = attempts.submit(correct: false)
        XCTAssertEqual(attempts.submit(correct: false), .wrongFinal)
        XCTAssertFalse(attempts.canRetry, "no retries after the allowed attempts")
        XCTAssertEqual(attempts.wrongCount, 2)
    }

    func testRetryLimitIsOneAndStated() {
        XCTAssertEqual(AnswerAttempts.retriesAllowed, 1)
    }

    func testOutcomeOnlyDependsOnTheFirstAttemptForXP() {
        // A question that is wrong first and right later must never give the first-try outcome.
        var attempts = AnswerAttempts()
        _ = attempts.submit(correct: false)
        XCTAssertNotEqual(attempts.submit(correct: true), .firstTryCorrect)
    }
}

final class NumberBoardEvaluationTests: XCTestCase {
    private func evaluate(_ numbers: [Double], _ operators: [String]) -> Double? {
        QuestionGenerator.evaluateBoardExpression(numbers: numbers, operators: operators)
    }

    func testMultiplicationAndDivisionRunLeftToRight() {
        XCTAssertEqual(evaluate([75, 100, 100], ["÷", "×"]), 75)
        XCTAssertEqual(evaluate([75, 100, 100], ["×", "÷"]), 75)
    }

    func testMultiplicationBeforeAddition() {
        XCTAssertEqual(evaluate([2, 3, 4], ["+", "×"]), 14)
        XCTAssertEqual(evaluate([10, 2, 3], ["−", "×"]), 4)
    }

    func testPowersBeforeMultiplicationAndAreRightAssociative() {
        XCTAssertEqual(evaluate([2, 3, 2], ["^", "^"]), 512, "2^(3^2)")
        XCTAssertEqual(evaluate([2, 3, 2], ["×", "^"]), 18, "2 × 3^2")
    }

    func testInvalidExpressionsAreRejected() {
        XCTAssertNil(evaluate([10, 0], ["÷"]), "division by zero")
        XCTAssertNil(evaluate([1, 2], ["+", "+"]), "operator count must be one less than the numbers")
        XCTAssertNil(evaluate([], []))
        XCTAssertNil(evaluate([1, 2], ["?"]), "unknown operator")
    }
}
