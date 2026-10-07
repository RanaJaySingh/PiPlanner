import XCTest

/// J1 · Setup: accounts, the consent tree, goal chat and the opening split.
final class SetupJourneyUITests: PiPlannerUITestCase {
    @MainActor
    func testSetupWithAutomaticUpdatesAndGrokChat() {
        launch()
        expectText("How it works")
        snap("01 Welcome")
        tap("Set up savings")

        expectText("Your accounts")
        snap("02 Accounts")
        tap("Continue")

        expectText("Allow PiPlanner to check this balance?")
        snap("03 Consent")
        tap("Yes, update automatically")

        expectText("₹1,00,000")
        snap("03a Balance read")
        tap("Continue")

        expectText("What are you planning for?")
        snap("05 Goal chat")
        tap("A ₹10 lakh car by Sep 2030 and a ₹2 lakh emergency fund in a year")
        XCTAssertTrue(app.buttons["Confirm"].waitForExistence(timeout: Self.timeout))
        snap("05a Grok proposal")
        tap("Confirm")

        expectText("Your goals")
        snap("05b Goals confirmed")
        tap("Continue")

        expectText("Opening split")
        snap("08 Opening split")
        tap("Lock this split")

        expectText("Your Goals")
        expectText("₹60,000 of")
        snap("09 Goals")
    }

    @MainActor
    func testSetupManualWithFormFallback() {
        launch()
        tap("Set up savings")
        tap("Continue")
        tap("No, I'll update it myself")

        expectText("Update balance")
        snap("04 Update balance")
        tap("Manually")

        expectText("Opening balance")
        type("100000", into: amountField())
        snap("04a Manual opening")
        tap("Continue")

        tap("Use a form")
        expectText("Goal name")
        type("Car", into: app.textFields["Goal name"].firstMatch)
        type("1000000", into: amountField("Target"))
        dismissKeyboard()
        snap("06 Goal form")
        tap("Save")

        expectText("This is your only goal, so it gets 100%.")
        snap("05c Single goal")
        tap("Continue")
        expectText("Opening split")
        tap("Lock this split")
        expectText("Your Goals")
        expectText("Update balance")
        snap("11 Goals manual")
    }

    @MainActor
    func testWrongPINFallsBackToManual() {
        launch()
        tap("Set up savings")
        tap("Continue")
        tap("No, I'll update it myself")
        tap("Balance sync")

        expectText("Check balance")
        enterPIN("000000")
        snap("04b PIN")
        app.buttons.matching(identifier: "Check balance").element(boundBy: 0).tap()

        expectText("Incorrect PIN")
        snap("04d Incorrect PIN")
        tap("Cancel")

        expectText("Incorrect PIN. Try again or enter it manually.")
        snap("04e Update balance after wrong PIN")
        tap("Manually")
        expectText("How much is in this account?")
    }
}
