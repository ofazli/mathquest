import XCTest
@testable import MathQuest

final class SamplingBiasQuestionTests: XCTestCase {

    func testCorrectAnswerIsExactlyOneChoiceAfterRandomization() {
        // Shuffling must never drop, duplicate or rename the correct answer.
        for _ in 0..<100 {
            let question = SamplingBiasQuestion.make()
            XCTAssertEqual(question.choices.count, 4)
            XCTAssertEqual(Set(question.choices).count, 4, "choices must be distinct")
            XCTAssertEqual(question.choices.filter { $0 == SamplingBiasQuestion.correctAnswer }.count, 1)
            XCTAssertEqual(question.answer, SamplingBiasQuestion.correctAnswer)
            XCTAssertTrue(question.choices.contains(question.answer))
        }
    }

    func testDistractorsAreClearlyIncorrect() {
        for distractor in SamplingBiasQuestion.distractors {
            XCTAssertNotEqual(distractor, SamplingBiasQuestion.correctAnswer)
        }
        XCTAssertEqual(SamplingBiasQuestion.distractors.count, 3)
    }

    func testPromptHintAndExplanationArePresent() {
        let question = SamplingBiasQuestion.make()
        XCTAssertEqual(question.prompt, SamplingBiasQuestion.prompt)
        XCTAssertEqual(question.hint, SamplingBiasQuestion.hint)
        XCTAssertNotNil(question.explanation)
        // The hint must not state the answer outright.
        XCTAssertFalse(question.hint.contains("may be more likely to prefer"))
    }

    func testChartUsesIllustrativeValuesThatTotalOneHundredPerGroup() {
        let chart = SamplingBiasQuestion.chart
        XCTAssertEqual(chart.categories, ["Basketball", "Soccer", "Other"])
        XCTAssertEqual(chart.groups.map(\.percents), [[80, 15, 5], [30, 45, 25]])
        for group in chart.groups {
            XCTAssertEqual(group.percents.reduce(0, +), 100, "\(group.name) must total 100%")
        }
        XCTAssertTrue(chart.isValid)
    }

    func testVisualIsAttachedAndWaitsForAnswer() {
        let question = SamplingBiasQuestion.make()
        guard let visual = question.visual else { return XCTFail("visual missing") }
        XCTAssertTrue(visual.isValid)
        XCTAssertTrue(visual.revealsAfterAnswer, "the chart explains the answer, so it must not show before submission")
    }
}

final class SurveyChartValidationTests: XCTestCase {

    private func chart(_ groups: [[Int]], categories: Int = 3) -> SurveyChart {
        SurveyChart(
            title: "t",
            categories: Array(repeating: "c", count: categories),
            groups: groups.enumerated().map { .init(name: "g\($0.offset)", percents: $0.element) }
        )
    }

    func testRejectsGroupsThatDoNotTotalOneHundred() {
        XCTAssertFalse(chart([[50, 30, 10]]).isValid)
    }

    func testRejectsMismatchedCategoryCounts() {
        XCTAssertFalse(chart([[50, 50]]).isValid)
    }

    func testRejectsNegativePercents() {
        XCTAssertFalse(chart([[120, -10, -10]]).isValid)
    }

    func testRejectsEmptyCharts() {
        XCTAssertFalse(chart([]).isValid)
        XCTAssertFalse(SurveyChart(title: "t", categories: [], groups: []).isValid)
    }

    func testAcceptsValidChart() {
        XCTAssertTrue(chart([[40, 40, 20], [100, 0, 0]]).isValid)
    }
}

final class QuestionDecodingTests: XCTestCase {

    /// Saved review challenges from before `explanation` and `visual` existed must still decode.
    func testLegacyQuestionJSONDecodesWithoutNewFields() throws {
        let json = """
        {"prompt":"p","choices":["a","b"],"answer":"a","hint":"h","story":"s",
         "operands":[],"operators":[],"numberTiles":[],"fractionNumerator":null,"fractionDenominator":null}
        """
        let question = try JSONDecoder().decode(Question.self, from: Data(json.utf8))
        XCTAssertNil(question.explanation)
        XCTAssertNil(question.visual)
    }

    func testQuestionWithVisualRoundTrips() throws {
        let original = SamplingBiasQuestion.make()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Question.self, from: data)
        XCTAssertEqual(decoded.visual, original.visual)
        XCTAssertEqual(decoded.explanation, original.explanation)
        XCTAssertEqual(decoded.answer, original.answer)
    }
}
