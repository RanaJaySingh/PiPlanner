import XCTest

/// The three-minute demo from docs/HACKATHON.md, step by step, in one run per consent answer.
final class DemoRehearsalUITests: PiPlannerUITestCase {
    @MainActor
    func testDemoConsentYes() {
        launch()

        // 1. Accounts and consent.
        tap("Set up savings")
        tap("Continue")
        tap("Yes, update automatically")
        tap("Continue")

        // 2. Goals by conversation: one sentence, 60/40, lock.
        tap("A ₹10 lakh car by Sep 2030 and a ₹2 lakh emergency fund in a year")
        tap("Confirm")
        tap("Continue")
        tap("Lock this split")
        expectText("60% of credits")
        snap("demo 1 Goals after setup")

        // 3. Sync, then the Goa trip at 20% from Ask, then Save at ₹25,000 / ₹15,000 / ₹10,000.
        tap("Sync")
        expectText("+₹50,000")
        tap("Continue")
        expectText("60% · ₹30,000")
        expectText("40% · ₹20,000")
        tap("Back")
        tapTab("Ask")
        sendToGrok("Put 20% of this into a ₹50,000 Goa trip by March")
        tap("Confirm")
        expectText("Goa trip")
        expectText("₹25,000")
        expectText("₹15,000")
        expectText("₹10,000")
        snap("demo 2 Entry with Goa trip")
        tap("Save and lock")
        expectText("Saved and locked · Custom split")
        tap("Back")

        // 4. Proof: the opening entry still reads 60/40.
        tapTab("History")
        tap("Opening balance")
        expectText("60% of ₹1,00,000")
        expectText("40% of ₹1,00,000")
        snap("demo 3 Opening entry unchanged")
        tap("Back")

        // 5. Manage: edit Car's end date, transfer ₹5,000, delete the Goa trip at 60/40.
        tapTab("Goals")
        tap("Car")
        app.buttons.matching(identifier: "Edit goal").element(boundBy: 0).tap()
        tap("Sep 2030")
        app.pickerWheels.element(boundBy: 1).adjust(toPickerWheelValue: "2031")
        tap("Done")
        tap("Save")
        expectText("Change saved. Applies at the next credit.")
        snap("demo 4 Car edit pending")
        tap("Back")

        tap("Transfer")
        type("5000", into: amountField())
        dismissKeyboard()
        tap("Move ₹5,000")
        expectText("Emergency → Car · ₹5,000")
        tapTab("Goals")

        tap("Goa trip")
        tap("Delete goal")
        expectText("Split equally. Change it once.")
        type("60", into: percentField("Car"))
        type("40", into: percentField("Emergency"))
        dismissKeyboard()
        tap("Delete and move ₹10,000")
        expectText("Goa trip deleted")
        snap("demo 5 History after manage")
    }

    @MainActor
    func testDemoConsentNo() {
        launch()

        // 6. Consent No: Balance sync with the UPI PIN, then later a typed ₹50,000.
        tap("Set up savings")
        tap("Continue")
        tap("No, I'll update it myself")
        tap("Balance sync")
        enterPIN("123456")
        app.buttons.matching(identifier: "Check balance").element(boundBy: 0).tap()
        expectText("₹1,00,000")
        tap("Continue")

        tap("A ₹10 lakh car by Sep 2030 and a ₹2 lakh emergency fund in a year")
        tap("Confirm")
        tap("Continue")
        tap("Lock this split")

        tap("Update balance")
        tap("Manually")
        type("50000", into: amountField())
        tap("Continue")
        expectText("Typed")
        expectText("60% · ₹30,000")
        tap("Save and lock")
        tap("Back")

        tapTab("History")
        expectText("New credit")
        snap("demo 6 History consent No")
    }
}
