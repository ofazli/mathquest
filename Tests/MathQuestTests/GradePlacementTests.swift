import XCTest
@testable import MathQuest

final class GradePlacementTests: XCTestCase {
    private func topic(_ id: String) throws -> Topic {
        try XCTUnwrap(CurriculumCatalog.topics.first { $0.id == id })
    }

    func testGradeFiveDataNeverShowsTheSamplingBiasQuestion() throws {
        var generator = QuestionGenerator()
        let data = try topic("data")
        for _ in 0..<500 {
            let question = generator.makeQuestion(topic: data, grade: 5)
            XCTAssertNotEqual(question.prompt, SamplingBiasQuestion.prompt)
        }
    }

    func testGradeFiveNeverAsksPercentOfSurveyResponses() throws {
        var generator = QuestionGenerator()
        let data = try topic("data")
        for _ in 0..<500 {
            XCTAssertFalse(generator.makeQuestion(topic: data, grade: 5).prompt.contains("What percent answered yes"))
        }
    }

    func testPercentOfSurveyAppearsFromGradeSeven() throws {
        var generator = QuestionGenerator()
        let data = try topic("data")
        var seen = false
        for _ in 0..<500 where !seen {
            seen = generator.makeQuestion(topic: data, grade: 7).prompt.contains("What percent answered yes")
        }
        XCTAssertTrue(seen)
    }

    func testSamplingBiasQuestionAppearsFromGradeSeven() throws {
        var generator = QuestionGenerator()
        let data = try topic("data")
        var seen = false
        for _ in 0..<500 where !seen {
            seen = generator.makeQuestion(topic: data, grade: 7).prompt == SamplingBiasQuestion.prompt
        }
        XCTAssertTrue(seen, "the sampling-bias question should be available from Grade 7")
    }

    func testGradeOneFractionsAreOnlyHalvesAndFourths() throws {
        var generator = QuestionGenerator()
        let fractions = try topic("fractions")
        let allowed: Set<String> = ["1/2", "1/4", "one half"]
        for _ in 0..<300 {
            let question = generator.makeQuestion(topic: fractions, grade: 1)
            XCTAssertTrue(allowed.contains(question.answer), "unexpected Grade 1 answer \(question.answer)")
            XCTAssertEqual(Set(question.choices).count, question.choices.count)
        }
    }

    func testGradeFiveFairSampleQuestionHasOneCorrectAnswer() throws {
        var generator = QuestionGenerator()
        let data = try topic("data")
        for _ in 0..<200 {
            let question = generator.makeQuestion(topic: data, grade: 5)
            XCTAssertEqual(Set(question.choices).count, question.choices.count, "duplicate choice")
            XCTAssertEqual(question.choices.filter { $0 == question.answer }.count, 1)
        }
    }
}
