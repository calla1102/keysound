import XCTest
@testable import KeyboardCore

final class CursorDragTrackerTests: XCTestCase {
    private func tracker() -> CursorDragTracker {
        var t = CursorDragTracker(step: 10)
        t.begin(at: 100)
        return t
    }

    func testBelowStepMovesNothing() {
        var t = tracker()
        XCTAssertEqual(t.move(to: 109.9), 0)
        XCTAssertEqual(t.move(to: 90.1), 0)
    }

    func testRightAndLeftSteps() {
        var t = tracker()
        XCTAssertEqual(t.move(to: 110), 1)
        XCTAssertEqual(t.move(to: 135), 2)  // 누적 3칸, 이미 1칸 옮김
        XCTAssertEqual(t.move(to: 80), -5)  // 누적 -2칸
    }

    func testRemainderAccumulatesAcrossSmallMoves() {
        var t = tracker()
        var total = 0
        for x in stride(from: 103.0, through: 130.0, by: 3.0) { total += t.move(to: CGFloat(x)) }
        XCTAssertEqual(total, 3)
    }

    func testReturningToAnchorNetsZero() {
        var t = tracker()
        var total = t.move(to: 160)
        total += t.move(to: 100)
        XCTAssertEqual(total, 0)
    }

    func testBeginResets() {
        var t = tracker()
        _ = t.move(to: 150)
        t.begin(at: 150)
        XCTAssertEqual(t.move(to: 150), 0)
        XCTAssertEqual(t.move(to: 140), -1)
    }
}
