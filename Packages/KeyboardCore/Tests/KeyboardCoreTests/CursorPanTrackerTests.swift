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

extension CursorPanTrackerTests {
    func testSidewaysDriftOverOneCellDuringVerticalDrag() {
        var t = tracker()
        // 엄지 호를 그리며 위로 끌 때 x 가 12pt 새도 세로 40pt 에서 한 줄 올라가야 한다
        XCTAssertEqual(t.move(to: CGPoint(x: 106, y: 85)), .init(columns: 0, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 112, y: 70)), .init(columns: 0, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 112, y: 60)), .init(columns: 0, lines: -1))
    }
}

extension CursorPanTrackerTests {
    func testVerticalAfterLongHorizontalDrag() {
        var t = tracker()
        // 오른쪽으로 길게 옮긴 뒤 위로 끌어도 세로가 먹혀야 한다(가로 변위가 기준점에 남아 세로를 막지 않음)
        XCTAssertEqual(t.move(to: CGPoint(x: 200, y: 100)), .init(columns: 10, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 203, y: 60)), .init(columns: 0, lines: -1))
    }

    func testHorizontalRemainderKeptAndReversible() {
        var t = tracker()
        // 15pt → 1칸, 남은 5pt 는 쌓였다가 다음 5pt 에서 1칸, 되돌아오면 같은 칸 수만큼 돌아감
        XCTAssertEqual(t.move(to: CGPoint(x: 115, y: 101)), .init(columns: 1, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 120, y: 101)), .init(columns: 1, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 100, y: 101)), .init(columns: -2, lines: 0))
    }

    func testDefaultLineStepFitsDownwardRoom() {
        var t = CursorPanTracker()
        t.begin(at: CGPoint(x: 100, y: 100))
        XCTAssertEqual(t.move(to: CGPoint(x: 100, y: 130)), .init(columns: 0, lines: 1))
    }
}

extension CursorPanTrackerTests {
    func testTieGoesHorizontal() {
        var t = tracker()
        XCTAssertEqual(t.move(to: CGPoint(x: 140, y: 140)), .init(columns: 4, lines: 0))
    }

    func testNegativeDirectionsKeepRemainder() {
        var t = tracker()
        XCTAssertEqual(t.move(to: CGPoint(x: 85, y: 100)), .init(columns: -1, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 80, y: 100)), .init(columns: -1, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 80, y: 20)), .init(columns: 0, lines: -2))
    }

    func testHorizontalMoveResetsVerticalProgress() {
        var t = tracker()
        // 세로 30pt 를 쌓다가 가로가 우세해져 한 칸 나가면 세로는 그 위치에서 다시 센다
        XCTAssertEqual(t.move(to: CGPoint(x: 100, y: 130)), .init(columns: 0, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 140, y: 130)), .init(columns: 4, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 140, y: 150)), .init(columns: 0, lines: 0))
        XCTAssertEqual(t.move(to: CGPoint(x: 140, y: 170)), .init(columns: 0, lines: 1))
    }
}
