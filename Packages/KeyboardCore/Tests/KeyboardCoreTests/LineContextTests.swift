import XCTest
@testable import KeyboardCore

final class LineContextTests: XCTestCase {
    private func ctx(_ before: String, _ after: String) -> LineContext { LineContext(before: before, after: after) }

    func testUpSameColumn() {
        // "abcd\nefgh\nij|kl" 현재 열 2 → 가운데 줄 열 2
        let m = ctx("abcd\nefgh\nij", "kl").verticalMove(.up, goalColumn: nil)
        XCTAssertEqual(m?.offset, -(2 + 1 + 4 - 2))
        XCTAssertEqual(m?.goalColumn, 2)
    }

    func testUpShorterLineGoesToEnd() {
        let m = ctx("ab\ncdefg", "").verticalMove(.up, goalColumn: nil)
        XCTAssertEqual(m?.offset, -(5 + 1))  // 이전 줄 끝
        XCTAssertEqual(m?.goalColumn, 5)
    }

    func testUpIntoEmptyLine() {
        XCTAssertEqual(ctx("\nxy", "").verticalMove(.up, goalColumn: nil)?.offset, -3)
    }

    func testDownSameColumn() {
        // "ab|cd\nefgh\nij" 열 2 → 다음 줄 열 2
        let m = ctx("ab", "cd\nefgh\nij").verticalMove(.down, goalColumn: nil)
        XCTAssertEqual(m?.offset, 2 + 1 + 2)
    }

    func testDownShorterLineGoesToEnd() {
        XCTAssertEqual(ctx("abcd", "\nef").verticalMove(.down, goalColumn: nil)?.offset, 1 + 2)
    }

    func testDownLastLineOfContextNoBreak() {
        XCTAssertNil(ctx("ab\ncd", "ef").verticalMove(.down, goalColumn: nil))
    }

    func testNoBreakBeforeMeansNoUp() {
        XCTAssertNil(ctx("abc", "d\nef").verticalMove(.up, goalColumn: nil))
        XCTAssertNil(ctx("", "").verticalMove(.up, goalColumn: nil))
    }

    func testGoalColumnRestoredAfterShortLine() {
        var c = ctx("abcdef\nx\nabcd", "ef")  // 열 4, 가운데 줄 길이 1
        var m = c.verticalMove(.up, goalColumn: nil)!
        XCTAssertEqual(m.offset, -(4 + 1 + 1 - 1))
        c.shift(by: m.offset)
        XCTAssertEqual(c.before, "abcdef\nx")
        m = c.verticalMove(.up, goalColumn: m.goalColumn)!
        XCTAssertEqual(m.offset, -(1 + 1 + 6 - 4))  // 원래 열 4 로 복귀
        c.shift(by: m.offset)
        XCTAssertEqual(c.before, "abcd")
    }

    func testCRLFCountsAsOneCharacter() {
        XCTAssertEqual(ctx("ab\r\ncd", "").verticalMove(.up, goalColumn: nil)?.offset, -(2 + 1))
    }

    func testShiftRoundTripAndClamp() {
        var c = ctx("ab", "cd")
        c.shift(by: 1)
        XCTAssertEqual(c, ctx("abc", "d"))
        c.shift(by: -10)
        XCTAssertEqual(c, ctx("", "abcd"))
        c.shift(by: 10)
        XCTAssertEqual(c, ctx("abcd", ""))
    }
}
