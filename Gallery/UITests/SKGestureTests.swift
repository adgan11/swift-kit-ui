//
//  SKGestureTests.swift
//  Swift Kit UI Gallery — UI tests
//
//  Gesture-driven components cannot be verified by compiling, by linting, or by
//  a screenshot. Pull-to-refresh shipped broken twice precisely because all
//  three of those passed. These drive the real thing on a real simulator.
//

import XCTest

final class SKGestureTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func launch(component: String, variant: String = "default") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--component", component, "--variant", variant]
        app.launch()
        return app
    }

    /// Swiping down past the threshold must actually run the refresh closure.
    /// The demo renumbers its rows by +14, so "Item 15" appearing is proof the
    /// action ran — not merely that an indicator was drawn.
    func testPullToRefreshRunsTheAction() {
        let app = launch(component: "sk-pull-to-refresh")

        let open = app.buttons["Open full-screen demo"]
        XCTAssertTrue(open.waitForExistence(timeout: 5), "launcher never appeared")
        open.tap()

        XCTAssertTrue(app.staticTexts["Item 1"].waitForExistence(timeout: 5),
                      "demo content never appeared")
        XCTAssertFalse(app.staticTexts["Item 15"].exists,
                       "list started already refreshed — test proves nothing")

        // A slow, long drag: a fast flick is treated as a scroll, not a pull.
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.30))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.88))
        start.press(forDuration: 0.25, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.4)

        XCTAssertTrue(app.staticTexts["Item 15"].waitForExistence(timeout: 8),
                      "pull-to-refresh did not run its action")
    }

    /// The sheet must present, and dragging it down must dismiss it.
    func testBottomSheetPresentsAndDragDismisses() {
        let app = launch(component: "sk-bottom-sheet", variant: "medium")

        let open = app.buttons["Open full-screen demo"]
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()

        let present = app.buttons["Open medium sheet"]
        XCTAssertTrue(present.waitForExistence(timeout: 5))
        present.tap()

        let sheetTitle = app.staticTexts["Share"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 3), "sheet never presented")

        // Drag the sheet down from its own surface.
        let from = sheetTitle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
        let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.05))
        from.press(forDuration: 0.1, thenDragTo: to, withVelocity: .default, thenHoldForDuration: 0)

        // Polled rather than NSPredicate + waitForExpectations: the latter
        // captures `self`, which Swift 6 rejects as a non-Sendable send.
        let deadline = Date().addingTimeInterval(5)
        while sheetTitle.exists && Date() < deadline {
            usleep(120_000)
        }
        XCTAssertFalse(sheetTitle.exists, "sheet did not dismiss on drag-down")
    }
}
