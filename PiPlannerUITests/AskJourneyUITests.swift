import XCTest

/// J8 · Ask: answers, a goal for the open entry, a transfer, a follow-up, and a refused payment.
final class AskJourneyUITests: PiPlannerUITestCase {
    @MainActor
    func testAnswerThenGoalForOpenEntry() {
        launch(at: .openCredit)
        tapTab("Ask")
        expectText("Ask about your plan")
        snap("19 Ask")

        tap("How are my goals doing?")
        expectText("Car has ₹60,000 of ₹10,00,000")
        snap("19a Grok answer")

        sendToGrok("Add a ₹50,000 vacation by March")
        expectText("Vacation")
        snap("13f Grok entry goal")
        tap("Confirm")

        expectText("New credit")
        expectText("Vacation")
        expectText("Total 100%")
        snap("13g Entry with Grok split")
    }

    @MainActor
    func testTransferFollowUpAndRefusal() {
        launch(at: .afterCustomCredit)
        tapTab("Ask")

        sendToGrok("Move 5k from Emergency to Car")
        expectText("Emergency")
        snap("19b Grok transfer")
        tap("Confirm")
        expectText("After transfer")
        expectText("Move ₹5,000")
        snap("16c Transfer from Grok")
        tap("Back")

        sendToGrok("Add a trip")
        expectText("How much is the trip, and by when?")
        snap("19d Grok follow-up")

        sendToGrok("Send ₹5,000 to Ravi")
        expectText("It never moves money.")
        snap("19e Grok refuses a payment")
    }
}
