import XCTest
@testable import KeyboardCore

/// 문서 "아어터커너\nㅏ커처" 를 예로, 메시지 앱처럼 문맥이 문단 단위로 잘려 오는 경우를 재현한다.
final class LineStepTests: XCTestCase {
    func testColumn() {
        XCTAssertEqual(LineStep.column(before: "아어"), 2)
        XCTAssertEqual(LineStep.column(before: "첫줄\n둘"), 1)
        XCTAssertEqual(LineStep.column(before: "\n"), 0)
        XCTAssertEqual(LineStep.column(before: ""), 0)
    }

    func testDownFromMiddleOfFirstLine() {
        // 커서 "아어|터커너": after 는 개행 없이 줄 끝까지만 온다
        XCTAssertEqual(LineStep.cross(.down, before: "아어", after: "터커너"), 4)
        // 다음 줄 처음에서 after 는 그 줄만
        XCTAssertEqual(LineStep.settle(.down, before: "\n", after: "ㅏ커처", goalColumn: 2), 2)
    }

    func testDownToShorterLineStopsAtLineEnd() {
        XCTAssertEqual(LineStep.settle(.down, before: "", after: "ㅏ", goalColumn: 4), 1)
    }

    func testUpFromStartOfSecondLine() {
        // 실측: 둘째 줄 처음에서 before 는 "\n" 하나
        XCTAssertEqual(LineStep.cross(.up, before: "\n", after: "ㅏ커처"), -1)
        // 첫 줄 끝에서 before 는 첫 줄 전체
        XCTAssertEqual(LineStep.settle(.up, before: "아어터커너", after: "", goalColumn: 0), -5)
    }

    func testUpKeepsColumnAndClampsToShorterLine() {
        XCTAssertEqual(LineStep.cross(.up, before: "앞\nㅏ커", after: "처"), -3)
        XCTAssertEqual(LineStep.settle(.up, before: "앞", after: "", goalColumn: 2), 0)
        XCTAssertEqual(LineStep.settle(.up, before: "아어터커너", after: "", goalColumn: 2), -3)
    }

    func testWholeContextInOneString() {
        // 문맥을 문서 전체로 주는 앱에서도 같은 결과
        XCTAssertEqual(LineStep.cross(.down, before: "아어", after: "터커너\nㅏ커처"), 4)
        XCTAssertEqual(LineStep.settle(.down, before: "아어터커너\n", after: "ㅏ커처", goalColumn: 2), 2)
        XCTAssertEqual(LineStep.settle(.up, before: "앞\n아어터커너", after: "\nㅏ커처", goalColumn: 2), -3)
    }

    func testLastAndFirstLineSettleToZero() {
        // 마지막 줄에서 아래: 1단계로 문서 끝에 멈추고 after 가 비어 2단계는 0
        XCTAssertEqual(LineStep.settle(.down, before: "끝", after: "", goalColumn: 3), 0)
        // 첫 줄에서 위: 1단계로 문서 처음에 멈추고 before 가 비어 2단계는 0
        XCTAssertEqual(LineStep.settle(.up, before: "", after: "아어", goalColumn: 3), 0)
    }

    func testCRLFIsOneCharacter() {
        XCTAssertEqual(LineStep.cross(.down, before: "", after: "ab\r\ncd"), 3)
        XCTAssertEqual(LineStep.column(before: "ab\r\nc"), 1)
    }
}
