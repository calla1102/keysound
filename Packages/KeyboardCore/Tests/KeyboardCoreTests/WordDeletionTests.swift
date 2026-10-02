import XCTest
@testable import KeyboardCore

final class WordDeletionTests: XCTestCase {
    func testEmpty() { XCTAssertEqual(WordDeletion.count(before: ""), 0) }
    func testSingleWord() { XCTAssertEqual(WordDeletion.count(before: "hello"), 5) }
    func testLastWordOnly() { XCTAssertEqual(WordDeletion.count(before: "안녕 하세요"), 3) }
    func testTrailingSpacesIncluded() { XCTAssertEqual(WordDeletion.count(before: "안녕 하세요  "), 5) }
    func testOnlySpaces() { XCTAssertEqual(WordDeletion.count(before: "ab   "), 5) }
    func testNewlineIsBoundary() { XCTAssertEqual(WordDeletion.count(before: "abc\ndef"), 3) }
    func testTrailingNewlineOnly() { XCTAssertEqual(WordDeletion.count(before: "abc\n"), 1) }
    func testSpacesThenNewlineStopsAtNewline() { XCTAssertEqual(WordDeletion.count(before: "abc\n  "), 2) }
    func testPunctuationAttachedToWord() { XCTAssertEqual(WordDeletion.count(before: "a, b.c!"), 4) }
    func testEmojiCountsAsOneCharacter() { XCTAssertEqual(WordDeletion.count(before: "hi 👍🏽😀"), 2) }
}
