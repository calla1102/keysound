import XCTest
@testable import KeyboardCore

final class ShiftStateTests: XCTestCase {
    func testSingleTapIsOnceAndConsumedByCharacter() {
        var s = ShiftState()
        s.tap(at: 0, allowsCaps: true)
        XCTAssertEqual(s.mode, .once)
        s.didInputCharacter()
        XCTAssertEqual(s.mode, .off)
    }

    func testQuickDoubleTapIsCaps() {
        var s = ShiftState()
        s.tap(at: 0, allowsCaps: true)
        s.tap(at: 0.2, allowsCaps: true)
        XCTAssertEqual(s.mode, .caps)
    }

    func testCapsSurvivesCharactersAndTapReleases() {
        var s = ShiftState()
        s.tap(at: 0, allowsCaps: true)
        s.tap(at: 0.1, allowsCaps: true)
        s.didInputCharacter()
        s.didInputCharacter()
        XCTAssertEqual(s.mode, .caps)
        s.tap(at: 5, allowsCaps: true)
        XCTAssertEqual(s.mode, .off)
    }

    func testSlowSecondTapTurnsOff() {
        var s = ShiftState()
        s.tap(at: 0, allowsCaps: true)
        s.tap(at: 1.0, allowsCaps: true)
        XCTAssertEqual(s.mode, .off)
    }

    func testTapAfterCapsReleaseStartsOverAsOnce() {
        var s = ShiftState()
        s.tap(at: 0, allowsCaps: true)
        s.tap(at: 0.1, allowsCaps: true)
        s.tap(at: 0.2, allowsCaps: true)
        XCTAssertEqual(s.mode, .off)
        s.tap(at: 0.3, allowsCaps: true)
        XCTAssertEqual(s.mode, .once)
    }

    func testNoCapsWhenNotAllowed() {
        var s = ShiftState()
        s.tap(at: 0, allowsCaps: false)
        s.tap(at: 0.1, allowsCaps: false)
        XCTAssertEqual(s.mode, .off)
    }

    func testClearOnceKeepsCaps() {
        var s = ShiftState()
        s.tap(at: 0, allowsCaps: true)
        s.clearOnce()
        XCTAssertEqual(s.mode, .off)
        s.tap(at: 1, allowsCaps: true)
        s.tap(at: 1.1, allowsCaps: true)
        s.clearOnce()
        XCTAssertEqual(s.mode, .caps)
        s.reset()
        XCTAssertEqual(s.mode, .off)
    }
}
