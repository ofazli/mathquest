# Math Quest — Canada Edition

A native macOS SwiftUI starter game for elementary math. It is designed around short, low-pressure challenges, playful stories, optional hints, XP, and a topic map.

## Run

Requires macOS 14 or later. Run Math Quest as a macOS app so Launch Services can see its bundle identifier (`com.mathquest.canada`):

1. Open `MathQuest.xcodeproj` in Xcode.
2. Select the `MathQuest` scheme and press **Run**.

Avoid `swift run` for launching the GUI. Swift Package Manager starts the executable directly, outside its `.app` bundle; macOS can then print missing bundle identifier and app-service connection warnings. The Xcode target already sets the bundle identifier.

## What's here

- Home dashboard with a Grades 1–12 selector, mini-adventure, and learning modules.
- Randomized challenges across number, fractions, decimals, algebra, geometry, measurement, data, probability, coding, modelling, and financial literacy.
- Progress charts, saved XP, characters, timed potions, hints, and parent-facing curriculum notes.
- No account, network access, advertising, or in-app purchases.

## Curriculum note

Canada's provinces and territories set their own detailed curriculum expectations. This starter offers sample challenge generators for Grades 1–12; it is not a complete province-aligned curriculum. A production curriculum needs a selected province or territory and reviewed learning outcomes for each grade.
