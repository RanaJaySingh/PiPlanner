import XCTest

/// J5 / J6 / J7 · Withdrawal, History, the consent switch, typed amounts, and Reset demo.
final class EdgeJourneyUITests: PiPlannerUITestCase {
    @MainActor
    func testWithdrawalFoundBySync() {
        launch(at: .afterTransfer)
        openSettings()
        chooseNextBalanceRead("−₹8,000")
        tap("Back")

        tap("Sync")
        expectText("Went down by")
        expectText("Your savings balance went down by ₹8,000.")
        snap("10b Sync found a withdrawal")
        tap("Continue")

        expectText("Choose which goals it comes from.")
        expectText("Total 100%")
        snap("18 Withdrawal")
        tap("Save and lock")

        expectText("History")
        expectText("Withdrawal")
        snap("18b History after withdrawal")
    }

    @MainActor
    func testConsentOffTypedCreditThenConsentOn() {
        launch(at: .afterOpening)
        openSettings()
        app.switches["Automatic balance updates"].firstMatch.tap()
        expectText("Off. You update the balance yourself with Update balance.")
        snap("20 Settings consent off")
        tap("Back")

        expectText("Update balance")
        snap("20a Goals manual")
        tap("Update balance")
        expectText("Type the amount yourself")
        snap("11a Update balance")
        tap("Manually")

        expectText("How much did you add?")
        type("20000", into: amountField())
        snap("11b Typed credit")
        tap("Continue")

        expectText("Typed")
        expectText("₹20,000")
        snap("13t Typed entry")
        tap("Save and lock")
        expectText("Saved and locked")
        tap("Back")

        openSettings()
        app.switches["Automatic balance updates"].firstMatch.tap()
        expectText("Allow PiPlanner to check this balance?")
        snap("20b Consent from Settings")
        tap("Yes, update automatically")
        expectText("On. PiPlanner reads this balance when you tap Sync.")
        tap("Back")

        tap("Sync")
        expectText("Fetched balance")
        snap("20c Sync after consent on")
    }

    @MainActor
    func testNotLinkedInPaytmFallsBackToManual() {
        launch(at: .afterOpening)
        openSettings()
        app.switches["Automatic balance updates"].firstMatch.tap()
        app.switches["Savings account linked in Paytm"].firstMatch.tap()
        tap("Back")

        tap("Update balance")
        tap("Balance sync")
        expectText("This account is not linked in Paytm")
        snap("11c Not linked in Paytm")
        expectText("How much did you add?")
    }

    @MainActor
    func testHistoryListAndOpeningEntry() {
        launch(at: .afterTransfer)
        tapTab("History")
        expectText("Opening balance")
        expectText("Transfer")
        snap("12 History")
        tap("Opening balance")

        expectText("Original amounts never change.")
        snap("12a Opening entry")
    }

    @MainActor
    func testResetDemoReturnsToWelcome() {
        launch(at: .afterTransfer)
        openSettings()
        app.swipeUp()
        tap("Reset demo")
        let confirm = app.sheets.buttons["Reset demo"].exists
            ? app.sheets.buttons["Reset demo"]
            : app.buttons.matching(identifier: "Reset demo").element(boundBy: 1)
        confirm.tap()

        expectText("How it works")
        snap("20d After reset")
    }

    // MARK: - Helpers

    @MainActor
    private func openSettings() {
        tap("Settings")
        expectText("Linked accounts")
    }

    @MainActor
    private func chooseNextBalanceRead(_ label: String) {
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Demo script'")).firstMatch.tap()
        tap(label)
        expectText(label)
    }
}
