import XCTest
@testable import KeyboardCore

final class WordDeletionTests: XCTestCase {
    func testEmpty() { XCTAssertEqual(WordDeletion.count(before: ""), 0) }
    func testSingleWord() { XCTAssertEqual(WordDeletion.count(before: "hello"), 5) }
    func testLastWordOnly() { XCTAssertEqual(WordDeletion.count(before: "안녕 하세요"), 3) }
    func testTrailingSpacesIncluded() { XCTAssertEqual(WordDeletion.count(before: "안녕 하세요  "), 5) }
    func testTrailingSpacesThenWord() { XCTAssertEqual(WordDeletion.count(before: "ab   "), 5) }
    func testNewlineIsBoundary() { XCTAssertEqual(WordDeletion.count(before: "abc\ndef"), 3) }
    func testTrailingNewlineOnly() { XCTAssertEqual(WordDeletion.count(before: "abc\n"), 1) }
    func testSpacesThenNewlineStopsAtNewline() { XCTAssertEqual(WordDeletion.count(before: "abc\n  "), 2) }
    func testPunctuationAttachedToWord() { XCTAssertEqual(WordDeletion.count(before: "a, b.c!"), 4) }
    func testEmojiCountsAsOneCharacter() { XCTAssertEqual(WordDeletion.count(before: "hi 👍🏽😀"), 2) }

    // 경계 문자
    func testTabIsTrailingWhitespace() { XCTAssertEqual(WordDeletion.count(before: "ab\t\t"), 4) }
    func testTabSeparatesWords() { XCTAssertEqual(WordDeletion.count(before: "ab\tcd"), 2) }
    func testCRLFIsSingleNewline() { XCTAssertEqual(WordDeletion.count(before: "abc\r\n"), 1) }
    func testSpacesThenCRLFStopsAtNewline() { XCTAssertEqual(WordDeletion.count(before: "abc\r\n  "), 2) }
    func testConsecutiveNewlinesDeleteOneAtATime() { XCTAssertEqual(WordDeletion.count(before: "a\n\n"), 1) }
    func testNBSPIsWhitespace() { XCTAssertEqual(WordDeletion.count(before: "ab\u{00A0}"), 3) }
    func testNBSPSeparatesWords() { XCTAssertEqual(WordDeletion.count(before: "ab\u{00A0}cd"), 2) }
    func testIdeographicSpaceIsWhitespace() { XCTAssertEqual(WordDeletion.count(before: "ab\u{3000}"), 3) }
    func testIdeographicSpaceSeparatesWords() { XCTAssertEqual(WordDeletion.count(before: "ab\u{3000}cd"), 2) }
    func testLineSeparatorIsNewline() { XCTAssertEqual(WordDeletion.count(before: "ab\u{2028}"), 1) }
    func testTrailingZeroWidthSpaceDeletedWithWord() { XCTAssertEqual(WordDeletion.count(before: "ab\u{200B}"), 3) }
    func testZeroWidthSpaceAfterSpaceDeletedTogether() { XCTAssertEqual(WordDeletion.count(before: "ab \u{200B}"), 4) }
    func testZeroWidthSpaceInsideWordIsWordPart() { XCTAssertEqual(WordDeletion.count(before: "ab\u{200B}cd"), 5) }
    func testOnlyZeroWidthSpace() { XCTAssertEqual(WordDeletion.count(before: "\u{200B}"), 1) }
}
