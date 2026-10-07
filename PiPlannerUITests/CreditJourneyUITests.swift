import XCTest

/// J2 · The demo heart: Sync finds ₹50,000, the entry takes one custom split with a new goal, then locks.
final class CreditJourneyUITests: PiPlannerUITestCase {
    @MainActor
    func testSyncCustomSplitWithNewGoal() {
        launch(at: .afterOpening)
        expectText("Your Goals")
        tap("Sync")

        expectText("Fetched balance")
        expectText("₹1,50,000")
        snap("10 Sync")
        tap("Continue")

        expectText("New credit")
        expectText("60% · ₹30,000")
        snap("13 Entry open")
        tap("Update percentages for this amount")

        expectText("Use this split from the next credit too")
        snap("13b Edit split")
        tap("+ Create a goal")

        expectText("New goal")
        type("Vacation", into: app.textFields["Goal name"].firstMatch)
        type("50000", into: amountField("Target"))
        dismissKeyboard()
        tap("Sep 2027")
        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "Mar")
        tap("Done")
        expectText("Mar 2027")
        snap("06c Goal on entry")
        tap("Save")

        expectText("Vacation")
        type("50", into: percentField("Car"))
        type("30", into: percentField("Emergency"))
        type("20", into: percentField("Vacation"))
        dismissKeyboard()
        expectText("Total 100%")
        expectText("₹25,000")
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "behind this month")).firstMatch.exists)
        snap("13c Custom split")
        tap("Save and lock")

        expectText("Saved and locked · Custom split")
        snap("13d Saved custom split")
        tap("Back")

        expectText("50% of credits")
        expectText("20% of credits")
        snap("09c Goals after credit")
    }

    @MainActor
    func testOpenEntryBannerAndSuggestedSplit() {
        launch(at: .openCredit)
        expectText("₹50,000 to assign")
        snap("09b Goals with open entry")
        XCTAssertFalse(app.buttons["Sync"].firstMatch.isEnabled, "Sync waits until the open entry is saved")
        tap("Assign now")

        expectText("You can change this split once.")
        tap("Save and lock")
        expectText("Saved and locked")
        snap("13a Saved suggested split")
        tap("Back")
        expectText("Your Goals")
        XCTAssertTrue(app.buttons["Sync"].firstMatch.isEnabled)
    }
}
