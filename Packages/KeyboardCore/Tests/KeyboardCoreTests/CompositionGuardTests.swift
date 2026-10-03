import XCTest
import KeyboardCore

final class CompositionGuardTests: XCTestCase {
    private func stale(_ g: CompositionGuard, composing: String = "가", before: String?, documentEmpty: Bool = false,
                       edit: Double = 0, now: Double) -> Bool {
        g.isStale(composing: composing, before: before, documentEmpty: documentEmpty, lastEditTime: edit, now: now)
    }

    func testNilContextKeepsComposition() {
        XCTAssertFalse(stale(CompositionGuard(), before: nil, now: 100))
    }

    func testContextEndingWithComposingIsNotStale() {
        XCTAssertFalse(stale(CompositionGuard(), before: "안녕 가", now: 100))
    }

    func testMismatchAfterGraceIsStale() {
        XCTAssertTrue(stale(CompositionGuard(), before: "안녕 나", edit: 0, now: 0.5))
    }

    func testGraceBoundary() {
        var g = CompositionGuard()
        g.note(composing: "", at: 0) // 빈 기록이 있어 유예 안에서는 관대
        // now - lastEdit < 0.3 이면 유예 안
        XCTAssertFalse(stale(g, before: "다른", edit: 0, now: 0.299))
        // 정확히 0.3 은 유예 밖(<) → stale. 뺄셈이 정확히 grace 가 되도록 edit 을 0 으로 둔다
        XCTAssertTrue(stale(g, before: "다른", edit: 0, now: CompositionGuard.grace))
    }

    func testWithinGraceMatchingRecentRecordIsNotStale() {
        var g = CompositionGuard()
        g.note(composing: "ㅎ", at: 10)
        g.note(composing: "하", at: 10.1)
        // 호스트 문맥이 한발 늦어 이전 조합 "ㅎ" 로 끝남
        XCTAssertFalse(stale(g, composing: "한", before: "안녕 ㅎ", edit: 10.1, now: 10.2))
    }

    func testWithinGraceNoMatchingRecordIsStale() {
        var g = CompositionGuard()
        g.note(composing: "ㅎ", at: 10)
        XCTAssertTrue(stale(g, composing: "하", before: "다른 글", edit: 10, now: 10.1))
    }

    func testRecordWindowInclusiveAndExclusive() {
        var g = CompositionGuard()
        g.note(composing: "ㅎ", at: 0)
        // 마지막 편집이 늦어 유예 안이어도 기록이 창 밖이면 무시 (0.6 은 포함, 0.75 는 제외)
        XCTAssertFalse(g.isStale(composing: "하", before: "ㅎ", documentEmpty: false, lastEditTime: 0.5, now: 0.6))
        XCTAssertTrue(g.isStale(composing: "하", before: "ㅎ", documentEmpty: false, lastEditTime: 0.7, now: 0.75))
    }

    func testNotePrunesRecordsOlderThanWindow() {
        var g = CompositionGuard()
        g.note(composing: "ㅎ", at: 0)
        g.note(composing: "하", at: 0.6)   // 0.6 - 0 = 0.6, > 0.6 아님 → 유지
        XCTAssertEqual(g.records.count, 2)
        g.note(composing: "한", at: 0.7)   // 첫 기록 0.7 > 0.6 → 제거
        XCTAssertEqual(g.records.map(\.text), ["하", "한"])
    }

    func testEmptyRecordMeansJustStartedSoNotStaleWithinGrace() {
        var g = CompositionGuard()
        g.note(composing: "", at: 5)
        XCTAssertFalse(stale(g, composing: "ㅎ", before: "아무 문맥", edit: 5, now: 5.1))
    }

    func testEmptyRecordOutsideWindowIsIgnored() {
        var g = CompositionGuard()
        g.note(composing: "", at: 5)
        XCTAssertTrue(stale(g, composing: "ㅎ", before: "아무 문맥", edit: 5.65, now: 5.7))
    }

    func testEmptyContextWithComposingIsStaleAfterGrace() {
        XCTAssertTrue(stale(CompositionGuard(), before: "", edit: 0, now: 1))
    }

    func testEmptyContextWithinGraceWithoutRecordsIsStale() {
        XCTAssertTrue(stale(CompositionGuard(), before: "", edit: 0, now: 0.1))
    }

    func testResetClearsRecords() {
        var g = CompositionGuard()
        g.note(composing: "", at: 0)
        g.reset()
        XCTAssertTrue(g.records.isEmpty)
        XCTAssertTrue(stale(g, before: "다른", edit: 0, now: 0.1))
    }

    // MARK: 호스트가 문서를 비운 경우(#45)

    func testEmptiedDocumentNilContextAfterGraceIsStale() {
        // 보내기 직후: 문맥 nil + hasText false → 조합 버림
        XCTAssertTrue(CompositionGuard().isStale(composing: "요", before: nil, documentEmpty: true, lastEditTime: 0, now: 1))
    }

    func testEmptiedDocumentWithinGraceIsNotStale() {
        // 방금 우리가 편집했다면 호스트 갱신이 늦은 것일 수 있다(빈 문서 첫 글자 오탐 방지)
        XCTAssertFalse(CompositionGuard().isStale(composing: "ㅇ", before: nil, documentEmpty: true, lastEditTime: 0, now: 0.1))
    }

    func testEmptiedDocumentAtGraceBoundaryIsStale() {
        // 경계: 마지막 편집 뒤 정확히 grace 가 지나면 stale (>= 유지)
        XCTAssertTrue(CompositionGuard().isStale(composing: "요", before: nil, documentEmpty: true,
                                                 lastEditTime: 0, now: CompositionGuard.grace))
    }

    func testEmptiedDocumentWithinGraceIgnoresRecords() {
        // nil 분기는 유예 중이면 최근 기록과 무관하게 유지한다
        var g = CompositionGuard()
        g.note(composing: "요", at: 0)
        XCTAssertFalse(g.isStale(composing: "요", before: nil, documentEmpty: true, lastEditTime: 0, now: 0.1))
    }

    func testUnreadableContextWithTextIsKept() {
        XCTAssertFalse(CompositionGuard().isStale(composing: "요", before: nil, documentEmpty: false, lastEditTime: 0, now: 1))
    }

    func testEmptyStringContextAfterGraceIsStale() {
        XCTAssertTrue(CompositionGuard().isStale(composing: "요", before: "", documentEmpty: true, lastEditTime: 0, now: 1))
    }

    func testContextEndingWithComposingStaysEvenIfDocumentEmptyFlag() {
        XCTAssertFalse(CompositionGuard().isStale(composing: "요", before: "안녕하세요", documentEmpty: true, lastEditTime: 0, now: 1))
    }

    func testOtherFieldFocusContextIsStale() {
        XCTAssertTrue(CompositionGuard().isStale(composing: "요", before: "다른 칸 글", documentEmpty: false, lastEditTime: 0, now: 1))
    }
}
