import SwiftUI

enum CurriculumCatalog {
    static let shopCharacters: [ShopCharacter] = [
        ShopCharacter(id:"Maple",emoji:"🦊",price:0,description:"Your first trail buddy"),
        ShopCharacter(id:"Pip",emoji:"🐼",price:280,description:"A curious puzzle pal"),
        ShopCharacter(id:"Nova",emoji:"🦉",price:350,description:"A stargazing scholar"),
        ShopCharacter(id:"Cedar",emoji:"🐻",price:420,description:"A brave forest explorer"),
        ShopCharacter(id:"Comet",emoji:"🐉",price:500,description:"A legendary math adventurer"),
        ShopCharacter(id:"Mochi",emoji:"🐱",price:300,description:"A clever little calculator"),
        ShopCharacter(id:"Waddles",emoji:"🐧",price:320,description:"A cool companion for tricky puzzles"),
        ShopCharacter(id:"Bubbles",emoji:"🐬",price:340,description:"A speedy ocean explorer"),
        ShopCharacter(id:"Thistle",emoji:"🐰",price:360,description:"A quick-thinking trail scout"),
        ShopCharacter(id:"Shellby",emoji:"🐢",price:380,description:"A patient problem solver"),
        ShopCharacter(id:"Sunny",emoji:"🦁",price:400,description:"A fearless number champion"),
        ShopCharacter(id:"Sprinkles",emoji:"🦄",price:440,description:"A magical math companion"),
        ShopCharacter(id:"Byte",emoji:"🤖",price:480,description:"A robot who loves patterns"),
        ShopCharacter(id:"Puddle",emoji:"🐸",price:310,description:"A cheerful pond-hopping puzzle solver"),
        ShopCharacter(id:"Acorn",emoji:"🐿️",price:330,description:"A speedy squirrel who gathers number facts"),
        ShopCharacter(id:"Orbit",emoji:"👩‍🚀",price:520,description:"A space explorer searching for star patterns"),
        ShopCharacter(id:"Coral",emoji:"🧜‍♀️",price:460,description:"A deep-sea guide who loves tricky fractions"),
        ShopCharacter(id:"Frost",emoji:"🐺",price:490,description:"A cool-headed wolf who plans every move"),
        ShopCharacter(id:"Peaches",emoji:"🐻‍❄️",price:430,description:"A kind polar bear with a sharp sense of number"),
        ShopCharacter(id:"Zigzag",emoji:"🦓",price:390,description:"A pattern expert with stripes for days"),
        ShopCharacter(id:"Poppy",emoji:"🐝",price:370,description:"A busy bee who collects math discoveries"),
        ShopCharacter(id:"Moss",emoji:"🦎",price:410,description:"A clever gecko who can adapt to any puzzle"),
        ShopCharacter(id:"Tango",emoji:"🦩",price:450,description:"A flamingo who keeps every equation balanced"),
        ShopCharacter(id:"Rumble",emoji:"🦖",price:550,description:"A tiny dinosaur with a giant appetite for math"),
        ShopCharacter(id:"Lumi",emoji:"🦋",price:470,description:"A bright butterfly who loves transformations"),
        ShopCharacter(id:"Marbles",emoji:"🦭",price:510,description:"A playful seal who makes waves with data"),
        ShopCharacter(id:"Pixel",emoji:"👾",price:600,description:"A rare arcade buddy who masters every level")
    ]

    static let topics: [Topic] = [
        .init(id:"number", title:"Number & operations", subtitle:"Whole numbers and calculations", icon:"number", color:Color(red:0.98,green:0.46,blue:0.31), grades:1...12, strand:"Number"),
        .init(id:"fractions", title:"Fractions & equal parts", subtitle:"Represent and compare fractions", icon:"circle.lefthalf.filled", color:Color(red:0.91,green:0.43,blue:0.63), grades:2...8, strand:"Number — fractions"),
        .init(id:"algebra", title:"Patterns & algebra", subtitle:"Find pattern rules and solve equations", icon:"arrow.left.arrow.right", color:Color(red:0.47,green:0.42,blue:0.88), grades:1...12, strand:"Algebra"),
        .init(id:"spatial", title:"Shapes & space", subtitle:"Describe shapes, position, and movement", icon:"square.on.circle", color:Color(red:0.19,green:0.67,blue:0.62), grades:1...12, strand:"Spatial sense"),
        .init(id:"measurement", title:"Measurement", subtitle:"Measure time, length, area, and more", icon:"ruler", color:Color(red:0.98,green:0.70,blue:0.25), grades:1...12, strand:"Measurement"),
        .init(id:"data", title:"Data", subtitle:"Collect, organize, and interpret information", icon:"chart.bar.xaxis", color:Color(red:0.35,green:0.62,blue:0.91), grades:1...12, strand:"Data"),
        .init(id:"money", title:"Money & decisions", subtitle:"Make spending and saving decisions", icon:"dollarsign.circle", color:Color(red:0.29,green:0.68,blue:0.42), grades:1...12, strand:"Financial literacy"),
        .init(id:"decimals_percentages", title:"Decimals & percentages", subtitle:"Compare and use decimals and percents", icon:"percent", color:Color(red:0.84,green:0.42,blue:0.34), grades:4...12, strand:"Fractions, decimals & percents"),
        .init(id:"probability", title:"Probability", subtitle:"Describe likelihood and possible outcomes", icon:"dice.fill", color:Color(red:0.48,green:0.58,blue:0.86), grades:3...12, strand:"Data — probability"),
        .init(id:"data_visualization", title:"Data displays", subtitle:"Read graphs and communicate data", icon:"chart.xyaxis.line", color:Color(red:0.24,green:0.61,blue:0.84), grades:3...12, strand:"Data — visualization"),
        .init(id:"coding_algorithms", title:"Coding & algorithms", subtitle:"Trace code and follow algorithms", icon:"chevron.left.forwardslash.chevron.right", color:Color(red:0.55,green:0.45,blue:0.82), grades:4...12, strand:"Algebra — coding"),
        .init(id:"mathematical_modelling", title:"Mathematical modelling", subtitle:"Use math to represent real situations", icon:"cube.transparent", color:Color(red:0.28,green:0.62,blue:0.60), grades:4...12, strand:"Algebra — modelling"),
        .init(id:"mental_math_place_value", title:"Mental math & place value", subtitle:"Use place value and mental strategies", icon:"number.square", color:Color(red:0.91,green:0.57,blue:0.29), grades:1...8, strand:"Number — place value"),
        .init(id:"triangles_transformations", title:"Triangles & transformations", subtitle:"Classify triangles and move shapes on grids", icon:"triangle", color:Color(red:0.34,green:0.68,blue:0.55), grades:3...12, strand:"Geometry — triangles & transformations"),
        .init(id:"budgeting_credit", title:"Budgeting & credit", subtitle:"Plan budgets and understand borrowing", icon:"creditcard.fill", color:Color(red:0.25,green:0.62,blue:0.43), grades:5...12, strand:"Financial literacy — budgeting & credit")
    ]
}
