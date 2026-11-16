import SwiftUI

struct Topic: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let grades: ClosedRange<Int>
    let strand: String
}

struct Question: Codable {
    let prompt: String
    let choices: [String]
    let answer: String
    let hint: String
    let story: String
    let operands: [Int]
    let operators: [String]
    let numberTiles: [Int]
    let fractionNumerator: Int?
    let fractionDenominator: Int?
    /// Shown after the player answers, to explain the correct answer.
    var explanation: String? = nil
    /// A question-specific visual. Nil means the question has no meaningful visual.
    var visual: QuestionVisual? = nil
    /// Why a particular wrong choice is wrong, keyed by the choice text. Shown once the solution is revealed.
    var choiceFeedback: [String: String]? = nil
    /// Ordered solution steps, each already checked against the question's numbers. Nil when the
    /// question type has no reliable step list; the UI then shows `explanation` only.
    var steps: [String]? = nil
    /// An illustrative worked example, one line per entry. Only set when clearly labelled as an example.
    var example: String? = nil
    /// A one-line rule or key idea to remember.
    var reminder: String? = nil
}

/// Question-specific visuals. Each case carries its own data, so a visual is only
/// ever shown for the question that generated it.
enum QuestionVisual: Codable, Equatable {
    /// Compares a biased sample with the whole population. Shown only after the answer,
    /// because the comparison explains the correct answer.
    case surveyComparison(SurveyChart)
    /// How often each value appears in a data set. Used for mode questions.
    case frequencyChart(FrequencyChart)
    /// A 10 x 10 grid where each square is 1% of a whole. Used for percent questions.
    case hundredGrid(HundredGrid)

    /// Whether the visual must wait until the student has submitted an answer.
    var revealsAfterAnswer: Bool {
        switch self {
        case .surveyComparison, .frequencyChart, .hundredGrid: return true
        }
    }

    /// False when the data cannot support an accurate display; the UI then hides the visual.
    var isValid: Bool {
        switch self {
        case .surveyComparison(let chart): return chart.isValid
        case .frequencyChart(let chart): return chart.isValid
        case .hundredGrid(let grid): return grid.isValid
        }
    }
}

/// A 100-square model. `highlighted` squares show one part; the rest show the remaining part of the whole.
struct HundredGrid: Codable, Equatable {
    let title: String
    let highlighted: Int
    let highlightLabel: String
    let remainderLabel: String

    var isValid: Bool { (0...100).contains(highlighted) && !highlightLabel.isEmpty && !remainderLabel.isEmpty }
}

/// Tracks the attempts on one question. The first attempt decides XP and the recorded result;
/// guided retries after it give practice only and never add XP or a second record.
struct AnswerAttempts: Equatable {
    enum Outcome: Equatable {
        case firstTryCorrect      // award XP, record a correct answer
        case correctAfterRetry    // practice only: no XP, no second record
        case wrongCanRetry        // show the guided hint, offer Try Again or Show Solution
        case wrongFinal           // no attempts left: reveal the full solution
    }

    /// Wrong answers that may be followed by a guided retry. 0 turns guided retry off.
    static let retriesAllowed = 1

    private(set) var wrongCount = 0

    /// True while a guided retry is on offer after a wrong answer.
    var canRetry: Bool { wrongCount > 0 && wrongCount <= Self.retriesAllowed }

    mutating func submit(correct: Bool) -> Outcome {
        if correct { return wrongCount == 0 ? .firstTryCorrect : .correctAfterRetry }
        wrongCount += 1
        return wrongCount > Self.retriesAllowed ? .wrongFinal : .wrongCanRetry
    }
}

/// Counts of each distinct value in a data set. Labels are the formatted values shown to the student.
struct FrequencyChart: Codable, Equatable {
    struct Bar: Codable, Equatable {
        let label: String
        let count: Int
    }

    let title: String
    let bars: [Bar]

    /// Every bar has a positive count and a unique label, and the labels are not empty.
    var isValid: Bool {
        !bars.isEmpty
            && bars.allSatisfy { $0.count > 0 && !$0.label.isEmpty }
            && Set(bars.map(\.label)).count == bars.count
    }
}

/// A 100% stacked-bar survey chart. Each group's percents must add up to 100,
/// and `percents` lines up with `categories`.
struct SurveyChart: Codable, Equatable {
    struct Group: Codable, Equatable {
        let name: String
        let percents: [Int]
    }

    let title: String
    let categories: [String]
    let groups: [Group]

    /// Every group has one non-negative percent per category, and each group totals exactly 100.
    var isValid: Bool {
        !categories.isEmpty && !groups.isEmpty && groups.allSatisfy { group in
            group.percents.count == categories.count
                && group.percents.allSatisfy { $0 >= 0 }
                && group.percents.reduce(0, +) == 100
        }
    }
}

struct ShopCharacter: Identifiable {
    let id: String
    let emoji: String
    let price: Int
    let description: String

    var abilityBonusXP: Int {
        if price >= 500 { return 3 }
        if price >= 350 { return 2 }
        return 1
    }

    var abilityDescription: String {
        switch id {
        case "Maple": return "+1 XP every 3rd solved challenge"
        case "Pip": return "+1 XP on number challenges"
        case "Nova": return "+1 XP on Grade 7 and up"
        case "Cedar": return "+1 XP on measurement challenges"
        case "Comet": return "+1 XP every 5th solved challenge"
        case "Mochi": return "+1 XP on fraction challenges"
        case "Waddles": return "+1 XP on data challenges"
        case "Bubbles": return "+1 XP on shape challenges"
        case "Thistle": return "+1 XP on algebra challenges"
        case "Shellby": return "+1 XP on probability challenges"
        case "Sunny": return "+1 XP on money challenges"
        case "Sprinkles": return "+1 XP on decimals and percent challenges"
        case "Byte": return "+1 XP on coding challenges"
        case "Puddle": return "+1 XP on graph challenges"
        case "Acorn": return "+1 XP on place-value challenges"
        case "Orbit": return "+1 XP on modelling challenges"
        case "Coral": return "+1 XP on transformation challenges"
        case "Frost": return "+1 XP on Grade 9 and up"
        case "Peaches": return "+1 XP for a correct review answer"
        case "Zigzag": return "+1 XP on Grades 1–3"
        case "Poppy": return "+1 XP on every other data challenge"
        case "Moss": return "+1 XP on budgeting challenges"
        case "Tango": return "+1 XP on every other shape challenge"
        case "Rumble": return "+1 XP on Grade 6+ number challenges"
        case "Lumi": return "+1 XP on Grade 6+ transformation challenges"
        case "Marbles": return "+1 XP while a potion is active"
        case "Pixel": return "+1 XP every 10th solved challenge"
        default: return "A cheerful trail companion"
        }
    }
}

struct TopicAnswerStats {
    var correct = 0
    var incorrect = 0
}

struct ReviewChallenge: Codable, Identifiable {
    var id: UUID
    var topicID: String
    var grade: Int
    var question: Question
    var missedAt: Date
}

struct GameBadge: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let rewardXP: Int
}

enum GameBadgeCatalog {
    static let core: [GameBadge] = [
        .init(id:"first_win",title:"First Spark",description:"Answer your first question correctly.",icon:"sparkle",rewardXP:20),
        .init(id:"streak_10",title:"Ten in a Row",description:"Answer 10 questions correctly in a row.",icon:"flame.fill",rewardXP:100),
        .init(id:"streak_25",title:"Unstoppable",description:"Answer 25 questions correctly in a row.",icon:"bolt.fill",rewardXP:300),
        .init(id:"solved_100",title:"Century Club",description:"Solve 100 questions.",icon:"star.circle.fill",rewardXP:200),
        .init(id:"xp_1000",title:"XP Collector",description:"Earn 1,000 XP in total.",icon:"sparkles",rewardXP:100),
        .init(id:"xp_5000",title:"XP Legend",description:"Earn 5,000 XP in total.",icon:"crown.fill",rewardXP:500),
        .init(id:"topics_5",title:"Curious Explorer",description:"Try questions in 5 different subjects.",icon:"map.fill",rewardXP:75),
        .init(id:"all_topics",title:"Trailblazer",description:"Try a question in every subject.",icon:"globe.americas.fill",rewardXP:400),
        .init(id:"review_win",title:"Comeback Kid",description:"Correctly answer a question from Review.",icon:"arrow.uturn.backward.circle.fill",rewardXP:50)
    ]
}
