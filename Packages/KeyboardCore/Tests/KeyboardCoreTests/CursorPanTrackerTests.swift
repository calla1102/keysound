import XCTest
@testable import KeyboardCore

final class CursorPanTrackerTests: XCTestCase {
    private func tracker() -> CursorPanTracker {
        var t = CursorPanTracker(step: 10, lineStep: 40)
        t.begin(at: CGPoint(x: 100, y: 100))
        return t
    }

    func testVerticalLines() {
        var t = tracker()
        XCTAssertEqual(t.move(to: CGPoint(x: 100, y: 139)), .init(columns: 0, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 100, y: 140)), .init(columns: 0, lines: 1))
        XCTAssertEqual(t.move(to: CGPoint(x: 100, y: 60)), .init(columns: 0, lines: -2))
    }

    func testHorizontalStillWorks() {
        var t = tracker()
        XCTAssertEqual(t.move(to: CGPoint(x: 125, y: 102)), .init(columns: 2, lines: 0))
    }

    func testSmallSidewaysDriftDuringVerticalDragIgnored() {
        var t = tracker()
        // 위로 끌며 x 가 8pt 새어도 가로 이동 없음, 세로 40pt 에서 한 줄
        XCTAssertEqual(t.move(to: CGPoint(x: 108, y: 70)), .init(columns: 0, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 108, y: 60)), .init(columns: 0, lines: -1))
    }

    func testDiagonalPicksDominantAxisOnly() {
        var t = tracker()
        // 한 번에 가로 3칸(30pt)·세로 1줄(40pt) → 세로가 더 멀리 → 세로만
        XCTAssertEqual(t.move(to: CGPoint(x: 130, y: 140)), .init(columns: 0, lines: 1))
        // 가로 5칸(50pt)·세로 1줄(40pt) → 가로만
        var u = tracker()
        XCTAssertEqual(u.move(to: CGPoint(x: 150, y: 140)), .init(columns: 5, lines: 0))
    }
}
