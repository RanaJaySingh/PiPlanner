import XCTest

/// J3 / J4 · Goal detail, edits for the next credit, the standing split, transfer and delete.
final class GoalsJourneyUITests: PiPlannerUITestCase {
    @MainActor
    func testGoalDetailAndEditForNextCredit() {
        launch(at: .afterCustomCredit)
        tap("Car")

        expectText("Saved so far")
        expectText("₹85,000")
        expectText("From History")
        snap("14 Goal detail")
        app.buttons.matching(identifier: "Edit goal").element(boundBy: 0).tap()

        expectText("Changes apply at the next credit. Earlier history stays as it is.")
        expectText("₹85,000 · locked")
        type("1200000", into: amountField("Target"))
        dismissKeyboard()
        snap("06e Edit goal")
        tap("Save")

        expectText("Saved so far")
        snap("14a Goal detail with pending edit")
    }

    @MainActor
    func testNewGoalReopensStandingSplit() {
        launch(at: .afterCustomCredit)
        tap("New goal")
        type("Bike", into: app.textFields["Goal name"].firstMatch)
        type("100000", into: amountField("Target"))
        dismissKeyboard()
        snap("06 New standalone goal")
        tap("Save")

        expectText("Used for the next credit. Saved money stays where it is.")
        type("40", into: percentField("Car"))
        type("25", into: percentField("Emergency"))
        type("15", into: percentField("Vacation"))
        type("20", into: percentField("Bike"))
        dismissKeyboard()
        expectText("Total 100%")
        snap("15 Standing split")
        tap("Save")

        expectText("Bike")
        expectText("40% of credits")
        snap("09 Goals with Bike")
    }

    @MainActor
    func testTransferRejectsTooMuchThenMoves() {
        launch(at: .afterCustomCredit)
        tap("Transfer")

        expectText("From · Emergency")
        expectText("To · Car")
        type("60000", into: amountField())
        dismissKeyboard()
        expectText("Emergency has only ₹55,000 saved.")
        snap("16b Transfer too much")
        XCTAssertFalse(app.buttons["Move ₹60,000"].firstMatch.isEnabled)

        type("5000", into: amountField())
        dismissKeyboard()
        expectText("After transfer")
        snap("16 Transfer")
        tap("Move ₹5,000")

        expectText("History")
        expectText("₹5,000")
        snap("16a History after transfer")
    }

    @MainActor
    func testDeleteGoalMovesItsSaving() {
        launch(at: .afterTransfer)
        tap("Vacation")
        tap("Delete goal")

        expectText("This releases ₹10,000.")
        expectText("Split equally. Change it once.")
        snap("17 Delete goal")
        type("60", into: percentField("Car"))
        type("40", into: percentField("Emergency"))
        dismissKeyboard()
        expectText("₹6,000")
        snap("17a Delete with custom split")
        tap("Delete and move ₹10,000")

        expectText("History")
        snap("17b History after delete")
        tapTab("Goals")
        expectText("Your Goals")
        snap("09 Goals after delete")
        let vacation = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Vacation'")).firstMatch
        XCTAssertFalse(vacation.exists, vacation.exists ? vacation.label : "")
    }
}
