import SwiftUI
import Charts


private struct PieWedge: Shape {
    let startAngle: Double
    let endAngle: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: .degrees(startAngle), endAngle: .degrees(endAngle), clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct FractionCircleView: View {
    let numerator: Int
    let denominator: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<max(1, denominator), id: \.self) { part in
                let start = -90 + Double(part) * 360 / Double(max(1, denominator))
                let end = -90 + Double(part + 1) * 360 / Double(max(1, denominator))
                PieWedge(startAngle: start, endAngle: end)
                    .fill(part < numerator ? Color(red: 0.99, green: 0.64, blue: 0.31) : .white)
                    .overlay(PieWedge(startAngle: start, endAngle: end).stroke(.white, lineWidth: 1.2))
            }
            Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1)
        }
        .frame(width: size, height: size)
    }
}

struct ContentView: View {
    private var topics: [Topic] { CurriculumCatalog.topics }
    private var shopCharacters: [ShopCharacter] { CurriculumCatalog.shopCharacters }
    @AppStorage("mathquest.appearance") private var appearance = "Light"
    private var isDarkAppearance: Bool { appearance == "Dark" }
    private var ink: Color { isDarkAppearance ? Color(red:0.91,green:0.93,blue:0.97) : Color(red:0.12,green:0.16,blue:0.24) }
    private var paper: Color { isDarkAppearance ? Color(red:0.09,green:0.11,blue:0.15) : Color(red:0.965,green:0.96,blue:0.93) }
    private var surface: Color { isDarkAppearance ? Color(red:0.15,green:0.18,blue:0.23) : .white }
    private var sidebarSurface: Color { isDarkAppearance ? Color(red:0.12,green:0.14,blue:0.19) : Color(red:0.94,green:0.93,blue:0.89) }
    private var buttonFill: Color { Color(red:0.12,green:0.16,blue:0.24) }
    private var boardPanelSurface: Color { isDarkAppearance ? Color(red:0.11,green:0.13,blue:0.18) : Color(red:0.99,green:0.99,blue:0.97) }
    private var numberBoardSurface: Color { isDarkAppearance ? Color(red:0.16,green:0.21,blue:0.22) : Color(red:0.91,green:0.95,blue:0.91) }
    private var fractionBoardSurface: Color { isDarkAppearance ? Color(red:0.22,green:0.16,blue:0.22) : Color(red:0.97,green:0.91,blue:0.95) }
    private var numberTileSurface: Color { isDarkAppearance ? Color(red:0.35,green:0.31,blue:0.20) : Color(red:1,green:0.88,blue:0.55) }
    private var slotValueSurface: Color { isDarkAppearance ? Color(red:0.22,green:0.28,blue:0.37) : Color(red:0.89,green:0.94,blue:0.99) }

    @State private var selectedTab = "Home"
    @State private var grade = 3
    @State private var selectedProfileTopicID = "number"
    @State private var selectedTopic: Topic?
    @State private var question: Question?
    @State private var selectedAnswer: String?
    @State private var answered = false
    @State private var showHint = false
    @State private var boardAnswer: String?
    @State private var boardValues: [Int?] = []
    @State private var boardOperators: [String?] = []
    @State private var selectedBoardTile: String?
    @State private var fractionPreview: String?
    @State private var fractionPieces: Set<Int> = []
    @State private var showBoardFeedback = false
    @AppStorage("mathquest.solvedChallenges") private var score = 0
    @AppStorage("mathquest.dayStreak") private var streak = 0
    @AppStorage("mathquest.correctAnswerStreak") private var correctAnswerStreak = 0
    @AppStorage("mathquest.topicCorrectStreaks") private var topicCorrectStreakData = ""
    @AppStorage("mathquest.topicsAttempted") private var topicsAttemptedData = ""
    @AppStorage("mathquest.earnedBadges") private var earnedBadgeData = ""
    @AppStorage("mathquest.totalXPEarned") private var totalXPEarned = 0
    @AppStorage("mathquest.topicWins") private var topicWinsData = ""
    @AppStorage("mathquest.topicAnswerStats") private var topicAnswerStatsData = ""
    @AppStorage("mathquest.reviewChallenges") private var reviewChallengeData = "[]"
    @State private var round = 0
    @State private var questionGenerator = QuestionGenerator()
    @State private var activeReviewChallengeID: UUID?
    @State private var newlyUnlockedBadgeMessage: String?
    @State private var insufficientXPMessage = ""
    @State private var showInsufficientXPAlert = false
    @State private var showParent = false
    @AppStorage("mathquest.xp") private var xp = 120
    @AppStorage("mathquest.ownedCharacters") private var ownedCharacterIDs = "Maple"
    @AppStorage("mathquest.activeCharacter") private var activeCharacterID = "Maple"
    @AppStorage("mathquest.potionInventory") private var potionInventory = 0
    @AppStorage("mathquest.doubleXPExpiry") private var doubleXPExpiry = 0.0
    @AppStorage("mathquest.quadruplePotionInventory") private var quadruplePotionInventory = 0
    @AppStorage("mathquest.quadrupleXPExpiry") private var quadrupleXPExpiry = 0.0
    @AppStorage("mathquest.enabledTopics") private var enabledTopicIDs = CurriculumCatalog.topics.map(\.id).joined(separator:",")

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            ZStack {
                paper.ignoresSafeArea()
                if let question { gameView(question) }
                else if selectedTab == "Map" { mapView }
                else if selectedTab == "Review" { reviewView }
                else if selectedTab == "Profile" { progressView }
                else if selectedTab == "Shop" { shopView }
                else if selectedTab == "Inventory" { inventoryView }
                else if selectedTab == "Settings" { settingsView }
                else { homeView }
            }
            .overlay(alignment:.topTrailing) {
                VStack(alignment:.trailing,spacing:8) {
                    if let message=newlyUnlockedBadgeMessage { badgeToast(message).transition(.move(edge:.top).combined(with:.opacity)) }
                    if question == nil { activePotionBadge }
                }
                .padding(.top,14).padding(.trailing,18)
                .allowsHitTesting(false)
                .task(id:newlyUnlockedBadgeMessage) {
                    guard newlyUnlockedBadgeMessage != nil else{return}
                    try? await Task.sleep(nanoseconds:4_000_000_000)
                    guard !Task.isCancelled else{return}
                    withAnimation(.easeOut(duration:0.25)) { newlyUnlockedBadgeMessage=nil }
                }
            }
        }
        .preferredColorScheme(isDarkAppearance ? .dark : .light)
        .onAppear { reconcileBadgeProgress() }
        .sheet(isPresented: $showParent) { parentSheet }
    }

    private func badgeToast(_ message:String)->some View {
        HStack(spacing:10) {
            Image(systemName:"rosette").font(.system(size:23,weight:.bold)).foregroundStyle(Color.orange)
            VStack(alignment:.leading,spacing:3) {
                Text("Badge unlocked!").font(.system(size:11,weight:.heavy)).foregroundStyle(ink)
                Text(message).font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary).lineLimit(3)
            }
        }
        .padding(.horizontal,13).padding(.vertical,11).frame(maxWidth:290,alignment:.leading)
        .background(surface,in:RoundedRectangle(cornerRadius:14))
        .overlay(RoundedRectangle(cornerRadius:14).stroke(Color.orange.opacity(0.3),lineWidth:1))
        .shadow(color:.black.opacity(0.12),radius:9,x:0,y:4)
        .accessibilityElement(children:.combine)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image("MathQuestMark")
                    .resizable()
                    .scaledToFill()
                    .frame(width:42,height:42)
                    .clipShape(RoundedRectangle(cornerRadius:13))
                    .overlay(RoundedRectangle(cornerRadius:13).stroke(Color.white.opacity(0.18),lineWidth:1))
                    .accessibilityHidden(true)
                VStack(alignment:.leading,spacing:0) { Text("MATH QUEST").font(.system(size:14,weight:.black,design:.rounded)).tracking(1.1); Text("CANADA EDITION").font(.system(size:9,weight:.bold,design:.rounded)).tracking(1.5).foregroundStyle(.secondary) }
            }.padding(.bottom,28)
            ForEach([("Home","house.fill"),("Map","map.fill"),("Profile","person.crop.circle"),("Review","arrow.counterclockwise.circle.fill"),("Shop","bag.fill"),("Inventory","shippingbox.fill"),("Settings","gearshape.fill")],id:\.0) { item in
                Button { navigate(to: item.0) } label: {
                    HStack(spacing:13) { Image(systemName:item.1).frame(width:20); Text(item.0).font(.system(size:14,weight:.semibold)); Spacer(); if item.0 == "Review" && !reviewChallenges.isEmpty { Text("\(reviewChallenges.count)").font(.system(size:10,weight:.black)).padding(.horizontal,7).padding(.vertical,4).background(Color.orange.opacity(0.22),in:Capsule()) } }
                        .foregroundStyle(selectedTab == item.0 ? ink : Color.gray)
                        .padding(.horizontal,14).frame(maxWidth:.infinity,minHeight:46,alignment:.leading)
                        .background(selectedTab == item.0 ? surface : .clear, in: RoundedRectangle(cornerRadius:13))
                        .contentShape(RoundedRectangle(cornerRadius:13))
                }.buttonStyle(.plain).frame(maxWidth:.infinity).contentShape(Rectangle()).accessibilityIdentifier("nav-\(item.0.lowercased())").padding(.bottom,5)
            }
            HStack(spacing:10) {
                Image(systemName:"sparkles").foregroundStyle(Color.orange)
                VStack(alignment:.leading,spacing:2){Text("XP BALANCE").font(.system(size:9,weight:.heavy)).tracking(0.8).foregroundStyle(.secondary);Text("\(xp) XP").font(.system(size:17,weight:.black,design:.rounded)).foregroundStyle(ink)}
                Spacer(minLength:0)
            }.padding(12).frame(maxWidth:.infinity,alignment:.leading).background(surface.opacity(0.75),in:RoundedRectangle(cornerRadius:14)).padding(.top,9)
            Spacer()
            Button { showParent=true } label: {
                HStack(spacing:10) { Image(systemName:"person.crop.circle").font(.system(size:18)); VStack(alignment:.leading,spacing:2){Text("Grown-up corner").font(.system(size:12,weight:.bold));Text("Curriculum & settings").font(.system(size:10)).foregroundStyle(.secondary)} }
                    .foregroundStyle(ink).padding(12).frame(maxWidth:.infinity,alignment:.leading).background(surface.opacity(0.7),in:RoundedRectangle(cornerRadius:14))
            }.buttonStyle(.plain)
        }.padding(22).frame(width:225).background(sidebarSurface)
    }

    private var homeView: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:25) {
                HStack { VStack(alignment:.leading,spacing:5){Text("Hey, learner! 👋").font(.system(size:28,weight:.black,design:.rounded));Text("Ready for a little adventure?").font(.system(size:15)).foregroundStyle(.secondary)}; Spacer(); HStack(spacing:7){Image(systemName:"flame.fill").foregroundStyle(.orange);Text("\(streak) day streak").font(.system(size:13,weight:.bold))}.padding(.horizontal,13).padding(.vertical,10).background(surface,in:Capsule()) }
                hero
                HStack {
                    Text("Pick your playground").font(.system(size:20,weight:.black,design:.rounded))
                    Spacer()
                    Text("YOUR GRADE").font(.system(size:9,weight:.heavy)).tracking(1).foregroundStyle(.secondary)
                    HStack(spacing:10) {
                        Button { grade=max(1,grade-1) } label:{Image(systemName:"minus").font(.system(size:10,weight:.black)).frame(width:27,height:27).background(Color.black.opacity(0.06),in:Circle())}.buttonStyle(.plain).disabled(grade <= 1)
                        Text("Grade \(grade)").font(.system(size:13,weight:.black,design:.rounded)).foregroundStyle(ink).frame(minWidth:58)
                        Button { grade=min(12,grade+1) } label:{Image(systemName:"plus").font(.system(size:10,weight:.black)).frame(width:27,height:27).background(Color.black.opacity(0.06),in:Circle())}.buttonStyle(.plain).disabled(grade >= 12)
                    }.padding(.horizontal,9).padding(.vertical,6).background(surface,in:Capsule())
                }
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())],spacing:14) {
                    ForEach(enabledTopics) { topicCard($0) }
                }
                HStack(spacing:14) { Image(systemName:"lightbulb.fill").foregroundStyle(.orange); Text("Challenges have no time limit. Play at your own pace—every try earns you a little progress.").font(.system(size:12,weight:.medium)).foregroundStyle(.secondary); Spacer() }.padding(15).background(surface.opacity(0.75),in:RoundedRectangle(cornerRadius:14))
            }.padding(34)
        }
    }

    private var hero: some View {
        HStack(spacing:20) {
            VStack(alignment:.leading,spacing:13) { Text("TODAY’S MINI ADVENTURE").font(.system(size:10,weight:.heavy)).tracking(1.6).foregroundStyle(.white.opacity(0.78)); Text("The Great\nMath Mystery").font(.system(size:29,weight:.black,design:.rounded)).foregroundStyle(.white); Text("\(activeCharacterID) is ready to explore!").font(.system(size:13,weight:.medium)).foregroundStyle(.white.opacity(0.88)); Button { startGame(topic:enabledTopics.first ?? topics[0]) } label: { HStack{Text("Let’s play");Image(systemName:"arrow.right")}.font(.system(size:13,weight:.bold)).foregroundStyle(ink).padding(.horizontal,17).padding(.vertical,11).background(Color(red:1,green:0.82,blue:0.43),in:Capsule()) }.buttonStyle(.plain) }
            Spacer()
            ZStack { Circle().fill(.white.opacity(0.13)).frame(width:180,height:180); Circle().stroke(.white.opacity(0.2),lineWidth:1).frame(width:145,height:145); Text(activeCharacter.emoji).font(.system(size:96)); Text("✦").font(.system(size:24)).foregroundStyle(.yellow).offset(x:70,y:-53); Text("✧").font(.system(size:29)).foregroundStyle(.white).offset(x:-78,y:43) }
        }.padding(25).frame(maxWidth:.infinity,minHeight:220).background(LinearGradient(colors:[Color(red:0.33,green:0.37,blue:0.76),Color(red:0.53,green:0.39,blue:0.77)],startPoint:.topLeading,endPoint:.bottomTrailing),in:RoundedRectangle(cornerRadius:24))
    }

    private func topicCard(_ topic: Topic) -> some View {
        Button { startGame(topic:topic) } label: {
            VStack(alignment:.leading,spacing:11) {
                HStack { Image(systemName:topic.icon).font(.system(size:18,weight:.bold)).foregroundStyle(topic.color); Spacer(); Image(systemName:"arrow.up.right").font(.system(size:11,weight:.bold)).foregroundStyle(.gray.opacity(0.5)) }
                Text(topic.title).font(.system(size:15,weight:.black,design:.rounded)).foregroundStyle(ink).lineLimit(1).minimumScaleFactor(0.8)
                Text(topic.subtitle).font(.system(size:11)).foregroundStyle(.secondary).lineLimit(1)
                GeometryReader { g in ZStack(alignment:.leading){Capsule().fill(Color.black.opacity(0.06));Capsule().fill(topic.color).frame(width:g.size.width * progress(for:topic))} }.frame(height:5)
                Text("\(topicWins[topic.id] ?? 0) challenges solved").font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary)
            }.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(Color.black.opacity(0.025),lineWidth:1))
        }.buttonStyle(.plain).disabled(!topic.grades.contains(grade)).opacity(topic.grades.contains(grade) ? 1 : 0.48)
    }

    private func progress(for topic: Topic) -> CGFloat { min(1,CGFloat(topicWins[topic.id] ?? 0)/10) }

    private var mapView: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                HStack(spacing:14) {
                    VStack(alignment:.leading,spacing:5) {
                        Text("Grade \(grade) practice map").font(.system(size:28,weight:.black,design:.rounded))
                        Text("Choose a topic to practise. Each bar tracks correct answers toward 10.")
                            .font(.system(size:13)).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
                    }
                    Spacer(minLength:8)
                    HStack(spacing:8) {
                        Button { grade=max(1,grade-1) } label: { Image(systemName:"minus").font(.system(size:11,weight:.black)).frame(width:30,height:30).background(surface,in:Circle()) }.buttonStyle(.plain).disabled(grade <= 1)
                        Text("Grade \(grade)").font(.system(size:12,weight:.black,design:.rounded)).frame(minWidth:54)
                        Button { grade=min(12,grade+1) } label: { Image(systemName:"plus").font(.system(size:11,weight:.black)).frame(width:30,height:30).background(surface,in:Circle()) }.buttonStyle(.plain).disabled(grade >= 12)
                    }.padding(6).background(surface.opacity(0.7),in:Capsule())
                }
                HStack(spacing:8) {
                    Image(systemName:"square.grid.2x2.fill").foregroundStyle(.secondary)
                    Text("\(learningMapTopics.count) topics available").font(.system(size:12,weight:.bold))
                }.foregroundStyle(.secondary)
                LazyVGrid(columns:[GridItem(.adaptive(minimum:260),spacing:12)],spacing:12) {
                    ForEach(learningMapTopics) { topic in learningMapCard(topic) }
                }
                if learningMapTopics.isEmpty {
                    Text("No enabled topics are available for Grade \(grade). Turn on a topic in Settings or choose another grade.")
                        .font(.system(size:13)).foregroundStyle(.secondary).padding(18).frame(maxWidth:.infinity,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:16))
                }
            }.padding(28)
        }
    }

    private func learningMapCard(_ topic:Topic)->some View {
        let wins=topicWins[topic.id] ?? 0
        let goalProgress=min(1,CGFloat(wins)/10)
        return Button { startGame(topic:topic) } label: {
            VStack(alignment:.leading,spacing:12) {
                HStack(spacing:11) {
                    ZStack { Circle().fill(topic.color.opacity(0.14)).frame(width:40,height:40); Image(systemName:topic.icon).font(.system(size:18,weight:.bold)).foregroundStyle(topic.color) }
                    Text(topic.title).font(.system(size:15,weight:.black,design:.rounded)).foregroundStyle(ink).lineLimit(2)
                    Spacer(minLength:4)
                    Image(systemName:"arrow.right").font(.system(size:12,weight:.bold)).foregroundStyle(topic.color)
                }
                Text(topic.subtitle).font(.system(size:12)).foregroundStyle(.secondary).lineLimit(2).frame(maxWidth:.infinity,minHeight:30,alignment:.leading)
                HStack {
                    Text("\(min(wins,10))/10 correct")
                    Spacer()
                    Text(wins >= 10 ? "Goal reached" : "Practice")
                }.font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary)
                GeometryReader { geometry in
                    ZStack(alignment:.leading) {
                        Capsule().fill(Color.black.opacity(0.07))
                        Capsule().fill(topic.color).frame(width:geometry.size.width*goalProgress)
                    }
                }.frame(height:5)
            }.padding(15).frame(maxWidth:.infinity,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:16))
        }.buttonStyle(.plain)
    }

    private var progressView: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:20) {
                HStack(spacing:16) {
                    ZStack { Circle().fill(Color(red:0.99,green:0.73,blue:0.28).opacity(0.25)).frame(width:78,height:78);Text(activeCharacter.emoji).font(.system(size:54)) }
                    VStack(alignment:.leading,spacing:4) { Text(activeCharacter.id).font(.system(size:25,weight:.black,design:.rounded));Text("Your adventure companion").font(.system(size:13,weight:.medium)).foregroundStyle(.secondary) }
                    Spacer()
                }.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:18))
                Text("Your progress").font(.system(size:26,weight:.black,design:.rounded))
                VStack(spacing:14) {
                    metricGraph("XP collected",value:xp,goal:500,icon:"sparkles",color:.orange)
                    metricGraph("Challenges solved",value:score,goal:50,icon:"puzzlepiece.fill",color:.blue)
                    metricGraph("Day streak",value:streak,goal:7,icon:"flame.fill",color:.pink)
                }
                VStack(alignment:.leading,spacing:12) {
                    HStack(alignment:.center,spacing:12) {
                        VStack(alignment:.leading,spacing:3) {
                            Text("Results by topic").font(.system(size:19,weight:.black,design:.rounded))
                            Text("Choose a topic to see correct and incorrect answers.").font(.system(size:12)).foregroundStyle(.secondary)
                        }
                        Spacer(minLength:8)
                        Picker("Topic",selection:Binding(
                            get:{ profileStatsTopic.id },
                            set:{ selectedProfileTopicID=$0 }
                        )) {
                            ForEach(enabledTopics) { topic in Text(topic.title).tag(topic.id) }
                        }
                        .pickerStyle(.menu)
                        .accessibilityLabel("Choose a topic for answer results")
                    }
                    topicPieChart(profileStatsTopic)
                }.padding(16).background(surface.opacity(0.55),in:RoundedRectangle(cornerRadius:18))
                badgeCollection
            }.padding(34)
        }
    }

    private var reviewChallenges: [ReviewChallenge] {
        guard let data = reviewChallengeData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([ReviewChallenge].self, from: data) else { return [] }
        return decoded.sorted { $0.missedAt > $1.missedAt }
    }

    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Questions to retry").font(.system(size:28,weight:.black,design:.rounded))
                Text("Only questions you answered incorrectly appear here. Retry the same question; it leaves the list when you answer correctly.")
                    .font(.system(size:14)).foregroundStyle(.secondary).fixedSize(horizontal:false,vertical:true)
                if reviewChallenges.isEmpty {
                    VStack(spacing:12) {
                        Image(systemName:"checkmark.seal.fill").font(.system(size:42)).foregroundStyle(.green)
                        Text("No questions to retry!").font(.system(size:19,weight:.black,design:.rounded))
                        Text("Questions you answer incorrectly will appear here. You won’t be sent through the whole lesson.").font(.system(size:13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }.frame(maxWidth:.infinity).padding(38).background(surface,in:RoundedRectangle(cornerRadius:18))
                } else {
                    ForEach(reviewChallenges) { challenge in
                        let topic = topics.first(where: { $0.id == challenge.topicID })
                        HStack(spacing:14) {
                            Image(systemName:topic?.icon ?? "questionmark.circle.fill").font(.system(size:22,weight:.bold)).foregroundStyle(topic?.color ?? .orange).frame(width:48,height:48).background((topic?.color ?? .orange).opacity(0.13),in:RoundedRectangle(cornerRadius:14))
                            VStack(alignment:.leading,spacing:5) {
                                Text(topic?.title ?? "Math lesson").font(.system(size:14,weight:.black,design:.rounded))
                                Text(challenge.question.prompt).font(.system(size:12)).foregroundStyle(.secondary).lineLimit(2)
                                Text("Grade \(challenge.grade)").font(.system(size:10,weight:.bold)).foregroundStyle(.secondary)
                            }
                            Spacer(minLength:8)
                            Button("Try again") { startReview(challenge) }.buttonStyle(.borderedProminent).tint(topic?.color ?? .orange)
                        }.padding(15).background(surface,in:RoundedRectangle(cornerRadius:16))
                    }
                }
            }.padding(34)
        }
    }

    private var earnedBadgeIDs: Set<String> { Set(earnedBadgeData.split(separator:",").map(String.init)) }
    private var allBadges: [GameBadge] {
        GameBadgeCatalog.core + topics.map {
            GameBadge(id:"subject_streak_\($0.id)",title:"\($0.title) Star",description:"Answer 10 questions correctly in a row in \($0.title.lowercased()).",icon:$0.icon,rewardXP:150)
        }
    }

    private var badgeCollection: some View {
        VStack(alignment:.leading,spacing:14) {
            HStack(alignment:.bottom) {
                VStack(alignment:.leading,spacing:5) {
                    Text("Badges").font(.system(size:22,weight:.black,design:.rounded))
                    Text("Keep exploring, practicing, and solving to earn more.").font(.system(size:13)).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(earnedBadgeIDs.count) / \(allBadges.count)").font(.system(size:12,weight:.black,design:.rounded)).foregroundStyle(ink).padding(10).background(Color.orange.opacity(0.18),in:Capsule())
            }
            LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible()),GridItem(.flexible())],spacing:13) {
                ForEach(allBadges) { badge in
                    let earned=earnedBadgeIDs.contains(badge.id)
                    VStack(spacing:9) {
                        ZStack(alignment:.bottomTrailing) {
                            Image(systemName:badge.icon).font(.system(size:28,weight:.bold)).foregroundStyle(earned ? Color.orange : Color.gray.opacity(0.5)).frame(width:68,height:68).background((earned ? Color.orange : Color.gray).opacity(0.13),in:Circle())
                            if !earned { Image(systemName:"lock.fill").font(.system(size:10,weight:.black)).foregroundStyle(.white).padding(5).background(Color.gray,in:Circle()).offset(x:3,y:3) }
                        }
                        Text(badge.title).font(.system(size:13,weight:.black,design:.rounded)).foregroundStyle(ink).multilineTextAlignment(.center)
                        Text(badge.description).font(.system(size:10,weight:.medium)).foregroundStyle(.secondary).multilineTextAlignment(.center).fixedSize(horizontal:false,vertical:true)
                        Text("Prize: +\(badge.rewardXP) XP").font(.system(size:10,weight:.heavy)).foregroundStyle(Color.purple)
                        Text(earned ? "EARNED" : "LOCKED").font(.system(size:9,weight:.heavy)).tracking(0.8).foregroundStyle(earned ? .green : .secondary)
                    }.padding(14).frame(maxWidth:.infinity,minHeight:185).background(surface,in:RoundedRectangle(cornerRadius:16)).opacity(earned ? 1 : 0.78)
                }
            }
        }
    }

    private var shopView: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack(alignment:.center) {
                    VStack(alignment:.leading,spacing:4) {
                        Text("Explorer shop").font(.system(size:28,weight:.black,design:.rounded))
                        Text("Spend XP on new friends and power-ups.").font(.system(size:14)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("\(xp) XP",systemImage:"sparkles").font(.system(size:16,weight:.black,design:.rounded)).foregroundStyle(ink).padding(13).background(Color.orange.opacity(0.16),in:Capsule())
                }
                Text("Power-ups").font(.system(size:19,weight:.black,design:.rounded)).padding(.top,4)
                potionShopCard(multiplier:2)
                potionShopCard(multiplier:4)
                Text("Choose a character").font(.system(size:19,weight:.black,design:.rounded))
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:14) {
                    ForEach(shopCharacters) { character in
                        let owned=ownedCharacterSet.contains(character.id)
                        VStack(spacing:9) {
                            Text(character.emoji).font(.system(size:48)).frame(height:62)
                            Text(character.id).font(.system(size:16,weight:.black,design:.rounded)).foregroundStyle(ink)
                            Text(character.description).font(.system(size:11,weight:.medium)).foregroundStyle(.secondary)
                            Label(character.abilityDescription.replacingOccurrences(of:"+1 XP",with:"+\(character.abilityBonusXP) XP"),systemImage:"sparkle")
                                .font(.system(size:10,weight:.semibold)).foregroundStyle(isDarkAppearance ? Color(red:0.82,green:0.66,blue:1) : Color.purple)
                                .frame(maxWidth:.infinity,alignment:.leading).padding(8)
                                .background(Color.purple.opacity(0.08),in:RoundedRectangle(cornerRadius:9))
                            if owned {
                                Button { activeCharacterID=character.id } label: {
                                    Text(activeCharacterID == character.id ? "Selected" : "Choose")
                                        .font(.system(size:12,weight:.bold)).foregroundStyle(activeCharacterID == character.id ? .white : ink)
                                        .frame(maxWidth:.infinity).padding(.vertical,9)
                                        .background(activeCharacterID == character.id ? Color.green : Color.black.opacity(0.07),in:Capsule())
                                }.buttonStyle(.plain)
                            } else {
                                Button { buy(character) } label: {
                                    Label("\(character.price) XP",systemImage:"sparkles").font(.system(size:12,weight:.bold)).foregroundStyle(.white).frame(maxWidth:.infinity).padding(.vertical,9).background(xp >= character.price ? buttonFill : Color.gray.opacity(0.55),in:Capsule())
                                }.buttonStyle(.plain)
                            }
                        }.padding(16).frame(maxWidth:.infinity).background(surface,in:RoundedRectangle(cornerRadius:18))
                    }
                }
            }.padding(34)
        }
        .alert("Not enough XP", isPresented: $showInsufficientXPAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(insufficientXPMessage)
        }
    }

    private func potionShopCard(multiplier:Int)->some View {
        let price=multiplier == 4 ? 200 : 100
        let inventory=multiplier == 4 ? quadruplePotionInventory : potionInventory
        let expiry=multiplier == 4 ? quadrupleXPExpiry : doubleXPExpiry
        let tint:Color=multiplier == 4 ? .orange : .purple
        return HStack(spacing:16) {
            ZStack { Circle().fill(tint.opacity(0.13)).frame(width:58,height:58);Text(multiplier == 4 ? "⚡️⚡️" : "⚡️").font(.system(size:multiplier == 4 ? 24 : 32)) }
            VStack(alignment:.leading,spacing:5) {
                Text("\(multiplier)× XP Potion").font(.system(size:16,weight:.black,design:.rounded))
                Text("Duration: 5 minutes.").font(.system(size:12)).foregroundStyle(.secondary)
                TimelineView(.periodic(from:.now,by:1)) { context in
                    let seconds=max(0,Int(ceil(expiry-context.date.timeIntervalSince1970)))
                    Text(seconds > 0 ? "\(multiplier)× XP active · \(timerText(seconds)) left" : "Inventory: \(inventory)").font(.system(size:11,weight:.bold)).foregroundStyle(tint)
                }
            }
            Spacer(minLength:4)
            VStack(spacing:8) {
                Button { buyPotion(multiplier:multiplier) } label:{Text("Buy · \(price) XP").font(.system(size:11,weight:.bold)).foregroundStyle(.white).padding(.horizontal,12).padding(.vertical,9).background(xp >= price ? tint : Color.gray.opacity(0.55),in:Capsule())}.buttonStyle(.plain)
                if inventory > 0 {
                    TimelineView(.periodic(from:.now,by:1)) { context in
                        let active=max(doubleXPExpiry,quadrupleXPExpiry) > context.date.timeIntervalSince1970
                        Button(active ? "Active" : "Use potion") { activatePotion(multiplier:multiplier) }.font(.system(size:11,weight:.bold)).buttonStyle(.bordered).disabled(active)
                    }
                }
            }
        }.padding(18).background(surface,in:RoundedRectangle(cornerRadius:18))
    }

    private var settingsView: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:18) {
                VStack(alignment:.leading,spacing:5) {
                    Text("Settings").font(.system(size:28,weight:.black,design:.rounded))
                    Text("Personalize how Math Quest looks and what you study.").font(.system(size:14)).foregroundStyle(.secondary)
                }

                VStack(alignment:.leading,spacing:12) {
                    Label("Appearance",systemImage:"paintbrush.fill").font(.system(size:17,weight:.black,design:.rounded))
                    HStack {
                        Text("Theme").font(.system(size:13,weight:.semibold))
                        Spacer()
                        Picker("Theme",selection:$appearance) {
                            Text("Light").tag("Light")
                            Text("Dark").tag("Dark")
                        }.pickerStyle(.segmented).frame(width:210)
                    }
                    Text("Choose the light or dark look for Math Quest.").font(.system(size:11)).foregroundStyle(.secondary)
                }.padding(17).frame(maxWidth:.infinity,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:16))

                VStack(alignment:.leading,spacing:12) {
                    HStack(alignment:.center) {
                        VStack(alignment:.leading,spacing:4) {
                            Label("Course modules",systemImage:"books.vertical.fill").font(.system(size:17,weight:.black,design:.rounded))
                            Text("Choose which courses appear on Home and Map.").font(.system(size:11)).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(enabledTopicSet.count) of \(topics.count) on").font(.system(size:10,weight:.bold)).foregroundStyle(.secondary)
                        Button("Enable all") { enabledTopicIDs=topics.map(\.id).joined(separator:",") }.buttonStyle(.bordered)
                    }

                    VStack(spacing:0) {
                        ForEach(topics) { topic in
                            HStack(spacing:12) {
                                Image(systemName:topic.icon).font(.system(size:17,weight:.bold)).foregroundStyle(topic.color).frame(width:30,height:34)
                                VStack(alignment:.leading,spacing:3) {
                                    Text(topic.title).font(.system(size:13,weight:.bold,design:.rounded)).foregroundStyle(ink)
                                    Text("\(topic.strand) · Grades \(topic.grades.lowerBound)–\(topic.grades.upperBound)").font(.system(size:10,weight:.medium)).foregroundStyle(.secondary)
                                }
                                Spacer(minLength:12)
                                Toggle(topic.title,isOn:topicBinding(for:topic)).labelsHidden().toggleStyle(.switch)
                                    .disabled(enabledTopicSet.count == 1 && enabledTopicSet.contains(topic.id))
                            }.padding(.vertical,9)
                            if topic.id != topics.last?.id { Divider().padding(.leading,42) }
                        }
                    }
                    Text("Keep at least one course on. Your XP and answers stay saved when you hide a course.").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary).padding(.top,2)
                }.padding(17).frame(maxWidth:.infinity,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:16))
            }.padding(34)
        }
    }

    private var enabledTopicSet:Set<String> { Set(enabledTopicIDs.split(separator:",").map(String.init)) }
    private var enabledTopics:[Topic] { topics.filter{enabledTopicSet.contains($0.id)} }
    private var learningMapTopics:[Topic] { enabledTopics.filter{$0.grades.contains(grade)} }
    private var profileStatsTopic:Topic {
        enabledTopics.first(where:{$0.id == selectedProfileTopicID}) ?? enabledTopics.first ?? topics[0]
    }
    private func topicBinding(for topic:Topic)->Binding<Bool> {
        Binding(
            get:{enabledTopicSet.contains(topic.id)},
            set:{isEnabled in
                var updated=enabledTopicSet
                if isEnabled { updated.insert(topic.id) }
                else if updated.count > 1 { updated.remove(topic.id) }
                enabledTopicIDs=topics.filter{updated.contains($0.id)}.map(\.id).joined(separator:",")
            }
        )
    }

    private var inventoryView: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                HStack {
                    VStack(alignment:.leading,spacing:4) {
                        Text("Inventory").font(.system(size:28,weight:.black,design:.rounded))
                        Text("Your collected companions and power-ups.").font(.system(size:14)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("\(xp) XP",systemImage:"sparkles").font(.system(size:15,weight:.black,design:.rounded)).foregroundStyle(ink).padding(12).background(Color.orange.opacity(0.16),in:Capsule())
                }
                potionInventoryCard(multiplier:2)
                potionInventoryCard(multiplier:4)
                Text("My characters").font(.system(size:19,weight:.black,design:.rounded))
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:14) {
                    ForEach(shopCharacters.filter{ownedCharacterSet.contains($0.id)}) { character in
                        Button { activeCharacterID=character.id } label: {
                            HStack(spacing:12) {
                                Text(character.emoji).font(.system(size:40))
                                VStack(alignment:.leading,spacing:4) {
                                    Text(character.id).font(.system(size:14,weight:.black,design:.rounded)).foregroundStyle(ink)
                                    Text(activeCharacterID == character.id ? "Selected companion" : "Tap to choose").font(.system(size:10,weight:.medium)).foregroundStyle(activeCharacterID == character.id ? .green : .secondary)
                                }
                                Spacer(minLength:0)
                            }.padding(14).frame(maxWidth:.infinity,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:16)).overlay(RoundedRectangle(cornerRadius:16).stroke(activeCharacterID == character.id ? Color.green : .clear,lineWidth:2))
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(34)
        }
    }

    private func potionInventoryCard(multiplier:Int)->some View {
        let inventory=multiplier == 4 ? quadruplePotionInventory : potionInventory
        let expiry=multiplier == 4 ? quadrupleXPExpiry : doubleXPExpiry
        let tint:Color=multiplier == 4 ? .orange : .purple
        return HStack(spacing:14) {
            Text(multiplier == 4 ? "⚡️⚡️" : "⚡️").font(.system(size:multiplier == 4 ? 29 : 40)).frame(width:62,height:62).background(tint.opacity(0.12),in:RoundedRectangle(cornerRadius:16))
            VStack(alignment:.leading,spacing:5) {
                Text("\(multiplier)× XP Potion").font(.system(size:17,weight:.black,design:.rounded))
                Text("Owned: \(inventory)").font(.system(size:13,weight:.bold)).foregroundStyle(tint)
                TimelineView(.periodic(from:.now,by:1)) { context in
                    let seconds=max(0,Int(ceil(expiry-context.date.timeIntervalSince1970)))
                    Text(seconds > 0 ? "\(multiplier)× XP active · \(timerText(seconds)) left" : "Duration: 5 minutes.").font(.system(size:12)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            if inventory > 0 {
                TimelineView(.periodic(from:.now,by:1)) { context in
                    let active=max(doubleXPExpiry,quadrupleXPExpiry) > context.date.timeIntervalSince1970
                    Button(active ? "Active" : "Use potion") { activatePotion(multiplier:multiplier) }
                        .buttonStyle(.borderedProminent).tint(tint).disabled(active)
                }
            } else {
                Button("Visit shop") { navigate(to:"Shop") }.buttonStyle(.bordered)
            }
        }.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:18))
    }

    private var ownedCharacterSet: Set<String> { Set(ownedCharacterIDs.split(separator:",").map(String.init)) }
    private var activeCharacter: ShopCharacter { shopCharacters.first(where:{$0.id == activeCharacterID}) ?? shopCharacters[0] }
    private var activePotionMultiplier: Int {
        let now=Date().timeIntervalSince1970
        if quadrupleXPExpiry > now { return 4 }
        if doubleXPExpiry > now { return 2 }
        return 1
    }

    private func buy(_ character:ShopCharacter) {
        guard !ownedCharacterSet.contains(character.id) else{return}
        guard xp >= character.price else {
            insufficientXPMessage = "Not enough XP. \(character.id) costs \(character.price) XP; you have \(xp), so you need \(character.price - xp) more."
            showInsufficientXPAlert = true
            return
        }
        xp -= character.price
        insufficientXPMessage = ""
        ownedCharacterIDs=ownedCharacterSet.union([character.id]).sorted().joined(separator:",")
        activeCharacterID=character.id
    }
    private func buyPotion(multiplier:Int) {
        let price=multiplier == 4 ? 200 : 100
        guard xp >= price else {
            insufficientXPMessage = "Not enough XP. This potion costs \(price) XP; you have \(xp), so you need \(price - xp) more."
            showInsufficientXPAlert = true
            return
        }
        xp -= price
        insufficientXPMessage = ""
        if multiplier == 4 { quadruplePotionInventory += 1 }
        else { potionInventory += 1 }
    }
    private func activatePotion(multiplier:Int) {
        let now=Date().timeIntervalSince1970
        guard max(doubleXPExpiry,quadrupleXPExpiry) <= now else{return}
        if multiplier == 4 {
            guard quadruplePotionInventory > 0 else{return}
            quadruplePotionInventory -= 1
            quadrupleXPExpiry=now+300
        } else {
            guard potionInventory > 0 else{return}
            potionInventory -= 1
            doubleXPExpiry=now+300
        }
    }
    private func timerText(_ seconds:Int)->String { String(format:"%d:%02d",seconds/60,seconds%60) }
    private var activePotionBadge: some View {
        TimelineView(.periodic(from:.now,by:1)) { context in
            let useQuadruple=quadrupleXPExpiry > context.date.timeIntervalSince1970
            let expiry=useQuadruple ? quadrupleXPExpiry : doubleXPExpiry
            let multiplier=useQuadruple ? 4 : 2
            let seconds=max(0,Int(ceil(expiry-context.date.timeIntervalSince1970)))
            if seconds > 0 {
                HStack(spacing:4) {
                    Image(systemName:"bolt.fill").font(.system(size:9,weight:.black))
                    Text("\(multiplier)× \(timerText(seconds))").font(.system(size:10,weight:.black,design:.rounded))
                }
                .foregroundStyle(Color.purple)
                .padding(.horizontal,8).padding(.vertical,6)
                .background(Color.purple.opacity(0.10),in:Capsule())
                .overlay(Capsule().stroke(Color.purple.opacity(0.18),lineWidth:1))
                .accessibilityLabel("\(multiplier) times XP potion active for \(timerText(seconds))")
            }
        }
    }
    private func awardCorrectAnswerXP(for topicID:String) {
        let baseXP = 10 * activePotionMultiplier
        let earnedXP=baseXP + characterBonusXP(for:topicID)
        xp += earnedXP
        totalXPEarned += earnedXP
        score += 1
        correctAnswerStreak += 1
        var subjectStreaks=topicCorrectStreaks
        subjectStreaks[topicID,default:0] += 1
        topicCorrectStreakData=subjectStreaks.keys.sorted().map{"\($0)=\(subjectStreaks[$0] ?? 0)"}.joined(separator:";")
        var wins=topicWins
        wins[topicID,default:0] += 1
        topicWinsData=wins.keys.sorted().map{"\($0)=\(wins[$0] ?? 0)"}.joined(separator:";")
        let wasReviewQuestion=activeReviewChallengeID != nil
        recordTopicAnswer(topicID,correct:true)
        unlockBadges(reviewCorrect:wasReviewQuestion)
        if let activeReviewChallengeID {
            saveReviewChallenges(reviewChallenges.filter { $0.id != activeReviewChallengeID })
        }
    }
    private func characterBonusXP(for topicID:String)->Int {
        let nextSolvedCount = score + 1
        let earnsBonus: Bool
        switch activeCharacterID {
        case "Maple": earnsBonus = nextSolvedCount.isMultiple(of:3)
        case "Pip": earnsBonus = topicID == "number"
        case "Nova": earnsBonus = grade >= 7
        case "Cedar": earnsBonus = topicID == "measurement"
        case "Comet": earnsBonus = nextSolvedCount.isMultiple(of:5)
        case "Mochi": earnsBonus = topicID == "fractions"
        case "Waddles": earnsBonus = topicID == "data"
        case "Bubbles": earnsBonus = topicID == "spatial"
        case "Thistle": earnsBonus = topicID == "algebra"
        case "Shellby": earnsBonus = topicID == "probability"
        case "Sunny": earnsBonus = topicID == "money"
        case "Sprinkles": earnsBonus = topicID == "decimals_percentages"
        case "Byte": earnsBonus = topicID == "coding_algorithms"
        case "Puddle": earnsBonus = topicID == "data_visualization"
        case "Acorn": earnsBonus = topicID == "mental_math_place_value"
        case "Orbit": earnsBonus = topicID == "mathematical_modelling"
        case "Coral": earnsBonus = topicID == "triangles_transformations"
        case "Frost": earnsBonus = grade >= 9
        case "Peaches": earnsBonus = activeReviewChallengeID != nil
        case "Zigzag": earnsBonus = grade <= 3
        case "Poppy": earnsBonus = topicID == "data" && score.isMultiple(of:2)
        case "Moss": earnsBonus = topicID == "budgeting_credit"
        case "Tango": earnsBonus = topicID == "spatial" && nextSolvedCount.isMultiple(of:2)
        case "Rumble": earnsBonus = topicID == "number" && grade >= 6
        case "Lumi": earnsBonus = topicID == "triangles_transformations" && grade >= 6
        case "Marbles": earnsBonus = activePotionMultiplier > 1
        case "Pixel": earnsBonus = nextSolvedCount.isMultiple(of:10)
        default: earnsBonus = false
        }
        return earnsBonus ? activeCharacter.abilityBonusXP : 0
    }
    private func recordTopicAnswer(_ topicID:String,correct:Bool,question missedQuestion:Question? = nil) {
        var stats=topicAnswerStats
        var count=stats[topicID] ?? TopicAnswerStats()
        if correct { count.correct += 1 } else { count.incorrect += 1 }
        stats[topicID]=count
        topicAnswerStatsData=stats.keys.sorted().map{"\($0):\(stats[$0]?.correct ?? 0),\(stats[$0]?.incorrect ?? 0)"}.joined(separator:";")
        var attempted=Set(topicsAttemptedData.split(separator:",").map(String.init))
        attempted.insert(topicID)
        topicsAttemptedData=attempted.sorted().joined(separator:",")
        if !correct {
            correctAnswerStreak=0
            var subjectStreaks=topicCorrectStreaks
            subjectStreaks[topicID]=0
            topicCorrectStreakData=subjectStreaks.keys.sorted().map{"\($0)=\(subjectStreaks[$0] ?? 0)"}.joined(separator:";")
            unlockBadges(reviewCorrect:false)
        }
        if !correct, activeReviewChallengeID == nil, let missedQuestion {
            var saved = reviewChallenges
            if !saved.contains(where: { $0.topicID == topicID && $0.question.prompt == missedQuestion.prompt }) {
                saved.append(ReviewChallenge(id:UUID(),topicID:topicID,grade:grade,question:missedQuestion,missedAt:Date()))
                saveReviewChallenges(saved)
            }
        }
    }

    private func unlockBadges(reviewCorrect:Bool) {
        var unlocked=earnedBadgeIDs
        var newlyUnlockedBadges:[GameBadge]=[]
        while true {
            var eligible=Set<String>()
            if score >= 1 { eligible.insert("first_win") }
            if correctAnswerStreak >= 10 { eligible.insert("streak_10") }
            if correctAnswerStreak >= 25 { eligible.insert("streak_25") }
            if score >= 100 { eligible.insert("solved_100") }
            if totalXPEarned >= 1_000 { eligible.insert("xp_1000") }
            if totalXPEarned >= 5_000 { eligible.insert("xp_5000") }
            let attempted=Set(topicsAttemptedData.split(separator:",").map(String.init))
            if attempted.count >= 5 { eligible.insert("topics_5") }
            if topics.allSatisfy({attempted.contains($0.id)}) { eligible.insert("all_topics") }
            if reviewCorrect { eligible.insert("review_win") }
            let subjectStreaks=topicCorrectStreaks
            for topic in topics where (subjectStreaks[topic.id] ?? 0) >= 10 {
                eligible.insert("subject_streak_\(topic.id)")
            }
            let newIDs=eligible.subtracting(unlocked)
            guard !newIDs.isEmpty else{break}
            let badges=allBadges.filter{newIDs.contains($0.id)}
            newlyUnlockedBadges.append(contentsOf:badges)
            unlocked.formUnion(newIDs)
            let prize=badges.reduce(0){$0+$1.rewardXP}
            xp += prize
            totalXPEarned += prize
        }
        if !newlyUnlockedBadges.isEmpty {
            newlyUnlockedBadgeMessage=newlyUnlockedBadges.map{"\($0.title) · +\($0.rewardXP) XP"}.joined(separator:"\n")
        }
        earnedBadgeData=unlocked.sorted().joined(separator:",")
    }

    private func reconcileBadgeProgress() {
        // Older saves have an XP balance but predate lifetime XP tracking.
        totalXPEarned=max(totalXPEarned,xp)
        unlockBadges(reviewCorrect:false)
    }

    private func saveReviewChallenges(_ challenges:[ReviewChallenge]) {
        guard let data = try? JSONEncoder().encode(challenges), let value = String(data:data,encoding:.utf8) else{return}
        reviewChallengeData=value
    }

    private func metricGraph(_ title:String,value:Int,goal:Int,icon:String,color:Color)->some View {
        VStack(alignment:.leading,spacing:8) {
            HStack(spacing:8) { Image(systemName:icon).foregroundStyle(color);Text(title).font(.system(size:13,weight:.bold));Spacer();Text("\(value)").font(.system(size:18,weight:.black,design:.rounded)).foregroundStyle(ink) }
            GeometryReader { proxy in
                ZStack(alignment:.leading) {
                    Capsule().fill(Color.black.opacity(0.07))
                    Capsule().fill(color.gradient).frame(width:proxy.size.width * min(1,CGFloat(value)/CGFloat(goal)))
                }
            }.frame(height:11)
            Text("Goal: \(goal)\(title == "XP collected" ? " XP" : title == "Day streak" ? " days" : " challenges")").font(.system(size:10,weight:.medium)).foregroundStyle(.secondary)
        }.padding(14).background(surface,in:RoundedRectangle(cornerRadius:14))
    }

    private func topicGraph(_ topic:Topic)->some View {
        let wins=topicWins[topic.id] ?? 0
        return HStack(spacing:11) {
            Image(systemName:topic.icon).foregroundStyle(topic.color).frame(width:23)
            Text(topic.title).font(.system(size:11,weight:.semibold)).lineLimit(1).frame(width:125,alignment:.leading)
            GeometryReader { proxy in
                ZStack(alignment:.leading) {
                    Capsule().fill(Color.black.opacity(0.06))
                    Capsule().fill(topic.color).frame(width:proxy.size.width * min(1,CGFloat(wins)/10))
                }
            }.frame(height:8)
            Text("\(wins)").font(.system(size:11,weight:.bold)).foregroundStyle(.secondary).frame(width:28,alignment:.trailing)
        }.padding(12).background(surface,in:RoundedRectangle(cornerRadius:12))
    }

    private var topicWins:[String:Int] {
        var result:[String:Int]=[:]
        for entry in topicWinsData.split(separator:";") {
            let parts=entry.split(separator:"=",maxSplits:1)
            if parts.count == 2,let count=Int(parts[1]) { result[String(parts[0])]=count }
        }
        return result
    }

    private var topicCorrectStreaks:[String:Int] {
        var result:[String:Int]=[:]
        for entry in topicCorrectStreakData.split(separator:";") {
            let parts=entry.split(separator:"=",maxSplits:1)
            if parts.count == 2,let value=Int(parts[1]) { result[String(parts[0])]=value }
        }
        return result
    }

    private var topicAnswerStats:[String:TopicAnswerStats] {
        var result=Dictionary(uniqueKeysWithValues:topics.map{($0.id,TopicAnswerStats(correct:topicWins[$0.id] ?? 0,incorrect:0))})
        for entry in topicAnswerStatsData.split(separator:";") {
            let parts=entry.split(separator:":",maxSplits:1)
            guard parts.count == 2 else{continue}
            let counts=parts[1].split(separator:",")
            guard counts.count == 2,let correct=Int(counts[0]),let incorrect=Int(counts[1]) else{continue}
            result[String(parts[0])]=TopicAnswerStats(correct:correct,incorrect:incorrect)
        }
        return result
    }

    private func topicPieChart(_ topic:Topic)->some View {
        let stats=topicAnswerStats[topic.id] ?? TopicAnswerStats()
        let total=stats.correct+stats.incorrect
        return VStack(spacing:8) {
            HStack(spacing:7) {
                Image(systemName:topic.icon).foregroundStyle(topic.color)
                Text(topic.title).font(.system(size:12,weight:.bold,design:.rounded)).lineLimit(1)
                Spacer(minLength:0)
                Text("\(total)").font(.system(size:11,weight:.black)).foregroundStyle(.secondary)
            }
            Chart {
                if stats.correct > 0 {
                    SectorMark(angle:.value("Correct",stats.correct),angularInset:2).foregroundStyle(Color.green)
                }
                if stats.incorrect > 0 {
                    SectorMark(angle:.value("Incorrect",stats.incorrect),angularInset:2).foregroundStyle(Color.red)
                }
                if total == 0 {
                    SectorMark(angle:.value("No attempts",1),angularInset:2).foregroundStyle(Color.gray.opacity(0.16))
                }
            }
            .chartLegend(.hidden)
            .frame(height:118)
            HStack(spacing:8) {
                Label("\(stats.correct)",systemImage:"checkmark.circle.fill").font(.system(size:10,weight:.bold)).foregroundStyle(.green)
                Spacer(minLength:2)
                Label("\(stats.incorrect)",systemImage:"xmark.circle.fill").font(.system(size:10,weight:.bold)).foregroundStyle(.red)
            }
            if total == 0 { Text("No answers yet").font(.system(size:9,weight:.medium)).foregroundStyle(.secondary) }
        }.padding(13).background(surface,in:RoundedRectangle(cornerRadius:15))
    }

    private func gameView(_ q: Question) -> some View {
        VStack(spacing:0) {
            HStack { Button { activeReviewChallengeID=nil;question=nil;selectedAnswer=nil;answered=false } label:{Label("Back to camp",systemImage:"arrow.left").font(.system(size:12,weight:.bold)).foregroundStyle(ink)}.buttonStyle(.plain); Spacer(); activePotionBadge; HStack{Image(systemName:"sparkles").foregroundStyle(.orange);Text("\(xp) XP").font(.system(size:12,weight:.bold))}.padding(10).background(surface,in:Capsule()) }.padding(.horizontal,32).padding(.top,23)
            VStack(spacing:10) {
            HStack(alignment:.top,spacing:20) {
            VStack(spacing:9) {
                ScrollView {
                    VStack(spacing:16) {
                    HStack(spacing:7){ForEach(0..<5,id:\.self){i in Capsule().fill(i < round%5 ? Color.green : Color.black.opacity(0.08)).frame(height:6)}}
                    HStack(spacing:8){Image(systemName:(selectedTopic ?? topics[0]).icon);Text((selectedTopic ?? topics[0]).title.uppercased()).tracking(1)}.font(.system(size:10,weight:.heavy)).foregroundStyle((selectedTopic ?? topics[0]).color)
                    Text("SCENARIO").font(.system(size:9,weight:.black,design:.rounded)).tracking(0.8).foregroundStyle(.tertiary).frame(maxWidth:500,alignment:.leading)
                    Text(q.story).font(.system(size:14,weight:.medium,design:.rounded)).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth:500)
                    Text(q.prompt).font(.system(size:29,weight:.black,design:.rounded)).foregroundStyle(ink).multilineTextAlignment(.center).padding(.vertical,4)
                    visualExampleView()
                    VStack(spacing:8) { ForEach(q.choices,id:\.self) { choice in
                        if q.fractionNumerator != nil {
                            EmptyView()
                        } else {
                        Button { choose(choice,q) } label: { HStack{Text(choice).font(.system(size:15,weight:.bold,design:.rounded));Spacer();if selectedAnswer==choice && answered {Image(systemName:choice==q.answer ? "checkmark.circle.fill":"xmark.circle.fill")} }.foregroundStyle(answerColor(choice,q)).padding(12).frame(maxWidth:.infinity).background(answerBackground(choice,q),in:RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(answerStroke(choice,q),lineWidth:2)) }.buttonStyle(.plain).disabled(answered)
                        }
                    }}.frame(maxWidth:430)
                    if answered {
                        HStack(spacing:8) {
                            Image(systemName:boardAnswer == "correct" ? "star.fill" : (q.fractionNumerator != nil ? "xmark.circle.fill" : "lightbulb.fill"))
                                .foregroundStyle(boardAnswer == "correct" ? .orange : (q.fractionNumerator != nil ? .red : .orange))
                            Text(boardAnswer == "correct" ? "Brilliant! The trail is getting brighter!" : (q.fractionNumerator != nil ? "Not quite. Your circles do not show the same amount yet. Adjust your circle and try again." : q.hint))
                                .font(.system(size:12,weight:.semibold)).foregroundStyle(ink)
                        }.padding(11).frame(maxWidth:430,alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:12))
                        if q.fractionNumerator != nil && boardAnswer == "wrong" {
                            Button { retryFraction() } label: {
                                Text("Try again").font(.system(size:13,weight:.bold)).foregroundStyle(.white).padding(.horizontal,20).padding(.vertical,11).background(buttonFill,in:Capsule())
                            }.buttonStyle(.plain)
                        } else if activeReviewChallengeID != nil {
                            if boardAnswer == "correct" {
                                Button { finishReview() } label:{HStack{Text("Review complete · Back to review");Image(systemName:"arrow.left")}.font(.system(size:13,weight:.bold)).foregroundStyle(.white).padding(.horizontal,20).padding(.vertical,11).background(Color.green,in:Capsule())}.buttonStyle(.plain)
                            } else {
                                Button { retryReviewedQuestion(q) } label:{HStack{Text("Try this question again");Image(systemName:"arrow.clockwise")}.font(.system(size:13,weight:.bold)).foregroundStyle(.white).padding(.horizontal,20).padding(.vertical,11).background(buttonFill,in:Capsule())}.buttonStyle(.plain)
                            }
                        } else {
                            Button { nextQuestion() } label:{HStack{Text("Next challenge");Image(systemName:"arrow.right")}.font(.system(size:13,weight:.bold)).foregroundStyle(.white).padding(.horizontal,20).padding(.vertical,11).background(buttonFill,in:Capsule())}.buttonStyle(.plain)
                        }
                    }
                    else {
                        Button { showHint.toggle() } label:{Label(showHint ? "Hide hint" : "Need a hint?",systemImage:"lightbulb").font(.system(size:12,weight:.semibold)).foregroundStyle(.secondary)}.buttonStyle(.plain)
                        if showHint { Text(q.hint).font(.system(size:12,weight:.medium)).foregroundStyle(ink).padding(10).background(Color.yellow.opacity(0.18),in:RoundedRectangle(cornerRadius:12)) }
                    }
                    }
                    .frame(maxWidth:.infinity,alignment:.top)
                    .padding(21)
                }
                .scrollIndicators(.hidden)
                .background(surface.opacity(0.64),in:RoundedRectangle(cornerRadius:20))
            }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.top)
                if q.fractionNumerator != nil { fractionBoard(q).frame(width:250) }
                else if !q.operands.isEmpty { whiteboard(q).frame(width:250) }
            }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.top)
            }.padding(24).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.top)
        }
    }

    private func whiteboard(_ q: Question) -> some View {
        VStack(alignment:.leading,spacing:14) {
            HStack(spacing:8){Image(systemName:"hand.draw").foregroundStyle(Color(red:0.28,green:0.60,blue:0.55));Text("NUMBER BOARD").font(.system(size:11,weight:.black,design:.rounded)).tracking(1)}
            Text("Build the equation. Some tiles are decoys!").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary)
            VStack(spacing:10) {
                Text(q.prompt).font(.system(size:13,weight:.bold,design:.rounded)).foregroundStyle(ink).multilineTextAlignment(.center).lineLimit(3).frame(maxWidth:.infinity,minHeight:52)
                equationBuilder(q)
                HStack(spacing:6){Image(systemName:"hand.draw.fill").font(.system(size:10));Text("DRAG NUMBER OR OPERATOR TILES").font(.system(size:8,weight:.heavy)).tracking(0.5)}.foregroundStyle(.secondary)
                Text("Numbers").font(.system(size:10,weight:.bold)).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading)
                LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:9) {
                    ForEach(Array(q.numberTiles.enumerated()),id:\.offset) { _, value in
                        Text("\(value)").font(.system(size:16,weight:.black,design:.rounded)).foregroundStyle(ink).frame(maxWidth:.infinity,minHeight:37).background(numberTileSurface,in:RoundedRectangle(cornerRadius:11)).overlay(RoundedRectangle(cornerRadius:11).stroke(selectedBoardTile == "N:\(value)" ? Color.orange : Color.black.opacity(0.04),lineWidth:selectedBoardTile == "N:\(value)" ? 2:1)).draggable("N:\(value)").onTapGesture{selectedBoardTile="N:\(value)"}.opacity(answered ? 0.55 : 1)
                    }
                }
                Text("Operations").font(.system(size:10,weight:.bold)).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading)
                HStack(spacing:5) { ForEach(["+","−","×","÷","^"],id:\.self) { symbol in Text(symbol).font(.system(size:16,weight:.black,design:.rounded)).foregroundStyle(.white).frame(maxWidth:.infinity,minHeight:36).background(Color(red:0.40,green:0.48,blue:0.75),in:RoundedRectangle(cornerRadius:10)).overlay(RoundedRectangle(cornerRadius:10).stroke(selectedBoardTile == "O:\(symbol)" ? Color.orange : .clear,lineWidth:2)).draggable("O:\(symbol)").onTapGesture{selectedBoardTile="O:\(symbol)"} } }
                Button { if let result=evaluateBoard(q) { let isCorrect=abs(result - (Double(q.answer) ?? 0)) < 0.0001;boardAnswer=isCorrect ? "correct":"wrong";showBoardFeedback=true;answered=isCorrect;if isCorrect{round += 1;awardCorrectAnswerXP(for:selectedTopic?.id ?? "number");streak=max(streak,1)}else{recordTopicAnswer(selectedTopic?.id ?? "number",correct:false,question:q)} } } label:{Text(boardAnswer == "wrong" ? "Try this equation" : "Check my equation").font(.system(size:12,weight:.bold)).foregroundStyle(.white).frame(maxWidth:.infinity).padding(.vertical,10).background(evaluateBoard(q) == nil || answered ? Color.gray.opacity(0.45):Color(red:0.27,green:0.61,blue:0.53),in:Capsule())}.buttonStyle(.plain).disabled(evaluateBoard(q) == nil || answered)
                Button("Clear board") { resetBoard(for:q);boardAnswer=nil;showBoardFeedback=false;selectedBoardTile=nil }.font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary).buttonStyle(.plain).disabled(answered)
            }.padding(13).background(boardPanelSurface,in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(Color.black.opacity(0.06),lineWidth:1))
            Spacer(minLength:0)
            Text("You can still tap an answer on the left.").font(.system(size:10)).foregroundStyle(.tertiary).multilineTextAlignment(.center).frame(maxWidth:.infinity)
        }.padding(15).frame(maxHeight:.infinity,alignment:.top).background(numberBoardSurface,in:RoundedRectangle(cornerRadius:20))
    }

    @ViewBuilder private func equationBuilder(_ q:Question)->some View {
        VStack(spacing:4) {
            ForEach(q.operands.indices,id:\.self) { index in
                dropSlot(text: boardValues.indices.contains(index) ? boardValues[index].map(String.init) : nil, kind:"N", minWidth:96) { token in
                    guard let number=Int(token) else{return};while boardValues.count < q.operands.count { boardValues.append(nil) };boardValues[index]=number
                }
                if index < q.operands.count-1 {
                    dropSlot(text: boardOperators.indices.contains(index) ? boardOperators[index] : nil, kind:"O", minWidth:58) { token in
                        while boardOperators.count < q.operands.count-1 { boardOperators.append(nil) };boardOperators[index]=token
                    }
                }
            }
            Rectangle().fill(ink.opacity(0.25)).frame(width:125,height:1).padding(.vertical,3)
            Text("= \(evaluateBoard(q).map(formatted) ?? "?")").font(.system(size:17,weight:.black,design:.rounded)).foregroundStyle(ink).frame(maxWidth:.infinity)
        }.frame(maxWidth:.infinity)
    }

    private func fractionBoard(_ q:Question)->some View {
        let denominator = fractionParts(q.answer)?.1 ?? 1
        let placedCount = fractionPieces.count
        return VStack(alignment:.leading,spacing:12) {
            HStack(spacing:8){Image(systemName:"circle.lefthalf.filled").foregroundStyle(Color(red:0.78,green:0.30,blue:0.54));Text("FRACTION CIRCLES").font(.system(size:11,weight:.black,design:.rounded)).tracking(0.8)}
            Text("Same amount, different number of pieces.").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary)
            VStack(spacing:8) {
                Text("Build an equivalent fraction with your circle.").font(.system(size:11,weight:.bold)).foregroundStyle(ink).multilineTextAlignment(.center)
                Text("Tap your circle to add a piece.").font(.system(size:10,weight:.medium)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                VStack(spacing:5) {
                    Text("Your circle").font(.system(size:10,weight:.bold)).foregroundStyle(ink)
                    Button { tapYourFractionCircle(denominator:denominator) } label: {
                        FractionCircleView(numerator:placedCount,denominator:denominator,size:66)
                            .contentShape(Circle())
                    }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add a piece to your circle")
                    Text("\(placedCount)/\(denominator)").font(.system(size:12,weight:.black,design:.rounded)).foregroundStyle(ink)
                    Text("\(denominator) equal pieces total").font(.system(size:9,weight:.medium)).foregroundStyle(.secondary)
                }.frame(maxWidth:.infinity).padding(.vertical,2)
                HStack(spacing:8) {
                    Button("Undo") { if let last=fractionPieces.max(){fractionPieces.remove(last)} }
                        .font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary).buttonStyle(.plain).disabled(placedCount == 0 || answered)
                    Spacer()
                    Button("Clear circle") { fractionPieces.removeAll() }
                        .font(.system(size:10,weight:.semibold)).foregroundStyle(.secondary).buttonStyle(.plain).disabled(placedCount == 0 || answered)
                }
                Button { checkFraction(q) } label: {
                    Text("Check fraction").font(.system(size:12,weight:.bold)).foregroundStyle(.white).frame(maxWidth:.infinity).padding(.vertical,10).background(placedCount == 0 || answered ? Color.gray.opacity(0.45):Color(red:0.78,green:0.30,blue:0.54),in:Capsule())
                }.buttonStyle(.plain).disabled(placedCount == 0 || answered)
            }.padding(13).frame(maxWidth:.infinity).background(boardPanelSurface,in:RoundedRectangle(cornerRadius:18)).overlay(RoundedRectangle(cornerRadius:18).stroke(Color.black.opacity(0.06),lineWidth:1))
            if answered && boardAnswer == "wrong" {
                Text("Not quite — your circle shows \(placedCount)/\(denominator). Try changing the number of pieces.")
                    .font(.system(size:10,weight:.semibold)).foregroundStyle(.red).multilineTextAlignment(.center).frame(maxWidth:.infinity)
            }
            if answered && selectedAnswer == q.answer { Text("Both circles shade the same part of a whole.").font(.system(size:10,weight:.semibold)).foregroundStyle(.green).multilineTextAlignment(.center).frame(maxWidth:.infinity) }
            Spacer(minLength:0)
        }.padding(15).frame(maxHeight:.infinity,alignment:.top).background(fractionBoardSurface,in:RoundedRectangle(cornerRadius:20))
    }

    private func fractionParts(_ text:String)->(Int,Int)? {
        let parts=text.split(separator:"/");guard parts.count==2,let n=Int(parts[0]),let d=Int(parts[1]),d>0 else{return nil};return(n,d)
    }

    private func fractionChoiceButton(_ value:String,_ q:Question)->some View {
        let isSelected=selectedAnswer == value && answered
        let isPreview=fractionPreview == value && !answered
        let foreground:Color = isSelected ? (value == q.answer ? .green : .red) : ink
        let background:Color = isSelected ? (value == q.answer ? Color.green.opacity(0.1) : Color.red.opacity(0.08)) : (isPreview ? Color.orange.opacity(0.12) : surface)
        return Button { choose(value,q) } label: {
            HStack(spacing:10) {
                Text(value).font(.system(size:14,weight:.black,design:.rounded))
                Spacer()
                if isSelected { Image(systemName:value == q.answer ? "checkmark.circle.fill":"xmark.circle.fill") }
                else if isPreview { Image(systemName:"circle.inset.filled").foregroundStyle(.orange) }
            }.foregroundStyle(foreground).padding(8).frame(maxWidth:.infinity).background(background,in:RoundedRectangle(cornerRadius:13))
        }.buttonStyle(.plain).disabled(answered)
    }

    private func dropSlot(text:String?,kind:String,minWidth:CGFloat,onDrop:@escaping(String)->Void)->some View {
        RoundedRectangle(cornerRadius:9).fill(text == nil ? surface : slotValueSurface).frame(minWidth:minWidth,maxWidth:.infinity,minHeight:41).overlay(RoundedRectangle(cornerRadius:9).strokeBorder(Color.gray.opacity(0.35),style:StrokeStyle(lineWidth:1.5,dash:[5,4]))).overlay {
            Text(text ?? (kind == "N" ? "?" : "op")).font(.system(size:17,weight:.black,design:.rounded)).foregroundStyle(ink)
        }.dropDestination(for:String.self) { items, _ in
            guard !answered, let item=items.first, item.hasPrefix(kind+":") else{return false}
            onDrop(String(item.dropFirst(2)));selectedBoardTile=nil;boardAnswer=nil;showBoardFeedback=false;return true
        }.onTapGesture {
            guard !answered,let item=selectedBoardTile,item.hasPrefix(kind+":") else{return}
            onDrop(String(item.dropFirst(2)));selectedBoardTile=nil;boardAnswer=nil;showBoardFeedback=false
        }
    }

    private func evaluateBoard(_ q:Question)->Double? {
        guard boardValues.count == q.operands.count,boardOperators.count == q.operands.count-1,
              boardValues.allSatisfy({$0 != nil}),boardOperators.allSatisfy({$0 != nil}) else{return nil}
        var numbers=boardValues.compactMap{ $0 }.map(Double.init)
        var ops=boardOperators.compactMap{$0}
        // Powers bind more tightly than multiplication and are evaluated right to left.
        var powerIndex=ops.count-1
        while powerIndex >= 0 {
            if ops[powerIndex] == "^" {
                let value=pow(numbers[powerIndex],numbers[powerIndex+1])
                guard value.isFinite else{return nil}
                numbers[powerIndex]=value
                numbers.remove(at:powerIndex+1);ops.remove(at:powerIndex)
            }
            powerIndex -= 1
        }
        var i=0
        while i < ops.count {
            if ops[i] == "×" || ops[i] == "÷" {
                guard ops[i] != "÷" || numbers[i+1] != 0 else{return nil}
                numbers[i] = ops[i] == "×" ? numbers[i]*numbers[i+1] : numbers[i]/numbers[i+1]
                numbers.remove(at:i+1);ops.remove(at:i)
            } else { i += 1 }
        }
        var result=numbers[0]
        for (index,op) in ops.enumerated() { result += op == "+" ? numbers[index+1] : -numbers[index+1] }
        return result.isFinite ? result : nil
    }

    private func formatted(_ result:Double)->String { result.rounded() == result ? String(Int(result)) : String(format:"%.2f",result) }
    private func answerColor(_ c:String,_ q:Question)->Color { guard answered,selectedAnswer==c else{return ink};return c==q.answer ? .green : .red }
    private func answerBackground(_ c:String,_ q:Question)->Color { guard answered,selectedAnswer==c else{return surface};return c==q.answer ? Color.green.opacity(0.1):Color.red.opacity(0.08) }
    private func answerStroke(_ c:String,_ q:Question)->Color { guard answered,selectedAnswer==c else{return .clear};return c==q.answer ? .green:.red }
    private func choose(_ choice:String,_ q:Question){
        if q.fractionNumerator != nil && !answered { fractionPreview=choice;return }
        selectedAnswer=choice;answered=true;boardAnswer=choice == q.answer ? "correct":"wrong";showBoardFeedback=true;round += 1;if choice==q.answer{awardCorrectAnswerXP(for:selectedTopic?.id ?? "number");streak=max(streak,1)}else{recordTopicAnswer(selectedTopic?.id ?? "number",correct:false,question:q)}
    }
    private func checkFraction(_ q:Question){
        guard let (_, targetDenominator)=fractionParts(q.answer), let (answerNumerator, answerDenominator)=fractionParts(q.answer), !fractionPieces.isEmpty else{return}
        let isCorrect=fractionPieces.count * answerDenominator == answerNumerator * targetDenominator
        selectedAnswer=isCorrect ? q.answer : "\(fractionPieces.count)/\(targetDenominator)";answered=true;boardAnswer=isCorrect ? "correct":"wrong";showBoardFeedback=true;round += 1
        if isCorrect { awardCorrectAnswerXP(for:selectedTopic?.id ?? "fractions");streak=max(streak,1) } else { recordTopicAnswer(selectedTopic?.id ?? "fractions",correct:false,question:q) }
    }
    private func retryFraction(){
        answered=false;selectedAnswer=nil;fractionPieces.removeAll();boardAnswer=nil;showBoardFeedback=false
    }
    private func tapYourFractionCircle(denominator:Int){
        guard !answered else{return}
        if let next=(0..<denominator).first(where:{!fractionPieces.contains($0)}) { fractionPieces.insert(next) }
    }
    private func resetBoard(for q:Question){boardValues=Array(repeating:nil,count:q.operands.count);boardOperators=Array(repeating:nil,count:max(0,q.operands.count-1));selectedBoardTile=nil}
    private func nextQuestion(){activeReviewChallengeID=nil;selectedAnswer=nil;fractionPreview=nil;fractionPieces=[];boardAnswer=nil;showBoardFeedback=false;answered=false;showHint=false;let q=questionGenerator.makeQuestion(topic:selectedTopic ?? topics[0],grade:grade);question=q;resetBoard(for:q)}
    private func startGame(topic:Topic){activeReviewChallengeID=nil;selectedTopic=topic;selectedTab="Home";round=0;selectedAnswer=nil;fractionPreview=nil;fractionPieces=[];boardAnswer=nil;showBoardFeedback=false;answered=false;showHint=false;let q=questionGenerator.makeQuestion(topic:topic,grade:grade);question=q;resetBoard(for:q)}
    private func startReview(_ challenge:ReviewChallenge){
        guard let topic=topics.first(where:{$0.id == challenge.topicID}) else{return}
        grade=challenge.grade;selectedTopic=topic;selectedTab="Review";question=challenge.question;activeReviewChallengeID=challenge.id;selectedAnswer=nil;fractionPreview=nil;fractionPieces=[];boardAnswer=nil;showBoardFeedback=false;answered=false;showHint=false;resetBoard(for:challenge.question)
    }
    private func retryReviewedQuestion(_ q:Question){
        selectedAnswer=nil;fractionPreview=nil;fractionPieces=[];boardAnswer=nil;showBoardFeedback=false;answered=false;showHint=false;resetBoard(for:q)
    }
    private func finishReview(){
        activeReviewChallengeID=nil;question=nil;selectedAnswer=nil;fractionPreview=nil;fractionPieces=[];boardAnswer=nil;showBoardFeedback=false;answered=false;showHint=false;selectedTab="Review"
    }
    private func navigate(to page:String){ activeReviewChallengeID=nil;selectedTab=page; question=nil; selectedAnswer=nil; fractionPreview=nil;fractionPieces=[]; boardAnswer=nil; showBoardFeedback=false; answered=false }

    private func exampleToken(_ value:String,_ tint:Color = Color(red:0.91,green:0.94,blue:0.98))->some View {
        Text(value).font(.system(size:15,weight:.black,design:.rounded)).foregroundStyle(Color.black.opacity(0.82)).padding(.horizontal,10).padding(.vertical,7).background(tint,in:RoundedRectangle(cornerRadius:9))
    }

    @ViewBuilder private func visualExampleView()->some View {
        VStack(spacing:9) {
            HStack(spacing:5) {
                Image(systemName:"lightbulb").font(.system(size:9,weight:.bold))
                Text("VISUAL EXAMPLE").font(.system(size:10,weight:.black,design:.rounded)).tracking(0.8)
            }.foregroundStyle(ink.opacity(0.78)).frame(maxWidth:.infinity,alignment:.leading)
            switch selectedTopic?.id {
            case "fractions":
                HStack(spacing:5){exampleToken("a / b");exampleToken("× k / k");Image(systemName:"arrow.right").foregroundStyle(.secondary);exampleToken("? / ?",.green.opacity(0.2))}
            case "number":
                if grade <= 3 {HStack(spacing:5){exampleToken("a");exampleToken("+",.orange.opacity(0.2));exampleToken("b");exampleToken("=");exampleToken("?",.green.opacity(0.2))}}
                else if grade <= 8 {HStack(spacing:5){exampleToken("two-digit × two-digit");exampleToken("→");exampleToken("partial products",.green.opacity(0.2))}}
                else {HStack(spacing:4){exampleToken("principal × rate × time");exampleToken("÷ 100");exampleToken("= ?",.green.opacity(0.2))}}
            case "algebra":
                HStack(spacing:5){exampleToken("unknown + amount = total");Image(systemName:"arrow.right").foregroundStyle(.secondary);exampleToken("total − amount",.green.opacity(0.2))}
            case "measurement":
                if grade <= 5 {HStack(spacing:5){exampleToken("parallelogram: b × h");exampleToken("triangle: b × h ÷ 2",.green.opacity(0.2))}}
                else if grade <= 8 {HStack(spacing:5){exampleToken("length × width × height");exampleToken("= volume",.green.opacity(0.2))}}
                else {HStack(spacing:5){exampleToken("circle area: π × r²");exampleToken("circumference: 2πr",.green.opacity(0.2))}}
            case "spatial":
                HStack(spacing:8){Image(systemName:"triangle").font(.system(size:32,weight:.medium)).foregroundStyle(Color.teal);Image(systemName:"arrow.right").foregroundStyle(.secondary);exampleToken(grade <= 5 ? "compare sides and angles" : "identify geometric properties",.green.opacity(0.2))}
            case "data":
                HStack(alignment:.bottom,spacing:8){ForEach(Array([24,38,18,50].enumerated()),id:\.offset){index,item in VStack(spacing:3){RoundedRectangle(cornerRadius:4).fill([Color.blue,Color.orange,Color.green,Color.purple][index].opacity(0.65)).frame(width:24,height:CGFloat(item));Text(["A","B","C","Σ"][index]).font(.system(size:9,weight:.bold))}}}
            case "decimals_percentages":
                HStack(spacing:7){exampleToken("fraction");Image(systemName:"↔").foregroundStyle(.secondary);exampleToken("decimal",.green.opacity(0.18));exampleToken("↔");exampleToken("percent")}
            case "probability":
                HStack(spacing:5){exampleToken("favourable outcomes");exampleToken("÷");exampleToken("all outcomes");exampleToken("=");exampleToken("probability",.green.opacity(0.2))}
            case "data_visualization":
                VStack(alignment:.leading,spacing:6) {
                    Text("Each bar is one group; colours show its categories.")
                        .font(.system(size:10,weight:.semibold)).foregroundStyle(ink)
                    HStack(spacing:5) {
                        Text("Group A").font(.system(size:9,weight:.bold)).frame(width:48,alignment:.leading)
                        stackedSegment("3",width:36,color:Color(red:0.16,green:0.38,blue:0.68))
                        stackedSegment("2",width:24,color:Color(red:0.68,green:0.32,blue:0.14))
                        Text("5 total").font(.system(size:9,weight:.bold)).foregroundStyle(ink)
                    }
                    HStack(spacing:5) {
                        Text("Group B").font(.system(size:9,weight:.bold)).frame(width:48,alignment:.leading)
                        stackedSegment("2",width:24,color:Color(red:0.16,green:0.38,blue:0.68))
                        stackedSegment("4",width:48,color:Color(red:0.68,green:0.32,blue:0.14))
                        Text("6 total").font(.system(size:9,weight:.bold)).foregroundStyle(ink)
                    }
                    HStack(spacing:10) {
                        legendDot("Type A",color:Color(red:0.16,green:0.38,blue:0.68))
                        legendDot("Type B",color:Color(red:0.68,green:0.32,blue:0.14))
                        Text("Add group totals to find all items.").font(.system(size:9,weight:.semibold)).foregroundStyle(ink.opacity(0.8))
                    }
                }.frame(maxWidth:.infinity,alignment:.leading)
            case "coding_algorithms":
                HStack(spacing:5){exampleToken("start value");Image(systemName:"arrow.right").foregroundStyle(.secondary);exampleToken("repeat: add k");Image(systemName:"arrow.right").foregroundStyle(.secondary);exampleToken("check condition");Image(systemName:"arrow.right").foregroundStyle(.secondary);exampleToken("output")}
            case "mathematical_modelling":
                HStack(spacing:5){Image(systemName:"bus.fill").foregroundStyle(.teal);exampleToken("fixed fee");exampleToken("+");exampleToken("cost per person × group");exampleToken("=");exampleToken("?")}
            case "mental_math_place_value":
                HStack(spacing:5){exampleToken("digit");exampleToken("×");exampleToken("place value");exampleToken("=");exampleToken("digit value",.green.opacity(0.2))}
            case "triangles_transformations":
                HStack(spacing:5){exampleToken("P(x, y)");Image(systemName:"arrow.right").foregroundStyle(.secondary);exampleToken("P(x + Δx, y)",.green.opacity(0.2))}
            case "budgeting_credit":
                HStack(spacing:5){Image(systemName:"dollarsign.circle.fill").foregroundStyle(.green);exampleToken("income");exampleToken("−");exampleToken("needs");exampleToken("−");exampleToken("savings");exampleToken("=");exampleToken("?")}
            default:
                HStack(spacing:7){ForEach(0..<3,id:\.self){index in Circle().fill(Color.yellow.opacity(0.35)).frame(width:32,height:32).overlay(Text("coin\(index+1)").font(.system(size:8,weight:.black)))};Image(systemName:"arrow.right").foregroundStyle(.secondary);exampleToken("choose an operation",.green.opacity(0.2))}
            }
        }
        .frame(maxWidth:.infinity,minHeight:78)
        .padding(9)
        .background(Color.blue.opacity(0.06),in:RoundedRectangle(cornerRadius:14))
        .accessibilityLabel("Visual example showing a general method, not the answer to the current question")
    }

    private func stackedSegment(_ value:String,width:CGFloat,color:Color)->some View {
        Text(value).font(.system(size:10,weight:.black,design:.rounded)).foregroundStyle(.white)
            .frame(width:width,height:22).background(color)
    }

    private func legendDot(_ title:String,color:Color)->some View {
        HStack(spacing:3){RoundedRectangle(cornerRadius:2).fill(color).frame(width:8,height:8);Text(title).font(.system(size:8,weight:.semibold)).foregroundStyle(ink)}
    }

    private var parentSheet: some View {
        VStack(alignment:.leading,spacing:16) {
            HStack{Image(systemName:"leaf.fill").foregroundStyle(.green);Text("For grown-ups").font(.system(size:22,weight:.black,design:.rounded));Spacer();Button("Done"){showParent=false}.buttonStyle(.bordered)}
            Text("Math Quest is organized around the shared foundations of Canadian provincial and territorial curricula. Exact sequencing and expectations vary by province or territory.").font(.system(size:13)).foregroundStyle(.secondary)
            Text("Learning modules • Grades 1–12").font(.system(size:15,weight:.bold))
            ForEach([("Number & operations","Counting, place value and arithmetic"),("Fractions","Equivalent fractions and circle models (Grades 2–8)"),("Decimals & percentages","Relate decimal, percent and fraction forms"),("Probability","Chance experiments and outcomes"),("Data visualization","Create and read charts; compare data"),("Algebra","Patterns, relationships, variables and equations"),("Coding & algorithms","Follow rules that generate number patterns"),("Mathematical modelling","Represent and solve real-world problems"),("Geometry","Shapes, angles, location and transformations"),("Triangles & transformations","Classify triangles and move shapes on a grid"),("Measurement","Length, time, mass, area, perimeter, volume and units"),("Data","Collect, organize, represent and interpret data"),("Financial literacy","Money, needs, wants, spending and saving"),("Budgeting & credit","Plan budgets and explore borrowing and interest")],id:\.0){item in HStack(alignment:.top,spacing:9){Image(systemName:"checkmark.seal.fill").foregroundStyle(.green);VStack(alignment:.leading,spacing:3){Text(item.0).font(.system(size:13,weight:.bold));Text(item.1).font(.system(size:11)).foregroundStyle(.secondary)}}}
            Divider();Text("This starter build provides an expandable foundation and sample adaptive question generators. A complete province-aligned curriculum would need the target province and reviewed learning outcomes for each grade.").font(.system(size:11,weight:.medium)).foregroundStyle(.secondary)
        }.padding(25).frame(width:510)
    }
}

#Preview { ContentView() }
