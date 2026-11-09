import Foundation

struct QuestionGenerator {
    private var recentQuestionPrompts: [String: [String]] = [:]
    private var recentQuestionPatterns: [String: [String]] = [:]
    private var recentPlaceLabels: [String: String] = [:]

    mutating func makeQuestion(topic:Topic,grade:Int)->Question {
        // Randomized values alone can still feel repetitive. Keep a short per-topic
        // history and reroll any exact prompt the player has just seen.
        let key="\(topic.id)-\(grade)"
        let recent=recentQuestionPrompts[key] ?? []
        let recentPatterns=recentQuestionPatterns[key] ?? []
        var candidate=generateQuestion(topic:topic,grade:grade)
        var patternRerolls=0
        for _ in 0..<30 {
            let label=placeLabel(in:candidate.prompt)
            let pattern=promptPattern(candidate.prompt)
            let repeatedPattern=recentPatterns.contains(pattern)
            if !recent.contains(candidate.prompt) && (!repeatedPattern || patternRerolls >= 3) && (label == nil || label != recentPlaceLabels[key]) { break }
            if repeatedPattern { patternRerolls += 1 }
            candidate=generateQuestion(topic:topic,grade:grade)
        }
        recentQuestionPrompts[key]=Array(([candidate.prompt]+recent).prefix(12))
        recentQuestionPatterns[key]=Array(([promptPattern(candidate.prompt)]+recentPatterns).prefix(1))
        if let label=placeLabel(in:candidate.prompt) { recentPlaceLabels[key]=label }
        return candidate
    }

    private func promptPattern(_ prompt:String)->String {
        let range=NSRange(prompt.startIndex..<prompt.endIndex,in:prompt)
        let normalized=(try? NSRegularExpression(pattern:"[0-9]+(?:[.,][0-9]+)?"))?.stringByReplacingMatches(in:prompt,range:range,withTemplate:"#") ?? prompt
        return normalized.lowercased().split(whereSeparator:\.isWhitespace).joined(separator:" ")
    }

    private func placeLabel(in prompt:String)->String? {
        ["hundred-thousands","ten-thousands","thousands","hundreds","tens","ones"].first { prompt.contains("the \($0) place") }
    }

    private func placeName(_ place:Int)->String {
        switch place { case 100000:return "hundred-thousands";case 10000:return "ten-thousands";case 1000:return "thousands";case 100:return "hundreds";case 10:return "tens";default:return "ones" }
    }

    private func generateQuestion(topic:Topic,grade:Int)->Question {
        let g=grade
        if g == 5,let gradeFiveQuestion=makeGradeFiveQuestion(topic) { return gradeFiveQuestion }
        if g == 6,let gradeSixQuestion=makeGradeSixQuestion(topic) { return gradeSixQuestion }
        if g == 4,let gradeFourQuestion=makeGradeFourQuestion(topic) { return gradeFourQuestion }
        switch topic.id {
        case "fractions": return makeFractionQuestion(grade:g)
        case "number":
            if g <= 3 {
                let a=Int.random(in:10...50),b=Int.random(in:2...30)
                if Bool.random() { return build("A trail has \(a) markers and the rangers add \(b). How many markers now?",ans:a+b,story:"Help Maple count the trail markers.",hint:"Add the tens and ones, then check your total.",operands:[a,b],operators:["+"]) }
                return build("There are \(a+b) apples. \(b) are packed for lunch. How many stay in the basket?",ans:a,story:"Pack the right number of apples for the explorers.",hint:"Find the missing part by subtracting.",operands:[a+b,b],operators:["−"])
            } else if g <= 6 {
                if Bool.random() {let x=Int.random(in:12...99),y=Int.random(in:12...99);return build("A library has \(x) shelves with \(y) books on each. How many books?",ans:x*y,story:"Help the librarian organize the collection.",hint:"Multiply the number of shelves by books per shelf.",operands:[x,y],operators:["×"])}
                let a=Int.random(in:120...999),b=Int.random(in:110...899),c=Int.random(in:2...9)
                let product=Int.random(in:12...24)*c
                return build("A school orders \(a) pencils and \(b) more. Then \(c) boxes hold \(product/c) pencils each. How many pencils altogether?",ans:a+b+product,story:"Plan the supply delivery using multi-step arithmetic.",hint:"Multiply the boxes first, then add both amounts.",operands:[a,b,c,product/c],operators:["+","+","×"])
            } else if g <= 8 {
                if Bool.random() {let total=Int.random(in:150...900),groups=Int.random(in:3...12);let quotient=total/groups;return build("A team shares \(quotient*groups) points equally among \(groups) players. How many points each?",ans:quotient,story:"Share the tournament points fairly.",hint:"Divide the total points by the number of players.",operands:[quotient*groups,groups],operators:["÷"])}
                let base=Int.random(in:3...9),square=base*base,groups=Int.random(in:3...8),extra=Int.random(in:10...60)
                return build("A game scores \(base)² points, then \(groups) bonus rounds worth \(extra) points each. Total?",ans:square+groups*extra,story:"Combine square numbers and bonus points to unlock the next level.",hint:"Evaluate the exponent first, multiply the bonus, then add.",operands:[base,2,groups,extra],operators:["^","+","×"])
            } else {
                if Bool.random() {let price=Int.random(in:80...900),rate=Int.random(in:5...35);return build("A jacket costs $\(price) and is reduced by \(rate)%. Find the discount amount.",ans:Double(price)*Double(rate)/100,story:"Compare a sale before choosing what to buy.",hint:"Multiply the price by the rate, then divide by 100. Give your answer in dollars and cents.",operands:[price,rate,100],operators:["×","÷"])}
                let principal=Int.random(in:200...1500),rate=Int.random(in:3...9),years=Int.random(in:2...5)
                return build("Simple interest: $\(principal) is saved at \(rate)% per year for \(years) years. How much interest is earned?",ans:Double(principal)*Double(rate)*Double(years)/100,story:"Compare savings plans and calculate the interest earned.",hint:"Use principal × rate × years ÷ 100. Give your answer in dollars and cents.",operands:[principal,rate,years,100],operators:["×","×","÷"])
            }
        case "algebra":
            if g <= 3 {let start=Int.random(in:2...15),step=Int.random(in:2...9);return build("Pattern: \(start), \(start+step), \(start+2*step), __",ans:start+3*step,story:"Find the rule in Maple's stepping-stone pattern.",hint:"Look at how much the pattern changes each time.",operands:[start+2*step,step],operators:["+"])}
            if g <= 6 {let x=Int.random(in:4...30),b=Int.random(in:5...40);return build("Solve for n: n + \(b) = \(x+b)",ans:x,story:"Find the number hidden in the mystery box.",hint:"Undo the addition by subtracting \(b) from both sides.",operands:[x+b,b],operators:["−"])}
            if g <= 8 {let x=Int.random(in:3...15),factor=Int.random(in:3...9);return build("Solve for n: \(factor)n = \(factor*x)",ans:x,story:"Balance the equation to reveal the mystery value.",hint:"Divide both sides by \(factor).",operands:[factor*x,factor],operators:["÷"])}
            if g <= 10 {let slope=Int.random(in:2...8),x=Int.random(in:3...12),b=Int.random(in:1...20);return build("For y = \(slope)x + \(b), find y when x = \(x).",ans:slope*x+b,story:"Use a linear rule to predict the next point on a graph.",hint:"Substitute x, multiply first, then add.",operands:[slope,x,b],operators:["×","+"])}
            if g == 11 {let a=Int.random(in:2...6),x=Int.random(in:2...7),b=Int.random(in:2...20);return build("For f(x) = \(a)x² + \(b), find f(\(x)).",ans:a*x*x+b,story:"Explore a quadratic pattern by evaluating its function rule.",hint:"Square x first, multiply by the coefficient, then add.",operands:[a,x,2,b],operators:["×","^","+"])}
            let a=Int.random(in:1...5),base=Int.random(in:2...3),x=Int.random(in:2...5),b=Int.random(in:2...20)
            return build("For f(x) = \(a) × \(base)^x + \(b), find f(\(x)).",ans:a*Int(pow(Double(base),Double(x)))+b,story:"Evaluate an exponential growth rule for a given input.",hint:"Find the power first, multiply by \(a), then add \(b).",operands:[a,base,x,b],operators:["×","^","+"])
        case "measurement":
            if g <= 3 {let w=Int.random(in:3...12),h=Int.random(in:2...10);if Bool.random(){return build("A garden is \(w) m by \(h) m. What is its area?",ans:w*h,story:"Maple is planning a rectangular garden.",hint:"Area is length times width.",operands:[w,h],operators:["×"])};let pieces=Int.random(in:2...8),each=Int.random(in:2...6);return build("A \(pieces*each) cm ribbon is cut into \(pieces) equal pieces. How long is each piece?",ans:each,story:"Cut ribbon for the explorers' badges.",hint:"Share the total length equally.",operands:[each,pieces],operators:["×"])}
            if g <= 6 {let w=Int.random(in:12...45),h=Int.random(in:8...32);if Bool.random(){return build("A rectangular mural is \(w) m wide and \(h) m high. Find its area.",ans:w*h,story:"Estimate the paintable area of a community mural.",hint:"Multiply width by height; area is in square metres.",operands:[w,h],operators:["×"])};return build("A rectangular field is \(w) m by \(h) m. Find the distance around it.",ans:2*w+2*h,story:"Plan the amount of fencing needed for the field.",hint:"Add twice the length and twice the width.",operands:[2,w,2,h],operators:["×","+","×"])}
            if g <= 8 {if Bool.random(){let l=Int.random(in:5...18),w=Int.random(in:3...12),h=Int.random(in:2...9);return build("A storage box is \(l) cm × \(w) cm × \(h) cm. Find its volume.",ans:l*w*h,story:"Pack the explorer's equipment into a rectangular box.",hint:"Volume = length × width × height.",operands:[l,w,h],operators:["×","×"])};let km=Int.random(in:2...18);return build("A hike is \(km) km long. How many metres is that?",ans:km*1000,story:"Convert the route length into metres for the trail map.",hint:"One kilometre equals 1,000 metres.",operands:[km,1000],operators:["×"])}
            let r=Int.random(in:3...15);return build("Using π ≈ 3, find the area of a circle with radius \(r) cm.",ans:3*r*r,story:"Design a circular garden bed and estimate its area.",hint:"Circle area = π × radius × radius. Use π ≈ 3.",operands:[3,r,r],operators:["×","×"])
        case "spatial":
            if g <= 3 {let sides=Int.random(in:3...6),groups=Int.random(in:2...5);if Bool.random(){return build("Each shape has \(sides) sides. How many sides do \(groups) shapes have?",ans:sides*groups,story:"Count all the sides in a set of shape tiles.",hint:"Multiply sides per shape by the number of shapes.",operands:[sides,groups],operators:["×"])};let corners=Int.random(in:3...8);return build("A polygon has \(corners) corners. How many vertices does it have?",ans:corners,story:"Name the corners on a shape in Maple's map.",hint:"A vertex is a corner of a shape.",operands:[corners],operators:[])}
            if g <= 6 {let l=Int.random(in:8...30),w=Int.random(in:5...22);if Bool.random(){return build("A rectangular field is \(l) m by \(w) m. What is its perimeter?",ans:2*l+2*w,story:"Map a fence around the rectangular field.",hint:"Perimeter = 2 × length + 2 × width.",operands:[2,l,2,w],operators:["×","+","×"])};let a=Int.random(in:25...155);return build("A straight angle is 180°. One part is \(a)°. Find the other part.",ans:180-a,story:"Rotate the compass to complete the straight angle.",hint:"Angles on a straight line add to 180°.",operands:[180,a],operators:["−"])}
            if g <= 8 {if Bool.random(){let map=Int.random(in:3...12),scale=Int.random(in:4...15);return build("On a map, a trail is \(map) cm long. The scale is 1 cm = \(scale) km. What is the real distance?",ans:map*scale,story:"Use the map scale to plan a hiking route.",hint:"Multiply map distance by kilometres per centimetre.",operands:[map,scale],operators:["×"])};let angle=Int.random(in:35...145);return build("Two angles in a triangle are 40° and \(angle)°. Find the third angle.",ans:140-angle,story:"Solve the final angle in a triangle puzzle.",hint:"The angles in a triangle add to 180°.",operands:[180,40,angle],operators:["−","−"])}
            let r=Int.random(in:4...30);return build("Using π ≈ 3, find the circumference of a circle with radius \(r) cm.",ans:6*r,story:"Measure the distance around a circular track.",hint:"Circumference = 2 × π × radius. Use π ≈ 3.",operands:[2,3,r],operators:["×","×"])
        case "data":
            if g <= 3 {let a=Int.random(in:3...9),b=Int.random(in:2...8),c=Int.random(in:4...10);return build("Pine cones: \(a) • Acorns: \(b) • Berries: \(c). How many altogether?",ans:a+b+c,story:"Read Maple's forest picture graph.",hint:"Add the three categories.",operands:[a,b,c],operators:["+","+"])}
            if g <= 8 {let a=Int.random(in:10...45),b=Int.random(in:4...9),c=Int.random(in:15...65),small=min(a,min(b,c)),large=max(a,max(b,c));if Bool.random(){return build("A data set has values \(a), \(b), and \(c). What is the range?",ans:large-small,story:"Compare the spread in three teams' scores.",hint:"Range = largest value − smallest value.",operands:[large,small],operators:["−"])};let score=[12,16,20].randomElement() ?? 12;return build("Four quiz scores are 6, 8, 10 and \(score). What is their total?",ans:24+score,story:"Add the team's scores before posting the results.",hint:"Add all four scores together.",operands:[6,8,10,score],operators:["+","+","+"])}
            let total=Int.random(in:40...200),part=Int.random(in:10...total/2);return build("\(part) of \(total) students chose cycling. What percent is that? (nearest whole percent)",ans:Int((Double(part)/Double(total)*100).rounded()),story:"Turn survey results into a percentage for the class chart.",hint:"Divide part by total, then multiply by 100.",operands:[part,100,total],operators:["×","÷"])
        case "decimals_percentages":
            if Bool.random() {
                let percent=[10,20,25,40,50,60,75,80].randomElement() ?? 25
                let decimal=String(format:"%.2f",Double(percent)/100).replacingOccurrences(of:"0$",with:"",options:.regularExpression)
                return build("Write \(decimal) as a percent.",ans:percent,story:"Connect a decimal amount to its percent form.",hint:"A decimal-to-percent conversion multiplies by 100.",operands:[percent],operators:[])
            }
            let percent=[10,20,25,30,40,50,60,75,80].randomElement() ?? 25,amount=Int.random(in:4...20)*25
            return build("What is \(percent)% of \(amount)?",ans:percent*amount/100,story:"Use a percent to find a part of a whole amount.",hint:"Convert the percent to hundredths, then multiply by the amount.",operands:[amount,percent,100],operators:["×","÷"])
        case "probability":
            let total=[4,5,10,20].randomElement() ?? 10, favorable=Int.random(in:1...total)
            return build("A bag has \(favorable) winning tickets out of \(total). What is the probability as a percent?",ans:favorable*100/total,story:"Compare the number of favorable outcomes with all possible outcomes.",hint:"Probability percent = favorable outcomes ÷ total outcomes × 100.",operands:[favorable,100,total],operators:["×","÷"])
        case "data_visualization":
            let values=(0..<4).map{_ in Int.random(in:2...15)},low=values.min() ?? 0,high=values.max() ?? 0
            let chart="Team A ▮\(String(repeating:"▮",count:values[0]))  Team B ▮\(String(repeating:"▮",count:values[1]))  Team C ▮\(String(repeating:"▮",count:values[2]))  Team D ▮\(String(repeating:"▮",count:values[3]))"
            return build("\(chart). How many more does the largest bar show than the smallest?",ans:high-low,story:"Read the bar chart and compare its values.",hint:"Find the tallest bar and shortest bar, then subtract.",operands:[high,low],operators:["−"])
        case "coding_algorithms":
            switch Int.random(in:0...2) {
            case 0:
                let start=Int.random(in:2...20),step=Int.random(in:2...9),repeats=Int.random(in:3...8)
                return build("Algorithm: set n = \(start); repeat \(repeats) times: add \(step). What is n at the end?",ans:start+repeats*step,story:"Trace a loop and predict its final value.",hint:"Start at n, then add the same amount for every repeat.",operands:[start,step,repeats],operators:["+","×"])
            case 1:
                let first=Int.random(in:2...12),step=Int.random(in:2...8),position=Int.random(in:5...12)
                return build("A pattern starts at \(first) and increases by \(step) each step. What value is at position \(position)?",ans:first+(position-1)*step,story:"Use a rule to predict a far term in a growing pattern.",hint:"There are \(position-1) increases after the first term.",operands:[first,position-1,step],operators:["+","×"])
            default:
                let start=Int.random(in:5...20),step=Int.random(in:2...8),loops=Int.random(in:2...6),printed=start+loops*step
                return build("A loop starts at \(start) and adds \(step) each time. It prints \(printed). How many times did it run?",ans:(printed-start)/step,story:"Work backwards from a program's output to find the loop count.",hint:"Subtract the starting value, then divide by the amount added each time.",operands:[printed-start,step],operators:["÷"])
            }
        case "mathematical_modelling":
            switch Int.random(in:0...2) {
            case 0:
                let fee=Int.random(in:40...120),perPerson=Int.random(in:8...25),people=Int.random(in:4...12)
                return build("A trip costs $\(fee) for the bus plus $\(perPerson) per student for \(people) students. What is the total cost?",ans:fee+perPerson*people,story:"Build and evaluate a model with a fixed cost and a per-person cost.",hint:"Multiply the per-student cost by the group, then add the fixed fee.",operands:[fee,perPerson,people],operators:["+","×"])
            case 1:
                let length=Int.random(in:8...25),width=Int.random(in:6...18),area=length*width
                return build("A rectangular garden plan is \(length) m long and \(width) m wide. How many square metres of planting space does the model provide?",ans:area,story:"Use a geometric model to estimate the space available in a real plan.",hint:"Represent the garden as a rectangle and multiply its side lengths.",operands:[length,width],operators:["×"])
            default:
                let predicted=Int.random(in:30...90),actual=Int.random(in:20...100)
                return build("A model predicted \(predicted) visitors; a count found \(actual). How far off was the prediction?",ans:abs(actual-predicted),story:"Check a model against observed results and evaluate its prediction.",hint:"Find the distance between the predicted and observed counts.",operands:[max(actual,predicted),min(actual,predicted)],operators:["−"])
            }
        case "mental_math_place_value":
            if g <= 6 {
                switch Int.random(in:0...2) {
                case 0:
                    let number = g <= 2 ? Int.random(in:100...999) : g <= 4 ? Int.random(in:1000...9999) : Int.random(in:10000...99999)
                    let places = g <= 2 ? [100,10,1] : g <= 4 ? [1000,100,10,1] : [10000,1000,100,10,1]
                    let place=places.randomElement() ?? 1000,digit=(number/place)%10
                    return build("In \(number), what is the value of the digit in the \(placeName(place)) place?",ans:digit*place,story:"Use place value to name the worth of a digit.",hint:"Multiply the digit by its place value.",operands:[digit,place],operators:["×"])
                case 1:
                    let number=g <= 2 ? Int.random(in:100...999) : Int.random(in:1000...9999),place=[10,100,1000].randomElement() ?? 100
                    let rounded=((number+place/2)/place)*place
                    return build("Estimate \(number) to the nearest \(placeName(place)).",ans:rounded,story:"Use a benchmark to make a quick estimate.",hint:"Look at the digit immediately to the right of the place you are rounding to.",operands:[rounded],operators:[])
                default:
                    let tens=Int.random(in:2...8),ones=Int.random(in:1...9),number=tens*10+ones
                    return build("A number is made from \(tens) tens and \(ones) ones. What is the number?",ans:number,story:"Compose a number from its place-value parts.",hint:"Multiply the tens digit by 10, then add the ones.",operands:[tens*10,ones],operators:["+"])
                }
            }
            switch Int.random(in:0...2) {
            case 0:
                let a=Int.random(in:25...99),b=Int.random(in:11...49)
                return build("Use mental math: \(a) × \(b) = ?",ans:a*b,story:"Break a multiplication into friendly parts in your head.",hint:"Try splitting one factor into tens and ones.",operands:[a,b],operators:["×"])
            case 1:
                let n=Int.random(in:250...950),step=[25,50,100].randomElement() ?? 50
                return build("Start at \(n). Add \(step) mentally. What is the new total?",ans:n+step,story:"Use place-value relationships to add a friendly amount.",hint:"Add the hundreds, tens, or quarter-hundred in parts.",operands:[n,step],operators:["+"])
            default:
                let total=Int.random(in:30...90)*10,groups=Int.random(in:2...9)
                return build("A teacher shares \(total) counters equally among \(groups) groups. How many counters are in each group?",ans:total/groups,story:"Use multiplication facts and place-value patterns to divide mentally.",hint:"Break the total into convenient groups, then divide by \(groups).",operands:[total,groups],operators:["÷"])
            }
        case "triangles_transformations":
            if g <= 6 {
                let a=Int.random(in:35...85),b=Int.random(in:35...(145-a))
                return build("A triangle has angles \(a)° and \(b)°. Find the third angle.",ans:180-a-b,story:"Use the angle rule to complete the triangle.",hint:"The three interior angles of a triangle total 180°.",operands:[180,a,b],operators:["−","−"])
            }
            let x=Int.random(in:-8...8),shift=Int.random(in:2...9)
            return build("Translate triangle vertex P(\(x), 2) right by \(shift) units. What is its new x-coordinate?",ans:x+shift,story:"Apply a translation to a point on a coordinate grid.",hint:"A move to the right adds to the x-coordinate.",operands:[x,shift],operators:["+"])
        case "budgeting_credit":
            if g <= 8 {
                let income=Int.random(in:300...900),food=Int.random(in:80...220),savings=Int.random(in:40...150)
                return build("A monthly budget is $\(income). After $\(food) for food and $\(savings) saved, how much remains?",ans:income-food-savings,story:"Balance needs and savings in a simple monthly budget.",hint:"Subtract both planned amounts from the total budget.",operands:[income,food,savings],operators:["−","−"])
            }
            let principal=Int.random(in:300...1600),rate=Int.random(in:3...8),years=Int.random(in:1...4)
            return build("A $\(principal) loan has \(rate)% simple interest per year for \(years) years. What is the total payback?",ans:principal+(principal*rate*years/100),story:"Model the cost of borrowing and include the interest in the payback.",hint:"Find interest with principal × rate × years ÷ 100, then add the principal.",operands:[principal,rate,years,100,principal],operators:["×","×","÷","+"])
        default:
            if g <= 3 {let price=Int.random(in:2...12),count=Int.random(in:2...5);if Bool.random(){return build("\(count) maple cookies cost $\(price) each. Total?",ans:price*count,story:"Buy treats for the forest fair.",hint:"Multiply the price by the number of cookies.",operands:[count,price],operators:["×"])};let have=Int.random(in:8...30),cost=Int.random(in:2...7);return build("You have $\(have) and spend $\(cost). How much is left?",ans:have-cost,story:"Choose a treat and keep track of your coins.",hint:"Subtract the cost from the amount you have.",operands:[have,cost],operators:["−"])}
            if g <= 6 {let price=Int.random(in:12...45),count=Int.random(in:3...18);if Bool.random(){return build("A school club sells \(count) tickets for $\(price) each. How much money is collected?",ans:price*count,story:"Plan the club's fundraiser budget.",hint:"Multiply ticket price by tickets sold.",operands:[price,count],operators:["×"])};let budget=Int.random(in:100...500),spent=Int.random(in:20...90);return build("A class has a $\(budget) trip budget and spends $\(spent). How much remains?",ans:budget-spent,story:"Help the class keep its trip budget on track.",hint:"Subtract the spending from the budget.",operands:[budget,spent],operators:["−"])}
            if g <= 8 {let price=Int.random(in:30...180),rate=Int.random(in:10...40);if Bool.random(){return build("A backpack costs $\(price) and is discounted by \(rate)%. How much is the discount?",ans:price*rate/100,story:"Compare sale prices before shopping.",hint:"Discount amount = price × percent ÷ 100.",operands:[price,rate,100],operators:["×","÷"])};let tax=Int.random(in:5...15);return build("A $\(price) item has \(tax)% sales tax. Find the tax amount (nearest dollar).",ans:Int((Double(price*tax)/100).rounded()),story:"Estimate the tax before paying at the checkout.",hint:"Multiply the price by the tax rate, then divide by 100.",operands:[price,tax,100],operators:["×","÷"])}
            let principal=Int.random(in:200...1500),rate=Int.random(in:3...9),years=Int.random(in:2...5)
            return build("A savings account has $\(principal) at \(rate)% simple interest for \(years) years. Find the interest.",ans:principal*rate*years/100,story:"Plan a savings goal and calculate the interest earned.",hint:"Interest = principal × rate × years ÷ 100.",operands:[principal,rate,years,100],operators:["×","×","÷"])
        }
    }

    // Grade 6 has specific Ontario expectations that differ from the broad
    // grade-band questions below. Keep its practice aligned to those outcomes.
    private func makeGradeSixQuestion(_ topic:Topic)->Question? {
        switch topic.id {
        case "number":
            switch Int.random(in:0...14) {
            case 0:
                if Bool.random() {
                    let n=Int.random(in:100_000...999_999),d=[100_000,10_000,1_000,100,10,1].randomElement() ?? 1_000
                    return build("In \(n), what is the value of the digit in the \(placeName(d)) place?",ans:(n/d%10)*d,story:"Read numbers up to one million using place value.",hint:"Multiply the digit by its place value.",operands:[n/d%10,d],operators:["×"])
                }
                let n=Int.random(in:100_000...999_999),digits=[100_000,10_000,1_000,100,10,1].map{(n/$0%10)*$0},expanded=digits.map(String.init).joined(separator:" + ")
                return conceptQuestion("Which is the expanded form of \(n)?",answer:expanded,choices:[expanded,"\(n) × 10","\(digits.map{$0/10}.map(String.init).joined(separator:" + "))","\(n/100_000) + \(n/10_000%10) + \(n/1_000%10)"],hint:"Write each digit multiplied by its place value, then add the values.",story:"Represent whole numbers up to one million in expanded form.")
            case 1:
                if Bool.random() {
                    return conceptQuestion("Order −2, 0.75, 1/2, and 1.25 from least to greatest.",answer:"−2, 1/2, 0.75, 1.25",choices:["−2, 1/2, 0.75, 1.25","1/2, 0.75, 1.25, −2","−2, 0.75, 1/2, 1.25","−2, 1.25, 0.75, 1/2"],hint:"Place them on a number line; compare the positive values using familiar fraction and decimal benchmarks.",story:"Compare and order integers, decimals, and fractions together.")
                }
                let values=[Int.random(in:-20 ... -1),Int.random(in:1...20),Int.random(in:-20 ... -1),Int.random(in:1...20)].shuffled(),sorted=values.sorted()
                return conceptQuestion("Order these integers from least to greatest: \(values.map(String.init).joined(separator:", ")).",answer:sorted.map(String.init).joined(separator:", "),choices:[sorted.map(String.init).joined(separator:", "),values.map(String.init).joined(separator:", "),sorted.reversed().map(String.init).joined(separator:", "),"0, " + sorted.map(String.init).joined(separator:", ")],hint:"Negative integers are left of zero; the one farther left is smaller.",story:"Compare and order integers on a number line.")
            case 2:
                let n=Int.random(in:100...999),divisor=[2,3,4,5,6,8,9,10].randomElement() ?? 3,yes=n%divisor==0
                return conceptQuestion("Is \(n) divisible by \(divisor)?",answer:yes ? "Yes" : "No",choices:["Yes","No","Only if it is even","Cannot tell without a calculator"],hint:"Use the divisibility rule for \(divisor), or check whether the remainder is zero.",story:"Apply divisibility rules for 2, 3, 4, 5, 6, 8, 9, and 10.")
            case 3:
                let numerator=Int.random(in:2...4),denominator=numerator+Int.random(in:1...4),groups=Int.random(in:2...8),whole=groups*numerator,answer=groups*denominator
                return conceptQuestion("How many \(numerator)/\(denominator) portions fit into \(whole)?",answer:"\(answer)",choices:["\(answer)","\(whole)","\(groups)","\(whole+denominator)"],hint:"Find how many groups of the fraction numerator are in the whole, then account for the denominator.",story:"Divide a whole number by a proper fraction.")
            case 4:
                let a=Int.random(in:100...999),varB=Int.random(in:100...999)
                let b=varB == a ? (a == 999 ? 998 : a+1) : varB
                return conceptQuestion("Which is greater: \(a)/1000 or \(b)/1000?",answer:a>b ? "\(a)/1000" : "\(b)/1000",choices:["\(a)/1000","\(b)/1000","They are equal","Not enough information"],hint:"The denominators match, so compare the numerators.",story:"Compare fractions and decimals using place value and benchmarks.")
            case 5:
                let a=Double(Int.random(in:120...990))/100,b=Double(Int.random(in:10...90))/10,c=Double(Int.random(in:10...90))/100
                return build("Calculate \(String(format:"%.2f",a)) + \(String(format:"%.1f",b)) − \(String(format:"%.2f",c)).",ans:a+b-c,story:"Solve a multistep problem with decimal numbers.",hint:"Line up decimal points, then calculate one operation at a time.",operands:[],operators:[])
            case 6:
                let a=Int.random(in:120...999),b=Int.random(in:12...99)
                return build("Calculate \(a) × \(b).",ans:a*b,story:"Multiply whole numbers using place-value strategies.",hint:"Break one factor into hundreds, tens, and ones, then combine the partial products.",operands:[a,b],operators:["×"])
            case 7:
                let amount=Int.random(in:2...20)*100,percent=[1,5,10,15,25,50].randomElement() ?? 25
                return build("Use a mental-math strategy to find \(percent)% of \(amount).",ans:amount*percent/100,story:"Calculate benchmark percents of a whole number.",hint:"Use 10%, 5%, 1%, or 50% as a friendly benchmark and combine parts as needed.",operands:[amount,percent,100],operators:["×","÷"])
            case 8:
                let whole=Int.random(in:120...999),tenths=Int.random(in:1...9)
                return build("Calculate \(whole) × 0.\(tenths).",ans:Double(whole*tenths)/10,story:"Multiply a three-digit whole number by decimal tenths.",hint:"Multiply by the tenths digit, then account for the factor of one tenth.",operands:[],operators:[])
            case 9:
                let tenths=Int.random(in:2...9),lowest=(100+tenths-1)/tenths,quotient=Int.random(in:lowest...min(330,999/tenths)),dividend=quotient*tenths
                return build("Calculate \(dividend) ÷ 0.\(tenths).",ans:quotient*10,story:"Divide a three-digit whole number by decimal tenths.",hint:"Rewrite the division so the divisor is a whole number, then divide.",operands:[],operators:[])
            case 10:
                let whole=Int.random(in:2...9),denominator=Int.random(in:3...9),numerator=Int.random(in:1..<denominator)
                return conceptQuestion("Find \(whole) × \(numerator)/\(denominator).",answer:"\(whole*numerator)/\(denominator)",choices:["\(whole*numerator)/\(denominator)","\(whole+numerator)/\(denominator)","\(whole*numerator)/(\(whole*denominator))","\(denominator)/(\(whole*numerator))"],hint:"Multiply the whole number by the numerator; keep the denominator, then simplify if possible.",story:"Multiply a whole number by a proper fraction.")
            case 11:
                switch Int.random(in:0...2) {
                case 0:
                    return conceptQuestion("Calculate 1/2 + 1/3.",answer:"5/6",choices:["5/6","2/5","2/6","1/6"],hint:"Use a common denominator before adding the numerators.",story:"Add fractions with unlike denominators.")
                case 1:
                    return conceptQuestion("Calculate 5/6 − 1/4.",answer:"7/12",choices:["7/12","4/2","4/12","1/2"],hint:"Rename both fractions with a common denominator before subtracting.",story:"Subtract fractions with unlike denominators.")
                default:
                    return conceptQuestion("Calculate 3/8 + 1/8.",answer:"4/8 or 1/2",choices:["4/8 or 1/2","4/16","2/8","1/4"],hint:"With like denominators, add the numerators and keep the denominator.",story:"Add fractions with like denominators and recognize equivalent forms.")
                }
            case 12:
                let p=[2,3,5,7].randomElement() ?? 3,q=[2,3,5,7].randomElement() ?? 5,n=p*p*q
                let factors=[p,p,q].sorted().map(String.init).joined(separator:" × ")
                return conceptQuestion("Write \(n) as a product of prime factors.",answer:factors,choices:[factors,"\(n) × 1","\(p) × \(q)","\(p*p) + \(q)"],hint:"Break the composite number into prime factors, as in a factor tree.",story:"Represent a composite number as a product of prime factors.")
            case 13:
                let divisor=Int.random(in:2...10),quotientThousandths=Int.random(in:max(1,100/divisor)...(999/divisor)),thousandths=quotientThousandths*divisor
                return build("Calculate \(String(format:"%.3f",Double(thousandths)/1000)) ÷ \(divisor).",ans:Double(quotientThousandths)/1000,story:"Divide a decimal to thousandths by a whole number.",hint:"Divide the number of thousandths equally, keeping track of place value.",operands:[],operators:[])
            default:
                let count=Int.random(in:3...8),rate=Int.random(in:2...9),total=count*rate
                return build("A trail mix recipe uses \(rate) cups of oats for \(count) batches. How many cups are needed for 1 batch?",ans:total/count,story:"Use a rate to describe a relationship between quantities.",hint:"Divide the total amount by the number of batches.",operands:[total,count],operators:["÷"])
            }
        case "fractions":
            let whole=Int.random(in:2...8),den=[2,3,4,5,6,8].randomElement() ?? 4
            return conceptQuestion("How many \(den)ths are in \(whole)?",answer:"\(whole*den)",choices:["\(whole*den)","\(whole+den)","\(whole)","\(den)"],hint:"Divide by 1/\(den) by counting how many pieces of that size fit in the whole amount.",story:"Interpret division by a unit fraction.")
        case "mental_math_place_value":
            if Bool.random() {
                let milli=Int.random(in:1_000...9_999),place=[10,100,1_000].randomElement() ?? 100,rounded=((milli+place/2)/place)*place
                return build("Round \(String(format:"%.3f",Double(milli)/1000)) to the nearest \(place==1_000 ? "whole number" : place==100 ? "tenth" : "hundredth").",ans:Double(rounded)/1000,story:"Round decimal numbers to a useful level of precision.",hint:"Check the digit immediately to the right of the place you are rounding to.",operands:[],operators:[])
            }
            let n=Int.random(in:100_000...999_999),place=[10,100,1_000,10_000,100_000].randomElement() ?? 1_000,rounded=((n+place/2)/place)*place
            return build("Round \(n) to the nearest \(placeName(place)).",ans:rounded,story:"Use place value and estimation with numbers up to one million.",hint:"Look at the digit immediately to the right of the place you are rounding to.",operands:[rounded],operators:[])
        case "decimals_percentages":
            switch Int.random(in:0...3) {
            case 0:
                let n=Int.random(in:100...999),value=String(format:"%.3f",Double(n)/1000)
                return conceptQuestion("What is \(n)/1000 written as a decimal?",answer:value,choices:[value,String(format:"%.2f",Double(n)/1000),String(format:"%.3f",Double(n)/100),String(format:"%.3f",Double(n)/10)],hint:"The third digit to the right of the decimal point is the thousandths place.",story:"Connect fractions and decimals to thousandths.")
            case 1:
                let pairs=[(1,8,"0.125"),(3,4,"0.75"),(2,5,"0.4"),(5,8,"0.625"),(1,3,"0.333…")],item=pairs.randomElement() ?? pairs[0]
                return conceptQuestion("Which decimal is equivalent to \(item.0)/\(item.1)?",answer:item.2,choices:[item.2,"0.25","0.5","0.8"],hint:"Think of the fraction as a division statement: numerator ÷ denominator.",story:"Show equivalences between fractions and decimals.")
            case 2:
                let tenths=Int.random(in:1...9),value=String(format:"0.%d",tenths),percent=tenths*10
                return conceptQuestion("Write \(value) as a percent.",answer:"\(percent)%",choices:["\(percent)%","\(percent+1)%","\(percent-1)%","\(percent+2)%"],hint:"A percent is a rate out of 100; multiply the decimal by 100.",story:"Connect decimals, fractions, and percents.")
            default:
                let values=[("25%","1/4","0.25"),("50%","1/2","0.5"),("75%","3/4","0.75")],item=values.randomElement() ?? values[0]
                return conceptQuestion("Which fraction and decimal are equivalent to \(item.0)?",answer:"\(item.1) and \(item.2)",choices:["\(item.1) and \(item.2)","\(item.2) and \(item.1)","\(item.1) and 0.1","1/10 and \(item.2)"],hint:"Write the percent as a fraction out of 100, then simplify and convert to decimal.",story:"Recall common fraction, decimal, and percent equivalents.")
            }
        case "algebra":
            switch Int.random(in:0...5) {
            case 0:
                let a=Int.random(in:2...8),b=Int.random(in:2...8)
                return conceptQuestion("Simplify \(a)m + \(b)m.",answer:"\(a+b)m",choices:["\(a+b)m","\(a*b)m","\(a+b)","\(a)m + \(b)"],hint:"Only add the coefficients of like terms; keep the variable.",story:"Combine degree-one monomials with the same variable.")
            case 1:
                let start=Int.random(in:1...12),step=Int.random(in:2...7),term=Int.random(in:4...8),value=start+(term-1)*step
                return build("A growing pattern starts at \(start) and increases by \(step) each step. What is term \(term)?",ans:value,story:"Describe and extend a pattern that grows at a constant rate.",hint:"Add the constant change once for each step after the first term.",operands:[start,step,term-1],operators:["+","×"])
            case 2:
                let a=Int.random(in:2...6),b=Int.random(in:1...5),x=Int.random(in:2...8),rhs=(a+b)*x
                return conceptQuestion("Solve: \(a)x + \(b)x = \(rhs).",answer:"x = \(x)",choices:["x = \(x)","x = \(rhs)","x = \(rhs/(a+b)+1)","x = \(a+b)"],hint:"Combine like terms first, then divide both sides by the coefficient of x.",story:"Solve an equation with multiple like terms.")
            case 3:
                let x=Int.random(in:2...8),limit=x+Int.random(in:1...6),coefficient=Int.random(in:2...5)
                return conceptQuestion("Which whole numbers satisfy \(coefficient)x < \(coefficient*limit)?",answer:"0 to \(limit-1)",choices:["0 to \(limit-1)","0 to \(limit)","\(limit) and greater","Only \(limit)"],hint:"Divide both sides by \(coefficient), then test whole-number values in the inequality.",story:"Solve and interpret a one-variable inequality.")
            case 4:
                let coefficient=Double(Int.random(in:15...45))/10,value=Int.random(in:2...9),constant=Int.random(in:1...12),answer=coefficient*Double(value)+Double(constant)
                return build("Evaluate \(String(format:"%.1f",coefficient))m + \(constant) when m = \(value).",ans:answer,story:"Evaluate an algebraic expression by substituting a value for its variable.",hint:"Replace m with \(value), then follow the order of operations.",operands:[],operators:[])
            default:
                let coefficient=Int.random(in:2...8),x=Int.random(in:2...9),constant=Int.random(in:1...12)
                return conceptQuestion("Solve: \(coefficient)x + \(constant) = \(coefficient*x+constant).",answer:"x = \(x)",choices:["x = \(x)","x = \(coefficient*x+constant)","x = \(x+constant)","x = \(coefficient)"],hint:"Undo the addition first, then divide by the coefficient.",story:"Solve a two-operation equation using inverse operations.")
            }
        case "coding_algorithms":
            if Bool.random() {
                return build("Code: n = 0. Repeat 4 times: if n < 5, add 2; otherwise, add 1. What is n at the end?",ans:7,story:"Trace a conditional inside a loop and predict the output.",hint:"Check the condition before each repeat: the values go 2, 4, 6, then 7.",operands:[],operators:[])
            }
            if Bool.random() {
                let repeats=Int.random(in:3...8),step=Int.random(in:3...7)
                return build("A loop repeats \(repeats) times. The original code adds \(step) each time; an edited version adds \(step-1). How much smaller is the edited output?",ans:repeats,story:"Read an edited loop and describe how the code change affects its output.",hint:"Each repetition changes the result by 1 less. Multiply that difference by the number of repetitions.",operands:[repeats,1],operators:["×"])
            }
            let start=Int.random(in:1...12),step=Int.random(in:2...6),limit=Int.random(in:20...50)
            let repeats=max(0,(limit-start)/step)
            return build("Code: n = \(start). While n + \(step) ≤ \(limit), add \(step) to n. What is n when the loop stops?",ans:start+repeats*step,story:"Trace a loop with a condition and predict its output.",hint:"Repeat the addition only while the condition remains true.",operands:[start,step,repeats],operators:["+","×"])
        case "mathematical_modelling":
            let meals=Int.random(in:3...7),cost=Int.random(in:6...12),budget=meals*cost+Int.random(in:5...30)
            return conceptQuestion("A lunch plan costs $\(cost) per meal for \(meals) meals. The budget is $\(budget). Which statement is true?",answer:"The plan fits; $\(budget-meals*cost) remains",choices:["The plan fits; $\(budget-meals*cost) remains","The plan is over budget by $\(meals*cost-budget)","The total is $\(cost+meals)","The budget is exactly used"],hint:"Multiply the cost per meal by the number of meals, then compare with the budget.",story:"Create and check a cost-efficient real-life model.")
        case "data", "data_visualization":
            switch Int.random(in:0...9) {
            case 0:
                return conceptQuestion("Which is continuous data?",answer:"The amount of rain measured each day",choices:["The amount of rain measured each day","The number of books in a bag","The number of students in a class","The number of goals scored"],hint:"Continuous data can take any measured value within a range.",story:"Distinguish discrete counts from continuous measurements.")
            case 1:
                let a=Int.random(in:1...12),b=Int.random(in:1...12),c=Int.random(in:1...12)
                return build("A broken-line graph shows rainfall: Monday \(a) mm, Tuesday \(b) mm, Wednesday \(c) mm. How much did rainfall change from Monday to Wednesday?",ans:c-a,story:"Read change over time from a broken-line graph.",hint:"Subtract Monday's value from Wednesday's; a negative result means a decrease.",operands:[],operators:[])
            case 2:
                return conceptQuestion("Which graph is best for showing temperature changes over a week?",answer:"A broken-line graph",choices:["A broken-line graph","A circle graph","A pictograph only","A list with no order"],hint:"Choose a graph that shows how a measured value changes over time.",story:"Select a suitable graph for continuous data over time.")
            case 3:
                return conceptQuestion("A survey asks students how they travel to school. Which data type is the response category?",answer:"Qualitative data",choices:["Qualitative data","Continuous data","A measurement in centimetres","An interval with no categories"],hint:"The responses are names of categories, not counts or measurements.",story:"Collect and organize qualitative and quantitative data.")
            case 4:
                return conceptQuestion("A graph uses a vertical axis that starts at 48 instead of 0, making small differences look huge. What should you do?",answer:"Check the scale and question whether the graph is misleading",choices:["Check the scale and question whether the graph is misleading","Assume the tallest bar is always twice as large","Ignore the labels","Add the axis values together"],hint:"Inspect axis labels, intervals, and the visual effect of the scale.",story:"Critically interpret graphs and identify misleading displays.")
            case 5:
                let a=Int.random(in:2...8),b=Int.random(in:2...8),c=Int.random(in:2...8)
                return build("A histogram shows 0–9 mm: \(a) days, 10–19 mm: \(b) days, 20–29 mm: \(c) days. How many days were recorded?",ans:a+b+c,story:"Read grouped data from a histogram.",hint:"Add the frequencies in all intervals.",operands:[a,b,c],operators:["+","+"])
            case 6:
                return conceptQuestion("A class wants to know how students travel to school. Which sample is fairest?",answer:"Ask students from different grades and travel groups",choices:["Ask students from different grades and travel groups","Ask only students who ride the bus","Ask only students in one classroom","Ask only students arriving by car"],hint:"A representative sample should include different parts of the population.",story:"Plan data collection that can support a fair conclusion.")
            case 7:
                switch Int.random(in:0...2) {
                case 0:
                    return conceptQuestion("For the data 2, 3, 3, 5, 7, what is the mean?",answer:"4",choices:["4","3","5","7"],hint:"Add all values and divide by the number of values.",story:"Determine the mean as a measure of central tendency.")
                case 1:
                    return conceptQuestion("For the data 2, 3, 3, 5, 7, what is the mode?",answer:"3",choices:["3","4","5","7"],hint:"The mode is the value that appears most often.",story:"Determine the mode as a measure of central tendency.")
                default:
                    return conceptQuestion("For the data 2, 3, 3, 5, 7, what are the median and range?",answer:"Median 3; range 5",choices:["Median 3; range 5","Median 4; range 3","Median 3; range 7","Median 5; range 4"],hint:"The median is the middle value; range = largest minus smallest.",story:"Use median and range to describe a data set.")
                }
            case 8:
                return conceptQuestion("A class investigates daily rainfall for a month. Which display plan best organizes and communicates the measurements?",answer:"Group measurements into intervals for a histogram and label the scale",choices:["Group measurements into intervals for a histogram and label the scale","List only the highest value","Use unlabeled bars with no intervals","Sort the days alphabetically"],hint:"Choose intervals for the continuous measurements, then provide clear labels and a scale.",story:"Organize quantitative data and choose an appropriate graph.")
            default:
                return conceptQuestion("What should an infographic about a data set include?",answer:"An appropriate table or graph, labels, scale, and context that explains the data",choices:["An appropriate table or graph, labels, scale, and context that explains the data","A graph without a title or labels","Only the largest number","Decorations without the data source"],hint:"A useful infographic makes the data understandable and tells an accurate story.",story:"Create an infographic that communicates data clearly.")
            }
        case "probability":
            switch Int.random(in:0...5) {
            case 0:
                let good=Int.random(in:1...5)
                return conceptQuestion("A fair number cube is rolled. What is the probability of rolling one of \(good) selected numbers?",answer:"\(good)/6",choices:["\(good)/6","6/\(good)","\(good)/5","\(good)/4"],hint:"Probability is favourable outcomes divided by all equally likely outcomes.",story:"Express and compare the likelihood of an event.")
            case 1:
                let heads=Int.random(in:2...8),trials=10,percent=heads*10
                return conceptQuestion("A coin lands heads \(heads) times in \(trials) flips. What is the experimental probability of heads?",answer:"\(heads)/10 or \(percent)%",choices:["\(heads)/10 or \(percent)%","1/2 every time","10/\(heads)","\(trials-heads)/10"],hint:"Experimental probability uses observed successes divided by the number of trials.",story:"Compare experimental results with theoretical probability.")
            case 2:
                return conceptQuestion("A fair coin is tossed and a fair number cube is rolled. What is the probability of heads and a 6?",answer:"1/12",choices:["1/12","1/8","1/2","7/12"],hint:"These events are independent, so multiply 1/2 by 1/6.",story:"Determine the theoretical probability of two independent events.")
            case 3:
                return conceptQuestion("A bag has 2 red and 1 blue counter. Two counters are drawn without replacement. What is the probability both are red?",answer:"1/3",choices:["1/3","2/3","4/9","1/6"],hint:"After one red is drawn, only 1 red remains among 2 counters. Multiply the successive probabilities.",story:"Determine probability when one event changes the outcomes available for the next.")
            case 4:
                return conceptQuestion("An event has probability 0.75. Where does it belong on a probability line from impossible to certain?",answer:"Closer to certain than to impossible",choices:["Closer to certain than to impossible","At impossible","Exactly halfway","At certain"],hint:"Compare 0.75 with 0.5 and 1 on the probability line.",story:"Represent likelihood on a probability line and use it to make predictions.")
            default:
                return conceptQuestion("Two independent coin tosses are repeated many times. Which comparison is appropriate?",answer:"Compare the theoretical probability with the fraction of trials that actually show two heads",choices:["Compare the theoretical probability with the fraction of trials that actually show two heads","The first toss changes the probability of the second","Experimental results must equal the theoretical value in every small sample","There is only one possible outcome"],hint:"For independent tosses, theoretical P(two heads) is 1/4; experimental probability comes from the recorded trials.",story:"Compare theoretical and experimental probability for independent events.")
            }
        case "measurement":
            switch Int.random(in:0...8) {
            case 0:
                let amount=Int.random(in:2...25),unit=Int.random(in:0...3)
                if unit==0 { return build("Convert \(amount) m to centimetres.",ans:amount*100,story:"Convert metric measurements using base-ten relationships.",hint:"There are 100 centimetres in 1 metre.",operands:[amount,100],operators:["×"]) }
                if unit==1 { return build("Convert \(amount*250) g to kilograms.",ans:Double(amount)/4,story:"Convert metric measurements using base-ten relationships.",hint:"There are 1,000 grams in 1 kilogram; divide by 1,000.",operands:[],operators:[]) }
                if unit==2 { return build("Convert \(amount*250) mL to litres.",ans:Double(amount)/4,story:"Convert metric measurements using base-ten relationships.",hint:"There are 1,000 millilitres in 1 litre; divide by 1,000.",operands:[],operators:[]) }
                return build("Convert \(amount) m² to cm².",ans:amount*10_000,story:"Convert area measurements using squared metric units.",hint:"Since 1 m = 100 cm, 1 m² = 100 × 100 = 10,000 cm².",operands:[amount,10_000],operators:["×"])
            case 1:
                let base=Int.random(in:4...18),height=Int.random(in:2...12)
                return build("A parallelogram has base \(base) cm and perpendicular height \(height) cm. Find its area.",ans:base*height,story:"Relate the area of a parallelogram to a rectangle.",hint:"Area = base × perpendicular height.",operands:[base,height],operators:["×"])
            case 2:
                let short=Int.random(in:2...6)*2,long=short+Int.random(in:1...5)*2,height=Int.random(in:2...8)
                return build("A trapezoid has parallel sides \(short) cm and \(long) cm, with height \(height) cm. Find its area by decomposition.",ans:(short+long)*height/2,story:"Decompose a trapezoid into shapes with known areas.",hint:"Double the trapezoid to form a parallelogram, then take half its area.",operands:[short+long,height,2],operators:["×","÷"])
            case 3:
                let a=Int.random(in:55...115),b=Int.random(in:55...115),c=Int.random(in:55...115)
                return build("Three angles in a quadrilateral are \(a)°, \(b)°, and \(c)°. Find the fourth angle.",ans:360-a-b-c,story:"Use angle relationships in quadrilaterals to find an unknown measure.",hint:"The interior angles of a quadrilateral add to 360°.",operands:[360,a,b,c],operators:["−","−","−"])
            case 4:
                let l=Int.random(in:3...10),w=Int.random(in:2...8),h=Int.random(in:2...7)
                return build("Find the surface area of a rectangular prism with dimensions \(l) cm, \(w) cm, and \(h) cm.",ans:2*(l*w+l*h+w*h),story:"Add the areas of all faces to find surface area.",hint:"There are two faces of each size: lw, lh, and wh.",operands:[],operators:[])
            case 5:
                let side=Int.random(in:3...10),triangleHeight=Int.random(in:2...8)
                return build("A square-based pyramid has base side \(side) cm. Each triangular face has perpendicular height \(triangleHeight) cm. Find its surface area.",ans:side*side+2*side*triangleHeight,story:"Use a net and add the areas of a pyramid's faces.",hint:"Add the square base area and the four equal triangle areas.",operands:[],operators:[])
            case 6:
                let d1=Int.random(in:2...8)*2,d2=Int.random(in:1...6)*2
                return build("A kite has diagonals \(d1) cm and \(d2) cm. Use its decomposition to find the area.",ans:d1*d2/2,story:"Decompose a kite into triangles to find its area.",hint:"The kite's area is half the product of its diagonals.",operands:[d1,d2,2],operators:["×","÷"])
            case 7:
                let angle=[30,45,60,90,120,150].randomElement() ?? 90
                return conceptQuestion("An angle measures \(angle)° counterclockwise. What is the equivalent clockwise measure for the same turn?",answer:"\(360-angle)°",choices:["\(360-angle)°","\(angle)°","\(180-angle)°","360°"],hint:"A full turn is 360°. Subtract the counterclockwise measure to get the equivalent clockwise turn.",story:"Relate clockwise and counterclockwise angle measures up to 360°.")
            default:
                switch Int.random(in:0...2) {
                case 0:
                    let angle=Int.random(in:25...155)
                    return conceptQuestion("Two adjacent angles form a straight line. One measures \(angle)°. What is the other?",answer:"\(180-angle)°",choices:["\(180-angle)°","\(90-angle)°","\(angle)°","\(360-angle)°"],hint:"Supplementary angles add to 180°.",story:"Use supplementary-angle relationships to find an unknown angle.")
                case 1:
                    let angle=Int.random(in:15...75)
                    return conceptQuestion("Two angles are complementary. One measures \(angle)°. What is the other?",answer:"\(90-angle)°",choices:["\(90-angle)°","\(180-angle)°","\(angle)°","\(360-angle)°"],hint:"Complementary angles add to 90°.",story:"Use complementary-angle relationships.")
                default:
                    let angle=Int.random(in:25...155)
                    return conceptQuestion("Two lines intersect. One angle is \(angle)°. What is the measure of the vertically opposite angle?",answer:"\(angle)°",choices:["\(angle)°","\(180-angle)°","\(90-angle)°","\(360-angle)°"],hint:"Vertically opposite angles are equal.",story:"Use opposite-angle relationships to find an unknown measure.")
                }
            }
        case "spatial":
            switch Int.random(in:0...3) {
            case 0:
                return conceptQuestion("A block model has two stacks in a row. The top view shows 2 positions; the front view shows heights 2 and 1; the side view shows a maximum height of 2. How many cubes build it?",answer:"3",choices:["3","2","4","5"],hint:"Build one stack of 2 cubes and one stack of 1 cube, then check all three views.",story:"Construct a three-dimensional object from top, front, and side views.")
            case 1:
                return conceptQuestion("A quadrilateral has four equal sides and four right angles. Which name describes it most specifically?",answer:"Square",choices:["Square","Rectangle","Kite","Pentagon"],hint:"Use both side lengths and angle properties to classify the quadrilateral.",story:"Describe and classify quadrilaterals by their properties.")
            case 2:
                return conceptQuestion("Which property is always true for the diagonals of a rhombus?",answer:"They bisect each other at right angles",choices:["They bisect each other at right angles","They are always different lengths and parallel","They never meet","They form four 90° angles in every quadrilateral"],hint:"A rhombus has diagonals that cross at right angles and bisect one another.",story:"Describe quadrilaterals using diagonal properties.")
            default:
                return conceptQuestion("A square is rotated 90° about its centre. Which statement is true?",answer:"It maps onto itself and has rotational symmetry",choices:["It maps onto itself and has rotational symmetry","It becomes a different shape","It has no line of symmetry","Its side lengths change"],hint:"Check whether the rotated image matches the original square.",story:"Identify rotational and line symmetry in quadrilaterals.")
            }
        case "triangles_transformations":
            switch Int.random(in:0...3) {
            case 0:
                let x=Int.random(in:-8...8),y=Int.random(in:-8...8),dx=Int.random(in:-5...5),dy=Int.random(in:-5...5)
                return conceptQuestion("Point P(\(x), \(y)) is translated by (\(dx), \(dy)). What are its new coordinates?",answer:"(\(x+dx), \(y+dy))",choices:["(\(x+dx), \(y+dy))","(\(x-dx), \(y-dy))","(\(y+dx), \(x+dy))","(\(x), \(y))"],hint:"Add the horizontal change to x and the vertical change to y.",story:"Plot coordinates in all four quadrants and describe translations.")
            case 1:
                let x=Int.random(in:-8...8),y=Int.random(in:-8...8)
                return conceptQuestion("Reflect point (\(x), \(y)) across the x-axis. What are its new coordinates?",answer:"(\(x), −\(y))",choices:["(\(x), −\(y))","(−\(x), \(y))","(\(y), \(x))","(−\(x), −\(y))"],hint:"A reflection across the x-axis keeps x and changes y to its opposite.",story:"Describe reflections on a coordinate grid.")
            case 2:
                let x=Int.random(in:1...8),y=Int.random(in:1...8),angle=[90,180,270].randomElement() ?? 90
                let answer=angle==90 ? "(−\(y), \(x))" : angle==180 ? "(−\(x), −\(y))" : "(\(y), −\(x))"
                return conceptQuestion("Rotate point (\(x), \(y)) \(angle)° counterclockwise about the origin. What are the new coordinates?",answer:answer,choices:[answer,"(\(x), \(y))","(\(y), \(x))","(−\(x), \(y))"],hint:"Use the coordinate rule for a quarter-turn, half-turn, or three-quarter-turn about the origin.",story:"Perform rotations up to 360° and predict their results.")
            default:
                let x=Int.random(in:1...8),y=Int.random(in:1...8),dx=Int.random(in:1...4)
                return conceptQuestion("Point (\(x), \(y)) is translated \(dx) right, then reflected across the y-axis. Where does it end?",answer:"(−\(x+dx), \(y))",choices:["(−\(x+dx), \(y))","(\(x+dx), −\(y))","(−\(x), \(y))","(\(x), \(y))"],hint:"Apply the translation first, then change the sign of the x-coordinate for the reflection.",story:"Combine transformations in order and predict the final position.")
            }
        case "money":
            return conceptQuestion("A student can pay with cash, debit, or a credit card. Which statement is accurate?",answer:"Debit uses money in an account; credit borrows and may add interest",choices:["Debit uses money in an account; credit borrows and may add interest","Credit always costs less than cash","Debit means borrowing from the bank","All payment methods have the same risks and fees"],hint:"Compare when money leaves the account, possible fees, and whether the payment is borrowing.",story:"Describe advantages and disadvantages of payment methods.")
        case "budgeting_credit":
            switch Int.random(in:0...3) {
            case 0:
                if Bool.random() {
                    let target=Int.random(in:60...180),hourly=Int.random(in:10...30),hours=(target+hourly-1)/hourly
                    return build("A student wants to earn $\(target) for a goal. At $\(hourly) per hour, what is the fewest whole hours needed?",ans:hours,story:"Plan an earning goal using a realistic timeline.",hint:"Divide the goal amount by hourly earnings and round up.",operands:[target,hourly],operators:["÷"])
                }
                let goal=Int.random(in:60...180),weekly=Int.random(in:10...30),weeks=(goal+weekly-1)/weekly
                return build("A student saves $\(weekly) each week toward a $\(goal) goal. What is the fewest whole weeks needed?",ans:weeks,story:"Set a financial goal and make a savings plan.",hint:"Divide the goal by weekly savings and round up to a whole week.",operands:[goal,weekly],operators:["÷"])
            case 1:
                return conceptQuestion("A savings account pays interest, while a loan charges interest. What does the interest rate describe?",answer:"The percentage used to calculate interest earned or owed",choices:["The percentage used to calculate interest earned or owed","A flat fee that never depends on the amount","The amount of money deposited","The number of payments only"],hint:"Interest is calculated as a percentage of money saved or borrowed; also check account fees.",story:"Explain interest rates and identify fees on accounts and loans.")
            case 2:
                return conceptQuestion("Which change could make it harder to reach a savings goal?",answer:"An unexpected expense reduces the amount available to save",choices:["An unexpected expense reduces the amount available to save","A clear timeline helps track progress","Regular saving adds money to the goal","Comparing prices helps reduce spending"],hint:"Look for a change that takes money away from the planned savings.",story:"Identify factors that help or interfere with financial goals.")
            default:
                let situations=[("A student swaps a book for a plant.","Trading"),("A student takes a library book and must return it.","Borrowing"),("A student lets a neighbour use a tool, expecting it back.","Lending"),("A group gives winter coats to a shelter with no payment expected.","Donating")]
                let item=situations.randomElement() ?? situations[3]
                return conceptQuestion("\(item.0) Which way of distributing resources is this?",answer:item.1,choices:["Trading","Borrowing","Lending","Donating"],hint:"Decide whether something is exchanged, temporarily received, temporarily given, or given without payment.",story:"Distinguish trading, lending, borrowing, and donating resources.")
            }
        default:
            return nil
        }
    }

    private func makeGradeFiveQuestion(_ topic:Topic)->Question? {
        switch topic.id {
        case "number":
            switch Int.random(in:0...7) {
            case 0:
                let a=Int.random(in:10...99),b=Int.random(in:10...99)
                return build("Use an area model or an algorithm: \(a) × \(b) = ?",ans:a*b,story:"Multiply two two-digit numbers and connect the partial products.",hint:"Break one factor into tens and ones, then add the partial products.",operands:[a,b],operators:["×"])
            case 1:
                let groups=Int.random(in:3...8),each=Int.random(in:12...35),extra=Int.random(in:100...500),remove=Int.random(in:20...80)
                return build("A club has \(extra) points, earns \(groups) groups of \(each) points, then spends \(remove). How many remain?",ans:extra+groups*each-remove,story:"Solve a multistep whole-number problem and check the result.",hint:"Multiply first, then add and subtract.",operands:[extra,groups,each,remove],operators:["+","×","−"])
            case 2:
                let a=Int.random(in:10000...49999),b=Int.random(in:10000...49999),add=Bool.random(),large=max(a,b),small=min(a,b)
                return build("Calculate \(add ? a : large) \(add ? "+" : "−") \(add ? b : small) = ?",ans:add ? a+b : large-small,story:"Add or subtract whole numbers up to 100,000.",hint:"Line up place values and use the inverse operation to check your calculation.",operands:[add ? a : large,add ? b : small],operators:[add ? "+" : "−"])
            case 3:
                let whole=Int.random(in:1...20),tenths=Int.random(in:1...9),hundredths=Int.random(in:1...9)
                let x=Double(whole)+Double(tenths)/10,y=Double(hundredths)/100,z=Double(Int.random(in:1...9))/10
                return build("A trail is \(String(format:"%.1f",x)) km long and another is \(String(format:"%.2f",y)) km. What is their total after a \(String(format:"%.1f",z)) km extension?",ans:x+y+z,story:"Add and subtract decimals to hundredths in a multistep context.",hint:"Line up decimal points and calculate one step at a time.",operands:[],operators:[])
            case 4:
                let divisor=Int.random(in:2...9),quotient=Int.random(in:12...99),remainder=Int.random(in:0...(divisor-1)),dividend=divisor*quotient+remainder
                let answer="\(quotient) R \(remainder)"
                return conceptQuestion("Divide \(dividend) by \(divisor). Give the quotient and remainder.",answer:answer,choices:[answer,"\(quotient+1) R \(remainder)","\(quotient) R \(min(divisor-1,remainder+1))","\(remainder) R \(quotient)"],hint:"Use a multiplication fact or a division strategy. Check: quotient × divisor + remainder = dividend.",story:"Divide a two- or three-digit number by a one-digit number and interpret the remainder.")
            case 5:
                let n=Int.random(in:2...9),d=[2,3,4,5,6,8,10,12].randomElement() ?? 4
                if Bool.random() { return build("How many \(1)/\(d) portions fit into \(n)?",ans:n*d,story:"Divide a whole number by a unit fraction.",hint:"Count how many unit-fraction pieces fit into the whole amount.",operands:[n,d],operators:["×"]) }
                return build("Find \(n) × 1/\(d). Give the numerator; the denominator stays \(d).",ans:n,story:"Multiply a whole number by a unit fraction.",hint:"Repeatedly add \(1)/\(d) a total of \(n) times.",operands:[n,1],operators:["×"])
            case 6:
                let n=Int.random(in:0...12),m=Int.random(in:0...12)
                return build("Recall the multiplication fact: \(n) × \(m) = ?",ans:n*m,story:"Recall multiplication facts from 0 × 0 to 12 × 12.",hint:"Use a known multiplication fact or an array of equal groups.",operands:[n,m],operators:["×"])
            default:
                if Bool.random() {
                    let a=Int.random(in:2...12),b=Int.random(in:2...12),scale=Int.random(in:2...6)
                    return conceptQuestion("Which ratio is equivalent to \(a):\(b)?",answer:"\(a*scale):\(b*scale)",choices:["\(a*scale):\(b*scale)","\(a+scale):\(b+scale)","\(a):\(b*scale)","\(b):\(a)"],hint:"Multiply both parts of a ratio by the same factor.",story:"Represent equivalent ratios using a scale factor.")
                }
                let n=Int.random(in:12...99),byHundredth=Bool.random()
                return build("Use mental math: \(n) × \(byHundredth ? "0.01" : "0.1") = ?",ans:Double(n)/(byHundredth ? 100 : 10),story:"Multiply a whole number by 0.1 or 0.01 mentally.",hint:"Multiplying by 0.1 or 0.01 moves each digit one or two places to the right in value.",operands:[],operators:[])
            }
        case "mental_math_place_value":
            switch Int.random(in:0...5) {
            case 0:
                let n=Int.random(in:10000...99999),place=[1,10,100,1000,10000].randomElement() ?? 1000
                return build("In \(n), what is the value of the digit in the \(placeName(place)) place?",ans:(n/place%10)*place,story:"Read a five-digit number using place value.",hint:"Multiply the digit by its place value.",operands:[n/place%10,place],operators:["×"])
            case 1:
                let n=Int.random(in:10000...99999)
                let expanded="\(n/10000*10000) + \(n/1000%10*1000) + \(n/100%10*100) + \(n/10%10*10) + \(n%10)"
                return conceptQuestion("Which expression is the expanded form of \(n)?",answer:expanded,choices:[expanded,"\(n/10000) + \(n/1000%10) + \(n/100%10) + \(n/10%10) + \(n%10)","\(n/10000*1000) + \(n/1000%10*10000) + \(n/100%10*100) + \(n/10%10*10) + \(n%10)","\(n) × 10"],hint:"Each digit contributes its value in its place.",story:"Compose and decompose numbers up to 100,000.")
            case 2:
                let a=Int.random(in:10000...99999),b=Int.random(in:10000...99999)
                return build("How much greater is \(max(a,b)) than \(min(a,b))?",ans:abs(a-b),story:"Compare and subtract five-digit whole numbers.",hint:"Compare place values, then subtract carefully.",operands:[max(a,b),min(a,b)],operators:["−"])
            case 3:
                let a=Int.random(in:10000...99999),b=Int.random(in:10000...99999),low=min(a,b),high=max(a,b)
                return conceptQuestion("Which number is greater: \(a) or \(b)?",answer:String(high),choices:[String(high),String(low)],hint:"Compare digits from left to right, beginning with the ten-thousands place.",story:"Order whole numbers through 100,000.")
            default:
                let n=Int.random(in:10...99)
                return build("Use mental math: \(n) × 0.1 = ?",ans:Double(n)/10,story:"Multiply a whole number by 0.1 mentally.",hint:"Multiplying by 0.1 is the same as dividing by 10.",operands:[],operators:[])
            }
        case "fractions":
            switch Int.random(in:0...5) {
            case 0:
                let d=[2,3,4,5,6,8,10,12].randomElement() ?? 8,n=Int.random(in:1...(d-1)),multiplier=Int.random(in:2...3)
                return conceptQuestion("Which fraction is equivalent to \(n)/\(d)?",answer:"\(n*multiplier)/\(d*multiplier)",choices:["\(n*multiplier)/\(d*multiplier)","\(n)/\(d*multiplier)","\(n*multiplier)/\(d)","\(n)/\(d)"],hint:"Multiply both the numerator and denominator by the same number.",story:"Represent equivalent fractions, including fractions greater than one.")
            case 1:
                let pool=[(1,2),(2,3),(3,4),(5,6),(7,8),(5,4),(7,5),(3,2),(11,10)]
                let picked=Array(pool.shuffled().prefix(3)),ordered=picked.sorted{Double($0.0)/Double($0.1)<Double($1.0)/Double($1.1)},answer="\(ordered[1].0)/\(ordered[1].1)"
                return conceptQuestion("Order these fractions from least to greatest: \(picked.map{"\($0.0)/\($0.1)"}.joined(separator:", ")). Which fraction is in the middle?",answer:answer,choices:[answer,"\(ordered[0].0)/\(ordered[0].1)","\(ordered[2].0)/\(ordered[2].1)"],hint:"Compare their values; use equivalent fractions or common benchmarks.",story:"Compare and order proper and improper fractions, including values greater than one.")
            case 2,3:
                let d=[4,5,6,8,10,12].randomElement() ?? 8
                let a=Int.random(in:1...(d-1)),b=Int.random(in:1...(d-a))
                let isAddition=Bool.random(),numerator=isAddition ? a+b : max(a,b)-min(a,b)
                let left=isAddition ? a : max(a,b),right=isAddition ? b : min(a,b),op=isAddition ? "+" : "−"
                return fractionAnswerQuestion("Build the answer: \(left)/\(d) \(op) \(right)/\(d).",answer:"\(numerator)/\(d)",denominator:d,hint:"The parts are the same size, so keep the denominator and combine the numerators.",story:"Add or subtract fractions with the same denominator.")
            default:
                let whole=Int.random(in:1...3),d=[2,3,4,5,6,8,10,12].randomElement() ?? 8,n=Int.random(in:1...(d-1))
                return conceptQuestion("Which improper fraction is equal to \(whole) \(n)/\(d)?",answer:"\(whole*d+n)/\(d)",choices:["\(whole*d+n)/\(d)","\(whole+n)/\(d)","\(whole*d)/\(d+n)","\(n)/\(d)"],hint:"Multiply the whole number by the denominator, then add the numerator.",story:"Represent a mixed number as an equivalent improper fraction.")
            }
        case "decimals_percentages":
            switch Int.random(in:0...4) {
            case 0:
                let a=Int.random(in:0...9999),b=Int.random(in:0...9999),lo=min(a,b),hi=max(a,b)
                return conceptQuestion("Which decimal is greater: \(String(format:"%.2f",Double(a)/100)) or \(String(format:"%.2f",Double(b)/100))?",answer:String(format:"%.2f",Double(hi)/100),choices:[String(format:"%.2f",Double(hi)/100),String(format:"%.2f",Double(lo)/100)],hint:"Compare matching place values from left to right.",story:"Compare and order decimal numbers to hundredths.")
            case 1:
                let n=Int.random(in:100...999),tenths=(n+5)/10
                return build("Round \(String(format:"%.2f",Double(n)/100)) to the nearest tenth. Enter the tenths digit.",ans:tenths%10,story:"Round a decimal to the nearest tenth.",hint:"Check the hundredths digit to decide whether the tenths digit changes.",operands:[tenths],operators:[])
            case 2:
                let pairs=[("1/2","0.50","50%"),("1/4","0.25","25%"),("3/4","0.75","75%"),("1/5","0.20","20%"),("1/10","0.10","10%"),("1/2","0.5","50%")]
                let p=pairs.randomElement() ?? ("1/2","0.50","50%")
                let percent=Int(p.2.dropLast()) ?? 0,wrongPercent=(percent+10)%100
                return conceptQuestion("Which three forms show the same amount?",answer:"\(p.0), \(p.1), \(p.2)",choices:["\(p.0), \(p.1), \(p.2)","\(p.0), \(p.1), \(wrongPercent)%","\(p.0), \(p.1), \(percent == 50 ? 5 : 90)%"],hint:"Use a fraction or decimal out of one whole to check the percent.",story:"Connect fractions, decimals to hundredths, and whole-number percents.")
            case 3:
                let amount=Int.random(in:2...20)*20,percent=[10,20,25,50,75].randomElement() ?? 25
                return build("What is \(percent)% of \(amount)?",ans:amount*percent/100,story:"Use a whole-number percent to describe part of an amount.",hint:"Think of the percent as a fraction out of 100.",operands:[amount,percent,100],operators:["×","÷"])
            default:
                let a=Double(Int.random(in:100...999))/100,b=Double(Int.random(in:100...999))/100,add=Bool.random(),ans=add ? a+b : abs(a-b)
                return build("Estimate, then calculate: \(String(format:"%.2f",a)) \(add ? "+" : "−") \(String(format:"%.2f",b)) = ?",ans:ans,story:"Estimate and calculate sums or differences of decimals to hundredths.",hint:"Estimate with nearby tenths, then line up decimal points.",operands:[],operators:[])
            }
        case "algebra":
            switch Int.random(in:0...7) {
            case 0,1:
                let start=Int.random(in:5...35),step=Int.random(in:2...9),shrinking=Bool.random()
                let values=(0...3).map{start+(shrinking ? -$0*step : $0*step)}
                return build("Pattern: \(values[0]), \(values[1]), \(values[2]), __. What comes next?",ans:start+(shrinking ? -3*step : 3*step),story:"Identify and extend a growing or shrinking pattern.",hint:"Find the change from one term to the next.",operands:[values[2],step],operators:[shrinking ? "−" : "+"])
            case 2:
                let x=Int.random(in:8...50),b=Int.random(in:2...20),c=Int.random(in:1...15)
                return build("Solve: \(b) + n = \(x+b-c) + \(c). What is n?",ans:x,story:"Solve a whole-number equation by keeping both sides equal.",hint:"Simplify the right side, then undo the addition.",operands:[x+b,b],operators:["−"])
            case 3:
                let rate=Int.random(in:2...8),start=Int.random(in:1...20),term=Int.random(in:2...8)
                return build("A pattern starts at \(start) and grows by \(rate) each step. What is the value at step \(term)?",ans:start+rate*(term-1),story:"Represent a growing pattern with a rule and a table value.",hint:"There are \(term-1) growth steps after the starting value.",operands:[start,rate,term-1],operators:["+","×"])
            case 4:
                let fixed=Int.random(in:2...9),rate=Int.random(in:2...6),input=Int.random(in:2...8)
                return build("Evaluate the rule output = \(fixed) + \(rate) × input when input = \(input).",ans:fixed+rate*input,story:"Translate and evaluate a whole-number relationship.",hint:"Replace input with \(input), then multiply before adding.",operands:[fixed,rate,input],operators:["+","×"])
            case 5:
                if Bool.random() {
                    return conceptQuestion("A repeating pattern goes red, blue, blue, red, blue, blue, __. What comes next?",answer:"red",choices:["red","blue","green"],hint:"Find the repeating group, then continue it.",story:"Identify, create, and extend repeating patterns.")
                }
                return build("Continue the decimal pattern: 0.2, 0.4, 0.6, __.",ans:0.8,story:"Create and describe patterns that show relationships among decimal numbers.",hint:"Find how much is added at each step.",operands:[],operators:[])
            default:
                let a=Int.random(in:2...15),b=Int.random(in:2...15),sum=a+b
                return conceptQuestion("Which pair of expressions is equivalent when n = \(a)?",answer:"n + \(b) and \(sum)",choices:["n + \(b) and \(sum)","n × \(b) and \(sum)","n − \(b) and \(sum)","n + \(sum) and \(b)"],hint:"Substitute the given value for n and compare the totals.",story:"Translate among words, algebraic expressions, and equivalent relationships.")
            }
        case "measurement":
            switch Int.random(in:0...6) {
            case 0:
                let base=Int.random(in:4...12),height=Int.random(in:2...9)
                return build("A parallelogram has base \(base) cm and perpendicular height \(height) cm. Find its area.",ans:base*height,story:"Develop and use the area relationship for a parallelogram.",hint:"Area equals base times perpendicular height.",operands:[base,height],operators:["×"])
            case 1:
                let base=Int.random(in:2...9)*2,height=Int.random(in:2...12)
                return build("A triangle has base \(base) cm and perpendicular height \(height) cm. Find its area.",ans:base*height/2,story:"Use the relationship between a triangle and a parallelogram to find area.",hint:"A triangle with this base and height is half of a matching parallelogram.",operands:[base,height,2],operators:["×","÷"])
            case 2:
                return conceptQuestion("Can two shapes have the same area but different perimeters?",answer:"Yes. Rearranging a shape can preserve area but change its perimeter.",choices:["Yes. Rearranging a shape can preserve area but change its perimeter.","No. Equal areas always have equal perimeters."],hint:"Area measures the surface covered; perimeter measures the distance around the edge.",story:"Compare equal-area shapes with different perimeters.")
            case 3:
                let amount=Int.random(in:2...90),unit=[("km",1000,"m"),("m",100,"cm"),("kg",1000,"g"),("L",1000,"mL")].randomElement() ?? ("km",1000,"m")
                return build("Convert \(amount) \(unit.0) to \(unit.2).",ans:amount*unit.1,story:"Choose appropriate metric units and convert between them.",hint:"Multiply by the number of smaller units in one larger unit.",operands:[amount,unit.1],operators:["×"])
            case 4:
                return conceptQuestion("Which metric unit is most appropriate for measuring the capacity of a large water tank?",answer:"kilolitres (kL)",choices:["kilolitres (kL)","millimetres (mm)","grams (g)","square centimetres (cm²)"],hint:"Choose a unit that measures capacity and suits a large quantity.",story:"Choose appropriate metric units for length, area, mass, and capacity.")
            case 5:
                let deg=Int.random(in:20...160),bench=[45,90,180].randomElement() ?? 90
                return conceptQuestion("An angle measures \(deg)°. Compared with a \(bench)° benchmark angle, is it smaller, equal, or larger?",answer:deg<bench ? "smaller" : deg==bench ? "equal" : "larger",choices:["smaller","equal","larger"],hint:"Compare the angle measures; a protractor can measure angles up to 180°.",story:"Estimate, compare, and measure angles.")
            default:
                return conceptQuestion("To construct a 120° angle with a protractor, what should you do?",answer:"Align the centre and zero line, mark 120°, then draw the second ray through the mark.",choices:["Align the centre and zero line, mark 120°, then draw the second ray through the mark.","Start at the 90° mark and draw any ray.","Measure the two side lengths and add them.","Use the outside scale without lining up the baseline."],hint:"Place the protractor centre at the vertex and align one arm with 0°.",story:"Use a protractor to measure and construct angles up to 180°.")
            }
        case "spatial":
            switch Int.random(in:0...4) {
            case 0:
                let options=["three equal sides and three equal angles","exactly two equal sides","one right angle","no equal sides"]
                return conceptQuestion("Which description always matches an equilateral triangle?",answer:options[0],choices:options,hint:"An equilateral triangle has all sides equal; its angles are equal too.",story:"Identify and classify triangle properties.")
            case 1:
                return conceptQuestion("A triangle has sides 5 cm, 5 cm, and 8 cm. What type is it by its sides?",answer:"isosceles",choices:["equilateral","isosceles","scalene"],hint:"Two equal side lengths make an isosceles triangle.",story:"Classify triangles using their side measurements.")
            case 2:
                let x=Int.random(in:0...8),shift=Int.random(in:1...8)
                return build("On a first-quadrant grid, point P(\(x), 3) is translated \(shift) units right. What is its new x-coordinate?",ans:x+shift,story:"Represent a translation on a first-quadrant grid.",hint:"Moving right adds to the x-coordinate.",operands:[x,shift],operators:["+"])
            case 3:
                return conceptQuestion("Which condition guarantees two triangles are congruent?",answer:"All three corresponding side lengths are equal.",choices:["All three corresponding side lengths are equal.","They have the same colour.","They point in the same direction.","They have one side length in common."],hint:"Congruent triangles have the same shape and size.",story:"Recognize and construct congruent triangles.")
            default:
                return conceptQuestion("Which statement is true about a 3-D object drawing?",answer:"Top, front, and side views show the object from different directions.",choices:["Top, front, and side views show the object from different directions.","Every view must look identical.","A side view always shows the top.","Views do not describe an object's shape."],hint:"Match each drawing to the direction from which the object is viewed.",story:"Draw and match top, front, and side views of objects.")
            }
        case "triangles_transformations":
            let x=Int.random(in:0...8),y=Int.random(in:0...8),scale=Int.random(in:1...4),move=Int.random(in:1...6)
            switch Int.random(in:0...1) {
            case 0:
                let newX=x+move*scale
                return build("On a first-quadrant grid where each step is \(scale) units, point P(\(x), \(y)) moves \(move) steps right. What is its new x-coordinate?",ans:newX,story:"Plot and translate coordinates in the first quadrant using a scale.",hint:"Multiply the number of steps by the scale, then add to x.",operands:[x,move,scale],operators:["+","×"])
            default:
                return conceptQuestion("On a first-quadrant grid, point A(2, 3) is moved to B(5, 3). What translation moves A to B?",answer:"3 units right",choices:["3 units right","3 units up","5 units right","2 units left"],hint:"Compare the x- and y-coordinates of both points.",story:"Read coordinates and describe a translation on a scaled grid.")
            }
        case "data":
            return makeGradeFiveDataQuestion()
        case "data_visualization":
            switch Int.random(in:0...3) {
            case 0:
                return conceptQuestion("A data set compares parts of each whole across several groups. Which graph is a good choice?",answer:"Stacked-bar graph",choices:["Stacked-bar graph","Number line","Venn diagram","Clock face"],hint:"Stacked bars show how each group is divided into parts.",story:"Choose and justify a graph that suits the data.")
            case 1:
                return conceptQuestion("What should a clear infographic include?",answer:"A title, labels, a data source, and a suitable display",choices:["A title, labels, a data source, and a suitable display","Only decorative pictures","Unlabelled numbers","A graph with no scale"],hint:"Readers need to know what the data show and where it came from.",story:"Create a clear infographic from data.")
            case 2:
                return conceptQuestion("A graph starts its vertical axis at 98, making a change from 99 to 100 look enormous. What should you do?",answer:"Check the scale and question whether the graph is misleading",choices:["Check the scale and question whether the graph is misleading","Assume the visual size proves the difference","Ignore the labels","Use the bar height only"],hint:"Always inspect axis scales before drawing a conclusion.",story:"Identify misleading graphs and make evidence-based conclusions.")
            default:
                let groups=Int.random(in:2...4),each=Int.random(in:3...9)
                return build("A stacked-bar chart has \(groups) groups with \(each) items in each. How many items altogether?",ans:groups*each,story:"Read and compare a stacked-bar display.",hint:"Find each group's total, then combine the groups.",operands:[groups,each],operators:["×"])
            }
        case "probability":
            if Bool.random() {
                let total=[4,5,8,10,12].randomElement() ?? 8,favorable=Int.random(in:1...total)
                let probability="\(favorable)/\(total)"
                return conceptQuestion("A bag has \(favorable) red counters out of \(total) counters. Express the probability of red as a fraction and place it between 0 and 1 on a probability line.",answer:probability,choices:[probability,"\(total)/\(favorable)","\(favorable)/\(total+1)","1/\(total)"],hint:"Probability is favourable outcomes over all equally likely outcomes.",story:"Express probability as a fraction, locate it from 0 to 1, and use it to predict.")
            }
            let trials=Int.random(in:20...80),favorable=Int.random(in:1...trials-1)
            return conceptQuestion("Two groups each try an experiment \(trials) times. Group A gets \(favorable) successes. What is a reasonable prediction for Group B?",answer:"The success count may be close to \(favorable), but need not be exactly the same.",choices:["The success count may be close to \(favorable), but need not be exactly the same.","The success count will always be exactly \(favorable)."],hint:"Results from equal-sized groups can differ by chance; use repeated trials to test a prediction.",story:"Make and test predictions about experimental likelihood across populations.")
        case "coding_algorithms":
            let start=Int.random(in:1...20),add=Int.random(in:2...9),threshold=Int.random(in:20...80),repeats=Int.random(in:2...6)
            if Bool.random() {
                return conceptQuestion("Code: set n = \(start); repeat \(repeats) times { n = n + \(add) }; if n ≥ \(threshold), print \"ready\", else print \"keep going\". What does it print?",answer:start+repeats*add >= threshold ? "ready" : "keep going",choices:["ready","keep going"],hint:"Trace the repeated update, then evaluate the condition.",story:"Read and execute code with a conditional statement.")
            }
            let revised=add+1,change=repeats
            return conceptQuestion("A loop starts at \(start) and repeats \(repeats) times, adding \(add) each time. If you change the code to add \(revised) each time, how will the final value change?",answer:"It will increase by \(change).",choices:["It will increase by \(change).","It will stay the same.","It will decrease by \(change).","It will increase by 1."],hint:"The update changes by 1 on every repeat.",story:"Read and alter code, then explain how the change affects its result.")
        case "mathematical_modelling":
            let chairs=Int.random(in:4...12),rows=Int.random(in:3...8),aisle=Int.random(in:1...3)
            return build("A venue has \(rows) rows with \(chairs) seats per row, but \(aisle) seats in each row must stay empty for an aisle. How many seats can be used?",ans:rows*(chairs-aisle),story:"Model a real venue constraint and determine its capacity.",hint:"Find usable seats per row, then multiply by the number of rows.",operands:[rows,chairs,aisle],operators:["×","−"])
        case "money":
            switch Int.random(in:0...4) {
            case 0:
                let choices=["Cash or coins","Debit card","Bank transfer or e-transfer","Cheque"]
                return conceptQuestion("Which is an example of transferring money electronically between people or businesses?",answer:choices[2],choices:choices,hint:"An electronic transfer moves money between accounts without handing over cash.",story:"Describe ways money can be transferred among people and organizations.")
            case 1:
                let prices=[Double(Int.random(in:100...599))/100,Double(Int.random(in:100...799))/100],tax=0.13,total=(prices[0]+prices[1])*(1+tax)
                let correct=String(format:"$%.2f",total)
                return conceptQuestion("Two items cost $\(String(format:"%.2f",prices[0])) and $\(String(format:"%.2f",prices[1])). With 13% sales tax, about how much is the total?",answer:correct,choices:[correct,String(format:"$%.2f",prices[0]+prices[1]),String(format:"$%.2f",total+1),String(format:"$%.2f",total-1)],hint:"Add the item prices, then find 13% of the subtotal and add the tax.",story:"Estimate and calculate a transaction with dollars, cents, and sales tax.")
            case 2:
                let unitA=Int.random(in:2...9),unitB=Int.random(in:2...9),countA=4,countB=6
                let better=unitA<unitB ? "Pack A" : unitB<unitA ? "Pack B" : "They cost the same per marker"
                return conceptQuestion("Pack A has \(countA) markers for $\(unitA*countA). Pack B has \(countB) for $\(unitB*countB). Which is the better price per marker?",answer:better,choices:["Pack A","Pack B","They cost the same per marker"],hint:"Divide each pack price by its number of markers and compare unit rates.",story:"Calculate unit rates and identify the best value.")
            case 3:
                return conceptQuestion("Which statement best describes Canadian taxes collected by different levels of government?",answer:"Tax revenue helps pay for public services in communities.",choices:["Tax revenue helps pay for public services in communities.","All tax revenue is kept by stores.","Only the federal government collects taxes.","Taxes are optional fees paid only by tourists."],hint:"Taxes support services such as schools, roads, health care, and community programs.",story:"Identify types of taxes and explain how tax revenue supports communities.")
            default:
                let earning=Int.random(in:20...100),spend=Int.random(in:5...earning/2),save=Int.random(in:5...earning/2)
                return build("You earn $\(earning), spend $\(spend), and save $\(save). How much remains for another goal?",ans:earning-spend-save,story:"Plan a basic budget using income, spending, and saving.",hint:"Subtract planned spending and saving from the income.",operands:[earning,spend,save],operators:["−","−"])
            }
        case "budgeting_credit":
            if Bool.random() {
                return conceptQuestion("What is one difference between credit and debt?",answer:"Credit lets you borrow; debt is the amount you owe.",choices:["Credit lets you borrow; debt is the amount you owe.","Credit is money you saved; debt is interest earned.","They both mean money that never needs to be repaid."],hint:"Borrowing can help with a purchase, but repayment affects future choices.",story:"Explain credit and debt and how they affect financial decisions.")
            }
            let income=Int.random(in:400...600),expense1=Int.random(in:20...80),expense2=Int.random(in:20...80),saving=Int.random(in:20...100)
            return build("A sample monthly budget has $\(income) income, $\(expense1) for needs, $\(expense2) for wants, and $\(saving) saved. How much is left unassigned?",ans:income-expense1-expense2-saving,story:"Design a basic budget that tracks income, spending, and savings.",hint:"Subtract each planned use of money from income.",operands:[income,expense1,expense2,saving],operators:["−","−","−"])
        default:
            return nil
        }
    }

    private func makeGradeFiveDataQuestion()->Question {
        switch Int.random(in:0...7) {
        case 0:
            return conceptQuestion("A school wants to know students' favourite lunch. Which sample is most representative?",answer:"Randomly ask students from every grade",choices:["Randomly ask students from every grade","Ask only the Grade 5 class","Ask only students in the cafeteria line","Ask only the principal's friends"],hint:"A representative sample includes a fair mix from the population.",story:"Choose a sampling technique that represents the population.")
        case 1:
            let total=[20,40,100].randomElement() ?? 20,percent=[10,20,25,50,75].randomElement() ?? 25,count=total*percent/100
            return build("A survey has \(count) yes responses from \(total) people. What percent answered yes?",ans:percent,story:"Organize and interpret data using relative frequency and benchmark percents.",hint:"Write the responses as a fraction of the total, then use an equivalent percent such as 10%, 25%, 50%, or 75%.",operands:[count,100,total],operators:["×","÷"])
        case 2:
            return conceptQuestion("Which table entry is a relative frequency?",answer:"The category count divided by the total, often shown as a fraction or percent",choices:["The category count divided by the total, often shown as a fraction or percent","The category name","The largest raw count only","The survey question"],hint:"Relative frequency compares a category count with all responses.",story:"Read and organize a relative-frequency table.")
        case 3:
            return conceptQuestion("Why might a poll of only students on the school basketball team give a biased answer about favourite sports?",answer:"The sample does not represent the whole school",choices:["The sample does not represent the whole school","The poll has a title","The responses are numbers","The team knows the sport"],hint:"Consider whether every part of the population had a fair chance to be included.",story:"Evaluate data collection and sample bias.")
        case 4:
            let tenths=[Int.random(in:10...29),Int.random(in:20...39),Int.random(in:30...49),Int.random(in:40...59)].sorted(),values=tenths.map{String(format:"%.1f",Double($0)/10)},mean=Double(tenths.reduce(0,+))/40
            return build("Find the mean of \(values.joined(separator:", ")).",ans:mean,story:"Determine and interpret the mean of decimal data to tenths.",hint:"Add all values and divide by how many values there are.",operands:[],operators:[])
        case 5:
            let values=(0..<5).map{_ in Int.random(in:10...80)}.sorted(),median=Double(values[2])/10
            return build("Find the median of \(values.map{String(format:"%.1f",Double($0)/10)}.joined(separator:", ")).",ans:median,story:"Determine the median of a decimal data set.",hint:"Order the values and find the one in the middle.",operands:[],operators:[])
        case 6:
            let mode=Int.random(in:2...12),other=Int.random(in:13...24),values=[mode,mode,mode,other,Int.random(in:13...24)].shuffled()
            return build("Find the mode of \(values.map{String(format:"%.1f",Double($0)/10)}.joined(separator:", ")).",ans:Double(mode)/10,story:"Identify the most frequent value in a decimal data set.",hint:"The mode is the value that appears most often.",operands:[],operators:[])
        default:
            let total=Int.random(in:30...100),part=Int.random(in:1...total-1)
            return conceptQuestion("A data set has \(part) responses in one category out of \(total). What fraction of responses is that before simplifying?",answer:"\(part)/\(total)",choices:["\(part)/\(total)","\(total)/\(part)","\(part)/\(total-part)","1/\(part)"],hint:"Use category count as the numerator and total count as the denominator.",story:"Interpret a category's frequency as part of the total data.")
        }
    }

    private func conceptQuestion(_ prompt:String,answer:String,choices:[String],hint:String,story:String)->Question {
        let options=Array(Set(choices+[answer])).shuffled()
        return Question(prompt:prompt,choices:options,answer:answer,hint:hint,story:story,operands:[],operators:[],numberTiles:[],fractionNumerator:nil,fractionDenominator:nil)
    }

    private func fractionAnswerQuestion(_ prompt:String,answer:String,denominator:Int,hint:String,story:String)->Question {
        let numerator=Int(answer.split(separator:"/").first ?? "0") ?? 0
        let choices=Array(Set([answer,"\(max(0,numerator-1))/\(denominator)","\(min(denominator,numerator+1))/\(denominator)","\(denominator)/\(denominator)"])).shuffled()
        return Question(prompt:prompt,choices:choices,answer:answer,hint:hint,story:story,operands:[],operators:[],numberTiles:[],fractionNumerator:1,fractionDenominator:denominator)
    }

    private func makeGradeFourQuestion(_ topic:Topic)->Question? {
        switch topic.id {
        case "number":
            switch Int.random(in:0...4) {
            case 0:
                let a=Int.random(in:1000...9999),b=Int.random(in:1000...9999)
                return build("Which number is greater: \(a) or \(b)?",ans:max(a,b),story:"Compare whole numbers using place value.",hint:"Compare digits from left to right, starting with the thousands place.",operands:[max(a,b),min(a,b)],operators:[])
            case 1:
                let n=Int.random(in:1000...9999),place=[10,100,1000].randomElement() ?? 100
                let rounded=((n+place/2)/place)*place
                return build("Round \(n) to the nearest \(place).",ans:rounded,story:"Estimate a quantity by rounding to a place value.",hint:"Look at the digit immediately to the right of the rounding place.",operands:[rounded],operators:[])
            case 2:
                let a=Int.random(in:1000...8000),b=Int.random(in:1000...(9999-a))
                return build("A library had \(a) books and received \(b) more. How many books does it have now?",ans:a+b,story:"Solve a real-life addition problem with numbers up to 10,000.",hint:"Add the matching place values, regrouping when needed.",operands:[a,b],operators:["+"])
            case 3:
                let total=Int.random(in:2000...9999),part=Int.random(in:500..<total)
                return build("A school collected \(total) cans and sent \(part) to a food bank. How many cans remain?",ans:total-part,story:"Solve a subtraction problem with numbers up to 10,000.",hint:"Subtract matching place values and regroup if needed.",operands:[total,part],operators:["−"])
            case 4:
                let divisor=Int.random(in:2...9),quotient=Int.random(in:12...(999/divisor)),dividend=divisor*quotient
                return build("Share \(dividend) markers equally among \(divisor) classes. How many markers per class?",ans:quotient,story:"Divide a two- or three-digit whole number by a one-digit number.",hint:"Use place-value strategies, then multiply the quotient by the divisor to check.",operands:[dividend,divisor],operators:["÷"])
            default:
                let a=Int.random(in:12...99),b=Int.random(in:2...9)
                return build("There are \(a) boxes with \(b) pencils in each. How many pencils are there?",ans:a*b,story:"Multiply a two-digit number by a one-digit number.",hint:"Break the two-digit number into tens and ones, multiply each part, then add.",operands:[a,b],operators:["×"])
            }
        case "fractions":
            switch Int.random(in:0...4) {
            case 0:
                let sample=[(1,2,2),(1,3,3),(3,4,2),(2,5,2),(3,5,2)].randomElement() ?? (1,2,2)
                let numerator=sample.0,denominator=sample.1,multiplier=sample.2
                return build("An equivalent fraction to \(numerator)/\(denominator) has denominator \(denominator*multiplier). What is its numerator?",ans:numerator*multiplier,story:"Represent equivalent fractions with denominators up to tenths.",hint:"Multiply the numerator and denominator by the same number.",operands:[numerator,multiplier],operators:["×"])
            case 1:
                let denominator=[2,3,4,5,6,8,10].randomElement() ?? 8
                let a=Int.random(in:1...(denominator-1)),b=Int.random(in:1...(denominator-1))
                return build("Two equal-sized snacks are shared: one share is \(a)/\(denominator) and another is \(b)/\(denominator). How many \(denominator)ths altogether?",ans:a+b,story:"Combine fair shares that use equal-sized fractional parts.",hint:"The parts are the same size, so add the numerators and keep the denominator.",operands:[a,b],operators:["+"])
            case 2:
                let denominator=[3,4,5,6,8,10].randomElement() ?? 8,whole=Int.random(in:1...4),numerator=Int.random(in:1...(denominator-1))
                return build("Write \(whole) and \(numerator)/\(denominator) as an improper fraction. What is the numerator?",ans:whole*denominator+numerator,story:"Connect mixed numbers with equal-sized fractional parts.",hint:"Convert each whole into \(denominator)ths, then add the remaining numerator.",operands:[whole,denominator,numerator],operators:["×","+"])
            case 3:
                let denominator=[4,6,8,10,12].randomElement() ?? 8,first=Int.random(in:1...(denominator-1)),second=Int.random(in:1...(denominator-1))
                return build("Which is greater: \(first)/\(denominator) or \(second)/\(denominator)? Give the greater numerator.",ans:max(first,second),story:"Compare fair-share amounts made of equal-sized parts.",hint:"When denominators match, the fraction with more parts is greater.",operands:[max(first,second)],operators:[])
            default:
                let denominator=[2,3,4,5,6,8,10].randomElement() ?? 6,parts=Int.random(in:2...denominator)
                return build("A whole is shared equally among \(denominator) people. How many shares make \(parts)/\(denominator) of the whole?",ans:parts,story:"Interpret a fraction as a number of equal fair shares.",hint:"Each person receives one \(denominator)th; count the shares needed.",operands:[parts],operators:[])
            }
        case "decimals_percentages":
            switch Int.random(in:0...3) {
            case 0:
                let a=Int.random(in:1...9),b=Int.random(in:1...9),lo=min(a,b),hi=max(a,b)
                return build("Which decimal is greater: 0.\(lo) or 0.\(hi)? Give its tenths digit.",ans:hi,story:"Compare decimals representing tenths.",hint:"The digit in the tenths place tells how many tenths each decimal has.",operands:[hi],operators:[])
            case 1:
                let a=Int.random(in:1...8),b=Int.random(in:1...8)
                return build("What is \(a).\(b) + 0.\(10-b)? Give the tenths digit of the sum.",ans:a+1,story:"Add decimal tenths by connecting them to whole-number units.",hint:"The tenths add to 10 tenths, which is one whole.",operands:[a,b,10-b],operators:["+"])
            case 2:
                let tenths=Int.random(in:1...9),whole=Int.random(in:2...8)
                return build("How many tenths are in \(whole).\(tenths)?",ans:whole*10+tenths,story:"Rename a decimal using tenths.",hint:"Each whole contains 10 tenths; then count the extra tenths.",operands:[whole,10,tenths],operators:["×","+"])
            default:
                let n=Int.random(in:11...99)
                return build("A length is \(n) tenths of a metre. How many metres is that? Give the number of tenths in the answer.",ans:n,story:"Relate tenths to metric measurement.",hint:"Ten tenths make one whole metre; the tenths digit records the remaining part.",operands:[n],operators:[])
            }
        case "algebra":
            switch Int.random(in:0...3) {
            case 0:
                let start=Int.random(in:2...12),step=Int.random(in:2...9)
                return build("Growing pattern: \(start), \(start+step), \(start+2*step), __. What comes next?",ans:start+3*step,story:"Find and extend a growing pattern.",hint:"Find how much is added each time, then add it once more.",operands:[start+2*step,step],operators:["+"])
            case 1:
                let known=Int.random(in:10...35),x=Int.random(in:10...70)
                return build("Complete the equation: \(known) + n = \(known+x). What is n?",ans:x,story:"Use a variable for an unknown quantity in an equation.",hint:"Find the missing addend by subtracting the known addend from the total.",operands:[known+x,known],operators:["−"])
            case 2:
                let a=Int.random(in:2...8),x=Int.random(in:2...12),b=Int.random(in:1...15)
                return build("A pattern rule is output = \(a) × input + \(b). What is the output when input = \(x)?",ans:a*x+b,story:"Represent a pattern relationship with a rule.",hint:"Substitute the input, multiply first, then add.",operands:[a,x,b],operators:["×","+"])
            default:
                return build("A group has fewer than 20 students. What is the greatest possible whole-number group size?",ans:19,story:"Interpret an inequality as a range of possible values.",hint:"Fewer than 20 means any whole number below 20; choose the greatest one.",operands:[20,1],operators:["−"])
            }
        case "spatial":
            switch Int.random(in:0...3) {
            case 0:
                return build("A rectangle has how many pairs of parallel opposite sides?",ans:2,story:"Identify parallel sides using geometric properties.",hint:"Both pairs of opposite sides stay the same distance apart.",operands:[2],operators:[])
            case 1:
                return build("How many lines of symmetry does a square have?",ans:4,story:"Identify symmetry in a familiar two-dimensional shape.",hint:"Count the vertical, horizontal, and two diagonal fold lines.",operands:[4],operators:[])
            case 2:
                return build("A cube has how many vertices (corners)?",ans:8,story:"Describe a three-dimensional object using its geometric properties.",hint:"Count the corners where three edges meet.",operands:[8],operators:[])
            default:
                return buildSelection("Start facing north. Turn a quarter-turn right, then a half-turn. Which direction are you facing? (1 = N, 2 = E, 3 = S, 4 = W)",answer:3,choiceCount:4,story:"Follow multistep directions that include quarter- and half-turns.",hint:"A quarter-turn right faces east; a half-turn from there faces south.")
            }
        case "measurement":
            switch Int.random(in:0...7) {
            case 0:
                let amount=Int.random(in:2...9)
                return build("Convert \(amount) metres to centimetres.",ans:amount*100,story:"Choose and convert metric units for length.",hint:"1 metre = 100 centimetres.",operands:[amount,100],operators:["×"])
            case 1:
                let amount=Int.random(in:2...8)
                return build("Convert \(amount) kilograms to grams.",ans:amount*1000,story:"Choose and convert metric units for mass.",hint:"1 kilogram = 1,000 grams.",operands:[amount,1000],operators:["×"])
            case 2:
                let amount=Int.random(in:2...9)
                return build("Convert \(amount) litres to millilitres.",ans:amount*1000,story:"Choose and convert metric units for capacity.",hint:"1 litre = 1,000 millilitres.",operands:[amount,1000],operators:["×"])
            case 3:
                let l=Int.random(in:3...20),w=Int.random(in:3...15)
                return build("A rectangle is \(l) cm long and \(w) cm wide. What is its area in square centimetres?",ans:l*w,story:"Measure area by counting equal square units in an array.",hint:"Area = length × width; use square centimetres.",operands:[l,w],operators:["×"])
            case 4:
                let l=Int.random(in:3...30),w=Int.random(in:3...20)
                return build("A rectangular garden is \(l) m by \(w) m. How many metres of fencing are needed around it?",ans:2*l+2*w,story:"Use perimeter to solve a measurement problem.",hint:"Add all four sides: length + width + length + width.",operands:[l,w,2],operators:["×","+"])
            case 5:
                let start=Int.random(in:5...50),afterHour=Int.random(in:0...59),elapsed=60-start+afterHour
                return build("An activity starts at 10:\(String(format:"%02d",start)) and ends at 11:\(String(format:"%02d",afterHour)). How many minutes pass?",ans:elapsed,story:"Calculate elapsed time across an hour.",hint:"Count to 11:00, then add the minutes after 11:00.",operands:[60-start,afterHour],operators:["+"])
            case 6:
                let angleType=Int.random(in:0...3)
                let degrees=[Int.random(in:20...85),90,Int.random(in:95...170),180][angleType]
                return buildSelection("An angle measures \(degrees)°. Classify it: (1 = acute, 2 = right, 3 = obtuse, 4 = straight)",answer:angleType+1,choiceCount:4,story:"Classify angles by comparing them with a right angle and a straight angle.",hint:"Acute is less than 90°, right is 90°, obtuse is between 90° and 180°, and straight is 180°.")
            default:
                let width=Int.random(in:2...12),height=Int.random(in:2...12),area=width*height
                if Bool.random() {return build("A rectangle has area \(area) cm² and width \(width) cm. What is its length in centimetres?",ans:height,story:"Find a missing rectangle dimension using its area.",hint:"Divide the area by the known side length.",operands:[area,width],operators:["÷"])}
                return build("A rectangle has area \(area) cm² and length \(height) cm. What is its width in centimetres?",ans:width,story:"Find a missing rectangle dimension using its area.",hint:"Divide the area by the known side length.",operands:[area,height],operators:["÷"])
            }
        case "data":
            switch Int.random(in:0...6) {
            case 0:
                let values=(0..<5).map{_ in Int.random(in:10...99)}.sorted()
                let median=values[2]
                return build("The data values are \(values.map(String.init).joined(separator:", ")). What is the median?",ans:median,story:"Find the middle value after ordering a data set.",hint:"The values are in order. The middle of five values is the third value.",operands:[median],operators:[])
            case 1:
                let counts=(0..<3).map{_ in Int.random(in:2...12)},chosen=Int.random(in:0...2)
                return build("Frequency table: red \(counts[0]), blue \(counts[1]), green \(counts[2]). How many chose \(["red","blue","green"][chosen])?",ans:counts[chosen],story:"Read one category's frequency from a table.",hint:"Find the count beside the requested category.",operands:[counts[chosen]],operators:[])
            case 2:
                let counts=(0..<3).map{_ in Int.random(in:2...18)},hi=counts.max() ?? 0,lo=counts.min() ?? 0
                return build("Collected scores are \(counts[0]), \(counts[1]) and \(counts[2]). How many more is the largest than the smallest?",ans:hi-lo,story:"Interpret the spread in collected data.",hint:"Subtract the smallest count from the largest.",operands:[hi,lo],operators:["−"])
            case 3:
                var values=(0..<4).map{_ in Int.random(in:1...9)}
                let partial=values.reduce(0,+),last=(1...9).first{(partial+$0).isMultiple(of:5)} ?? 5
                values.append(last)
                let sum=values.reduce(0,+)
                return build("Data set: \(values.map(String.init).joined(separator:", ")). What is the mean?",ans:sum/values.count,story:"Find the mean of a whole-number data set.",hint:"Add all values and divide by the number of values.",operands:[sum,values.count],operators:["÷"])
            case 4:
                let mode=Int.random(in:2...8),a=Int.random(in:1...9),b=Int.random(in:1...9)
                return build("Data set: \(mode), \(a), \(mode), \(b), \(mode). What is the mode?",ans:mode,story:"Identify the value that occurs most often.",hint:"The mode is the value that appears most often.",operands:[mode],operators:[])
            case 5:
                let leaves=(0..<4).map{_ in Int.random(in:0...9)}.sorted()
                return build("Stem-and-leaf plot: 2 | \(leaves.map(String.init).joined(separator:" ")). How many values are in the 20s?",ans:leaves.count,story:"Read a stem-and-leaf plot using its key and leaves.",hint:"The stem 2 represents the twenties; count the leaves beside it.",operands:[leaves.count],operators:[])
            case 6:
                return buildSelection("A class wants to find out which playground games students prefer. Which is a primary source? (1 = ask students in a survey, 2 = read a published report, 3 = use last year's unrelated data, 4 = guess)",answer:1,choiceCount:4,story:"Choose a suitable source when collecting data to answer a question.",hint:"A primary source gathers new information directly from the people involved.")
            default: return nil
            }
        case "data_visualization":
            let a=Int.random(in:2...7),b=Int.random(in:2...7),c=Int.random(in:2...7)
            switch Int.random(in:0...2) {
            case 0:
                return build("A stem-and-leaf plot has stems 2 | 4, 7 and 3 | 1, 5. How many data values are shown?",ans:4,story:"Read a stem-and-leaf plot by counting its leaves.",hint:"Each leaf represents one data value.",operands:[4],operators:[])
            case 1:
                let hi=max(a,max(b,c)),lo=min(a,min(b,c))
                return build("A multiple-bar graph shows Group A = \(a), Group B = \(b), and Group C = \(c). How many more are in the largest group than the smallest?",ans:hi-lo,story:"Read and compare values in a multiple-bar graph.",hint:"Compare the labelled values, then subtract the smallest from the largest.",operands:[hi,lo],operators:["−"])
            default:
                return build("An infographic compares three groups: A has \(a), B has \(b), and C has \(c) responses. How many responses should it represent altogether?",ans:a+b+c,story:"Check that a data story represents every group's information.",hint:"Add the frequency from each group.",operands:[a,b,c],operators:["+","+"])
            }
        case "probability":
            switch Int.random(in:0...3) {
            case 0:
                let event=Int.random(in:0...4)
                let likelihood=["impossible","unlikely","equally likely","likely","certain"][event]
                return buildSelection("Likelihood line: 1 = impossible, 2 = unlikely, 3 = equally likely, 4 = likely, 5 = certain. What number matches ‘\(likelihood)’?",answer:event+1,choiceCount:5,story:"Place likelihood words on a probability line.",hint:"Impossible and certain are at opposite ends; equally likely is in the middle.")
            case 1:
                return buildSelection("A bag contains only red and blue counters. What number describes drawing a green counter? (1 = impossible, 2 = unlikely, 3 = equally likely, 4 = likely, 5 = certain)",answer:1,choiceCount:5,story:"Use the possible outcomes to describe likelihood.",hint:"There are no green counters in the bag.")
            case 2:
                return buildSelection("A fair coin is flipped. Heads and tails have the same chance. On the line 1 = impossible, 2 = unlikely, 3 = equally likely, 4 = likely, 5 = certain, what number describes getting heads?",answer:3,choiceCount:5,story:"Use a probability line to describe equally likely outcomes.",hint:"Heads and tails have equal chances, so use the middle label.")
            default:
                return buildSelection("Two groups of the same size are surveyed. Group A's median is 6. Does that guarantee Group B's median will also be 6? (1 = yes, always; 2 = no, it may differ)",answer:2,choiceCount:2,story:"Make a prediction about whether a data measure will match across two populations.",hint:"Different groups can have different data values and different medians.")
            }
        case "coding_algorithms":
            switch Int.random(in:0...2) {
            case 0:
                let stage=Int.random(in:2...8)
                return build("Geometric pattern code: one square uses 4 sticks; each new square shares a side and adds 3. How many sticks for \(stage) squares?",ans:3*stage+1,story:"Model a growing shape pattern with a rule.",hint:"The first square uses 4; each additional square adds 3.",operands:[3,stage,1],operators:["×","+"])
            case 1:
                let start=Int.random(in:2...15),add=Int.random(in:2...6),loops=Int.random(in:2...6)
                return build("Loop: start at \(start), then repeat \(loops) times: add \(add). What value does the code print?",ans:start+add*loops,story:"Trace a loop and predict its output.",hint:"Add \(add) once for every loop.",operands:[start,add,loops],operators:["+","×"])
            default:
                let repeatCount=Int.random(in:2...6),bug=Int.random(in:1...4)
                return build("Debug: a loop should add \(bug+2) each time, but adds \(bug) for \(repeatCount) repeats. How much too small is its output?",ans:2*repeatCount,story:"Compare intended code with buggy code and find the error.",hint:"Each repeat is short by 2. Multiply that error by the repeat count.",operands:[repeatCount,2],operators:["×"])
            }
        case "money":
            switch Int.random(in:0...3) {
            case 0:
                return buildSelection("Payment methods: 1 = cash, 2 = debit, 3 = credit, 4 = e-transfer. Which method uses money already in a chequing account at checkout?",answer:2,choiceCount:4,story:"Identify different ways to pay for goods and services.",hint:"A debit payment comes from money in an account; credit is borrowing.")
            case 1:
                let priceA=Int.random(in:2...20),priceB=Int.random(in:2...20),priceC=Int.random(in:2...20),total=priceA+priceB+priceC
                return build("A student buys items priced $\(priceA), $\(priceB), and $\(priceC), all whole-dollar prices. What is the total before tax?",ans:total,story:"Estimate and calculate the cost of several items using mental math.",hint:"Add the whole-dollar prices; no sales tax is included.",operands:[priceA,priceB,priceC],operators:["+","+"])
            case 2:
                let prices=(0..<3).map{_ in Int.random(in:2...20)},total=prices.reduce(0,+),paid=((total+9)/10)*10
                return build("Items cost $\(prices[0]), $\(prices[1]), and $\(prices[2]). You pay $\(paid) cash. How much change should you get?",ans:paid-total,story:"Calculate cash change after buying multiple whole-dollar items.",hint:"Add the prices, then subtract the total from the cash paid.",operands:[paid,total],operators:["−"])
            default:
                return buildSelection("Two stores sell a similar toy. Store A costs $18; Store B costs $15 but has poor reviews. What should you consider before deciding? (1 = only the lowest price, 2 = price and quality/reviews, 3 = which ad is loudest, 4 = always the most expensive)",answer:2,choiceCount:4,story:"Consider price, quality, and reviews when deciding whether something is a good purchase.",hint:"A reasonable purchase depends on more than the price tag.")
            }
        case "budgeting_credit":
            switch Int.random(in:0...2) {
            case 0:
                return build("A student earns $12 and spends $5. How much of the $12 is not spent and could be saved?",ans:7,story:"Connect spending and saving decisions.",hint:"Subtract the amount spent from the amount earned.",operands:[12,5],operators:["−"])
            case 1:
                return buildSelection("A person gives money to support a community food bank. Which financial action is this? (1 = earning, 2 = investing, 3 = donating, 4 = spending)",answer:3,choiceCount:4,story:"Distinguish earning, saving, investing, spending, and donating.",hint:"Giving money to support a cause is donating.")
            default:
                return build("A student wants to save for a $30 book. They earn $10 and spend $6. How much of that earning can they add to their savings?",ans:4,story:"Explain how spending choices affect the amount available to save.",hint:"Subtract spending from earning.",operands:[10,6],operators:["−"])
            }
        case "mental_math_place_value":
            switch Int.random(in:0...2) {
            case 0:
                let n=Int.random(in:1000...9999),place=[10,100,1000].randomElement() ?? 100,digit=(n/place)%10
                return build("In \(n), what is the value of the digit in the \(placeName(place)) place?",ans:digit*place,story:"Use place value to describe a digit in a number up to 10,000.",hint:"Multiply the digit by its place value.",operands:[digit,place],operators:["×"])
            case 1:
                let a=Int.random(in:20...99),b=Int.random(in:2...9)
                return build("Use a mental strategy to find \(a) × \(b).",ans:a*b,story:"Use known multiplication facts and place-value strategies.",hint:"Break \(a) into tens and ones, multiply each by \(b), then combine.",operands:[a,b],operators:["×"])
            default:
                let n=Int.random(in:100...999),rounded=((n+50)/100)*100
                return build("Estimate \(n) rounded to the nearest hundred.",ans:rounded,story:"Use benchmarks and mental math to estimate a quantity.",hint:"Check the tens digit to decide whether to round up or down.",operands:[rounded],operators:[])
            }
        case "mathematical_modelling":
            switch Int.random(in:0...2) {
            case 0:
                let fixed=Int.random(in:20...80),rate=Int.random(in:3...12),group=Int.random(in:4...12)
                return build("A model for a trip is $\(fixed) + $\(rate) per student. Predict the cost for \(group) students.",ans:fixed+rate*group,story:"Use a real-world model to predict a total cost.",hint:"Multiply the per-student cost by the group, then add the fixed cost.",operands:[fixed,rate,group],operators:["+","×"])
            case 1:
                let predicted=Int.random(in:20...60),actual=Int.random(in:20...60)
                return build("A model predicts \(predicted) visitors; the actual count is \(actual). By how much was the prediction off?",ans:abs(predicted-actual),story:"Test a prediction against collected results.",hint:"Find the distance between the prediction and actual value.",operands:[max(predicted,actual),min(predicted,actual)],operators:["−"])
            default:
                let budget=Int.random(in:80...200),cost=Int.random(in:20...70),groups=Int.random(in:2...4),left=budget-cost*groups
                if left >= 0 {return build("A plan has $\(budget). Each of \(groups) teams needs $\(cost). How much remains?",ans:left,story:"Evaluate whether a proposed plan fits the available budget.",hint:"Multiply the cost for one team by the number of teams, then subtract.",operands:[budget,cost,groups],operators:["−","×"])}
                return build("A plan has $\(budget) and needs $\(cost) for each of \(groups) teams. How much extra money is needed?",ans:abs(left),story:"Check whether a modelled plan is affordable.",hint:"Compare the total need with the budget.",operands:[cost,groups,budget],operators:["×","−"])
            }
        case "triangles_transformations":
            switch Int.random(in:0...2) {
            case 0:
                let x=Int.random(in:1...8),move=Int.random(in:1...5)
                return build("Point P is at x = \(x) on a grid. Translate it \(move) units right. What is its new x-coordinate?",ans:x+move,story:"Describe a translation on a grid.",hint:"Moving right increases the x-coordinate by the distance moved.",operands:[x,move],operators:["+"])
            case 1:
                let x=Int.random(in:1...7),move=Int.random(in:1...5)
                return build("Point P is at y = \(x) on a grid. Translate it \(move) units up. What is its new y-coordinate?",ans:x+move,story:"Describe a translation on a grid.",hint:"Moving up increases the y-coordinate by the distance moved.",operands:[x,move],operators:["+"])
            default:
                let axis=Int.random(in:3...6),x=Array(1...(axis*2-1)).filter{$0 != axis}.randomElement() ?? 1
                return build("Point P is at x = \(x). Reflect it across the vertical grid line x = \(axis). What is the new x-coordinate?",ans:2*axis-x,story:"Predict the result of a reflection on a grid.",hint:"The image is the same distance on the other side of the mirror line.",operands:[2,axis,x],operators:["×","−"])
            }
        default: return nil
        }
    }

    private func makeFractionQuestion(grade:Int)->Question {
        if grade <= 3 {
            switch Int.random(in:0...3) {
            case 0:
                let samples=[(1,2,2),(1,3,3),(3,4,2),(2,5,2),(3,5,2)].randomElement() ?? (1,2,2)
                let numerator=samples.0,denominator=samples.1,multiplier=samples.2
                return makeFractionChoiceQuestion("An equivalent fraction to \(numerator)/\(denominator) has denominator \(denominator*multiplier). What is its numerator?",answer:String(numerator*multiplier),distractors:(0...denominator*multiplier).map(String.init),hint:"Multiply the numerator and denominator by the same number.",story:"Keep the amount the same while splitting each part into smaller equal pieces.")
            case 1:
                let sharers=[2,3,4,5,6,8,10].randomElement() ?? 4
                return makeFractionChoiceQuestion("One whole is shared equally among \(sharers) children. What fraction of the whole does each child get?",answer:"1/\(sharers)",distractors:["1/\(sharers-1)","2/\(sharers)","1/\(sharers+1)","\(sharers)/1"],hint:"One equal share is one unit fraction.",story:"Imagine sharing one snack fairly so every child gets the same amount.")
            case 2:
                var denominators=Array(2...10).shuffled()
                let a=denominators.removeFirst(),b=denominators.first(where:{$0 != a}) ?? a+1
                let larger=a < b ? "1/\(a)" : "1/\(b)"
                return makeFractionChoiceQuestion("Which share is larger: 1/\(a) of a whole or 1/\(b) of the same-sized whole?",answer:larger,distractors:["1/\(a)","1/\(b)","1/\(a+b)","1/\(max(a,b)+1)"],hint:"When a whole is split into fewer equal parts, each part is larger.",story:"Compare the size of one fair share when the number of sharers changes.")
            default:
                let denominator=[2,3,4,5,6,8,10].randomElement() ?? 4
                let parts=Int.random(in:2...denominator)
                return build("How many one-\(denominator)th pieces make \(parts)/\(denominator) of a whole?",ans:parts,story:"Count equal unit fractions to build a larger fraction.",hint:"Each piece is one \(denominator)th. Count the pieces.",operands:[parts],operators:[])
            }
        }
        switch Int.random(in:0...3) {
        case 0:
            let denominator=Int.random(in:4...12),a=Int.random(in:1...(denominator-2)),b=Int.random(in:1...(denominator-a))
            let answer="\(a+b)/\(denominator)"
            return makeFractionChoiceQuestion("Add \(a)/\(denominator) + \(b)/\(denominator).",answer:answer,distractors:["\(a+b+1)/\(denominator)","\(abs(a-b))/\(denominator)","\(a)/\(denominator)","\(b)/\(denominator)"],hint:"The parts are the same size, so add the numerators and keep the denominator.",story:"Combine fractional parts that name equal-sized pieces.")
        case 1:
            let denominator=Int.random(in:4...12),a=Int.random(in:2...denominator),b=Int.random(in:1..<a)
            let answer="\(a-b)/\(denominator)"
            return makeFractionChoiceQuestion("Subtract \(b)/\(denominator) from \(a)/\(denominator).",answer:answer,distractors:["\(a+b)/\(denominator)","\(a)/\(denominator)","\(b)/\(denominator)","\(a-b+1)/\(denominator)"],hint:"The denominators match. Subtract the numerators and keep the denominator.",story:"Find what remains after removing one fractional amount from another.")
        case 2:
            let pairs=[(2,4),(3,6),(4,8),(5,10)],pair=pairs.randomElement() ?? (2,4)
            let a=Int.random(in:1...(pair.0-1)),b=Int.random(in:1...(pair.1-1))
            let numerator=a*(pair.1/pair.0)+b,answer="\(numerator)/\(pair.1)"
            return makeFractionChoiceQuestion("Find \(a)/\(pair.0) + \(b)/\(pair.1). Give an equivalent fraction with denominator \(pair.1).",answer:answer,distractors:["\(a+b)/\(pair.1)","\(abs(a*(pair.1/pair.0)-b))/\(pair.1)","\(numerator+1)/\(pair.1)","\(b)/\(pair.1)"],hint:"Rename the fraction with denominator \(pair.0) using denominator \(pair.1), then add.",story:"Rename fractional parts so they refer to equal-sized pieces before adding.")
        default:
            let denominator=Int.random(in:3...10),numerator=Int.random(in:1...(denominator-1)),whole=Int.random(in:2...6)
            return makeFractionChoiceQuestion("What is \(whole) × \(numerator)/\(denominator)? Give the numerator of the result.",answer:String(whole*numerator),distractors:(0...(whole*numerator+3)).map(String.init),hint:"Multiply the whole number by the numerator; the denominator stays the same.",story:"Find the total when the same fractional amount is taken several times.")
        }
    }

    private func makeFractionChoiceQuestion(_ prompt:String,answer:String,distractors:[String],hint:String,story:String)->Question {
        var options=Array(Set(distractors.filter{$0 != answer})).shuffled().prefix(3).map{$0}
        while options.count < 3 {
            let candidate="\(options.count+1)/\(options.count+4)"
            if candidate != answer && !options.contains(candidate) { options.append(candidate) }
        }
        return Question(prompt:prompt,choices:([answer]+options).shuffled(),answer:answer,hint:hint,story:story,operands:[],operators:[],numberTiles:[],fractionNumerator:nil,fractionDenominator:nil)
    }
    private func buildSelection(_ prompt:String,answer:Int,choiceCount:Int,story:String,hint:String)->Question {
        let choices=(1...choiceCount).map(String.init)
        return Question(prompt:prompt,choices:choices,answer:String(answer),hint:hint,story:story,operands:[],operators:[],numberTiles:[],fractionNumerator:nil,fractionDenominator:nil)
    }
    private func build(_ prompt:String,ans:Int,story:String,hint:String,operands:[Int],operators:[String])->Question {
        let generatedExpression=arithmeticExpression(operands:operands,operators:operators,answer:ans)
        let useCalculationForm=generatedExpression != nil && Int.random(in:0...2) == 0
        let finalPrompt=useCalculationForm ? generatedExpression!.prompt : prompt
        let finalStory=useCalculationForm ? "Solve the number sentence using a strategy that makes sense to you." : story
        let finalHint=useCalculationForm ? generatedExpression!.hint : hint
        let correct=String(ans);var options=Set([ans]);while options.count<4 { options.insert(max(0,ans+Int.random(in:-max(3,ans/2)...max(3,ans/2)))) };let choices=options.map(String.init).shuffled()
        var tiles=operands
        var used=Set(operands)
        while tiles.count < operands.count+3 { let candidate=Int.random(in:1...max(15,operands.max() ?? 15));if used.insert(candidate).inserted { tiles.append(candidate) } }
        return Question(prompt:finalPrompt,choices:choices,answer:correct,hint:finalHint,story:finalStory,operands:operands,operators:operators,numberTiles:tiles.shuffled(),fractionNumerator:nil,fractionDenominator:nil)
    }

    private func arithmeticExpression(operands:[Int],operators:[String],answer:Int)->(prompt:String,hint:String)? {
        guard operands.count >= 2,operators.count == operands.count-1 else { return nil }
        var values=[operands[0]]
        var pendingOperators:[String]=[]
        for (index,op) in operators.enumerated() {
            let next=operands[index+1]
            switch op {
            case "×":
                guard let previous=values.popLast() else { return nil }
                values.append(previous*next)
            case "÷":
                guard next != 0,let previous=values.popLast(),previous.isMultiple(of:next) else { return nil }
                values.append(previous/next)
            case "+","−":
                pendingOperators.append(op)
                values.append(next)
            default: return nil
            }
        }
        guard var result=values.first else { return nil }
        for (index,op) in pendingOperators.enumerated() {
            let next=values[index+1]
            result = op == "+" ? result+next : result-next
        }
        guard result == answer else { return nil }
        let expression=operands.enumerated().map { index,value in
            index == 0 ? String(value) : "\(operators[index-1]) \(value)"
        }.joined(separator:" ")
        if operands.count == 2,let op=operators.first {
            switch op {
            case "+": return ("Add \(operands[0]) and \(operands[1]).","Combine the two addends.")
            case "−": return ("Find the difference: \(operands[0]) − \(operands[1]).","Subtract the second number from the first.")
            case "×": return ("Find the product of \(operands[0]) and \(operands[1]).","Use equal groups or a known multiplication fact.")
            case "÷": return ("Divide \(operands[0]) by \(operands[1]).","Think about how many equal groups of the divisor fit in the dividend.")
            default: break
            }
        }
        return ("Calculate: \(expression).","Follow the operations in order, using multiplication and division before addition and subtraction.")
    }

    private func build(_ prompt:String,ans:Double,story:String,hint:String,operands:[Int],operators:[String])->Question {
        let rounded=(ans*100).rounded()/100
        let generatedExpression=arithmeticExpression(operands:operands,operators:operators,answer:rounded)
        let useCalculationForm=generatedExpression != nil && Int.random(in:0...2) == 0
        let finalPrompt=useCalculationForm ? generatedExpression!.prompt : prompt
        let finalStory=useCalculationForm ? "Solve the number sentence and give your answer to the nearest cent." : story
        let finalHint=useCalculationForm ? generatedExpression!.hint : hint
        let correct=String(format:"%.2f",rounded)
        var options=Set([correct])
        for offset in [-2.0,-1.0,1.0,2.0] { options.insert(String(format:"%.2f",max(0,rounded+offset))) }
        var tiles=operands
        var used=Set(operands)
        while tiles.count < operands.count+3 { let candidate=Int.random(in:1...max(15,operands.max() ?? 15));if used.insert(candidate).inserted { tiles.append(candidate) } }
        return Question(prompt:finalPrompt,choices:Array(options).shuffled(),answer:correct,hint:finalHint,story:finalStory,operands:operands,operators:operators,numberTiles:tiles.shuffled(),fractionNumerator:nil,fractionDenominator:nil)
    }

    private func arithmeticExpression(operands:[Int],operators:[String],answer:Double)->(prompt:String,hint:String)? {
        guard operands.count >= 2,operators.count == operands.count-1 else { return nil }
        var values=[Double(operands[0])]
        var pendingOperators:[String]=[]
        for (index,op) in operators.enumerated() {
            let next=Double(operands[index+1])
            switch op {
            case "×":
                guard let previous=values.popLast() else { return nil }
                values.append(previous*next)
            case "÷":
                guard next != 0,let previous=values.popLast() else { return nil }
                values.append(previous/next)
            case "+","−":
                pendingOperators.append(op)
                values.append(next)
            default: return nil
            }
        }
        guard var result=values.first else { return nil }
        for (index,op) in pendingOperators.enumerated() {
            let next=values[index+1]
            result = op == "+" ? result+next : result-next
        }
        guard abs((result*100).rounded()/100-answer) < 0.001 else { return nil }
        let expression=operands.enumerated().map { index,value in
            index == 0 ? String(value) : "\(operators[index-1]) \(value)"
        }.joined(separator:" ")
        return ("Calculate: \(expression). Give your answer to the nearest cent.","Follow the operations in order, then round to two decimal places.")
    }

}
