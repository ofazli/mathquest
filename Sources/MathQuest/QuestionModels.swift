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
