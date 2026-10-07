import XCTest

/// Launches the app on the fixed demo evening and attaches a named screenshot per mockup screen.
class PiPlannerUITestCase: XCTestCase {
    enum Stage: String {
        case welcome, afterOpening, openCredit, afterCustomCredit, afterTransfer
    }

    private(set) var app: XCUIApplication!
    static let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func launch(at stage: Stage = .welcome) {
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-demo-stage", stage.rawValue]
        app.launch()
    }

    @MainActor
    func snap(_ screen: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = screen
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Queries

    @MainActor
    func tap(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        // Rows with a subtitle merge into one label, e.g. "Manually, Type the amount yourself".
        let predicate = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", label, "\(label), ")
        let button = app.buttons.matching(predicate).firstMatch
        require(button, "Missing button “\(label)”", file: file, line: line)
        button.tap()
    }

    /// Fails with a screenshot of what was on screen instead.
    @MainActor
    func require(_ element: XCUIElement, _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        guard !element.waitForExistence(timeout: Self.timeout) else { return }
        snap("99 Failure · \(message)")
        XCTFail(message, file: file, line: line)
    }

    @MainActor
    func tapTab(_ title: String) {
        app.buttons["tab.\(title.lowercased())"].tap()
    }

    @MainActor
    func expectText(_ text: String, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let element = app.descendants(matching: .any).matching(predicate).firstMatch
        require(element, "Missing text “\(text)”", file: file, line: line)
    }

    @MainActor
    func type(_ text: String, into field: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        require(field, "Missing field \(field)", file: file, line: line)
        // Tap the trailing edge so the caret lands after any existing text.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        if let current = field.value as? String, !current.isEmpty, current != field.placeholderValue {
            // Twice the length: regrouping while deleting ("60,000" → "6,000") shifts the caret.
            for _ in 0..<(current.count * 2) {
                field.typeText(XCUIKeyboardKey.delete.rawValue)
            }
        }
        // One key at a time: the fields regroup digits as you type and can drop a burst of keys.
        for character in text {
            field.typeText(String(character))
        }
    }

    @MainActor
    func amountField(_ label: String = "Amount in rupees") -> XCUIElement {
        app.textFields[label].firstMatch
    }

    @MainActor
    func percentField(_ goal: String) -> XCUIElement {
        app.textFields["\(goal) share"].firstMatch
    }

    @MainActor
    func enterPIN(_ digits: String) {
        for digit in digits {
            app.buttons[String(digit)].firstMatch.tap()
        }
    }

    @MainActor
    func sendToGrok(_ text: String) {
        let composer = app.descendants(matching: .any).matching(identifier: "composer").firstMatch
        require(composer, "Missing composer")
        composer.tap()
        // The simulator's one-time "slide to type" tip covers the keyboard.
        app.buttons["Continue"].firstMatch.tapIfPresent()
        composer.typeText(text)
        tap("Send")
    }

    @MainActor
    func dismissKeyboard() {
        if app.keyboards.count > 0 {
            app.toolbars.buttons["Done"].firstMatch.tapIfPresent()
            if app.keyboards.count > 0 { app.swipeDown() }
        }
    }
}

extension XCUIElement {
    func tapIfPresent() {
        if exists && isHittable { tap() }
    }
}
