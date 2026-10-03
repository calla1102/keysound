import CoreGraphics
import XCTest
@testable import KeyboardCore

final class AlternatePopupTests: XCTestCase {
    private let bounds = CGRect(x: 0, y: 0, width: 390, height: 260)

    func testDollarHasEuro() {
        XCTAssertTrue(AlternateCharacters.alternates(for: "$").contains("€"))
    }

    func testPlainKeyHasNoAlternates() {
        XCTAssertTrue(AlternateCharacters.alternates(for: "a").isEmpty)
        XCTAssertTrue(AlternateCharacters.alternates(for: "ㅂ").isEmpty)
    }

    func testTableNeverRepeatsBaseOrDuplicates() {
        for (base, alts) in AlternateCharacters.table {
            XCTAssertFalse(alts.contains(base), "\(base)")
            XCTAssertEqual(Set(alts).count, alts.count, "\(base)")
        }
    }

    func testLeftAlignedUnderKeyAndSelectsByX() {
        let key = CGRect(x: 100, y: 120, width: 36, height: 42)
        let g = AlternatePopupGeometry(keyFrame: key, cellCount: 4, bounds: bounds)
        XCTAssertFalse(g.reversed)
        XCTAssertEqual(g.frame.minX, 100)
        XCTAssertEqual(g.frame.maxY, 120 - AlternatePopupGeometry.gap)
        // 키 바로 위(손가락이 안 움직임) = 원래 문자
        XCTAssertEqual(g.candidate(at: CGPoint(x: 110, y: 140)), 0)
        XCTAssertEqual(g.candidate(at: CGPoint(x: 100 + 38 * 2 + 5, y: 100)), 2)
        // 가장자리 밖은 끝 칸
        XCTAssertEqual(g.candidate(at: CGPoint(x: 10, y: 100)), 0)
        XCTAssertEqual(g.candidate(at: CGPoint(x: 389, y: 100)), 3)
    }

    func testRightEdgeReversesSoBaseStaysOverKey() {
        let key = CGRect(x: 340, y: 120, width: 36, height: 42)
        let g = AlternatePopupGeometry(keyFrame: key, cellCount: 4, bounds: bounds)
        XCTAssertTrue(g.reversed)
        XCTAssertLessThanOrEqual(g.frame.maxX, bounds.maxX)
        XCTAssertEqual(g.candidate(at: CGPoint(x: 350, y: 140)), 0)
        XCTAssertEqual(g.candidate(at: CGPoint(x: g.frame.minX + 1, y: 100)), 3)
        XCTAssertEqual(g.slot(forCandidate: 0), 3)
    }

    func testFirstRowClampsToTop() {
        let key = CGRect(x: 100, y: 16, width: 36, height: 42)
        let g = AlternatePopupGeometry(keyFrame: key, cellCount: 3, bounds: bounds)
        XCTAssertEqual(g.frame.minY, 0)
    }

    func testFirstRowFingerOnKeySelectsBase() {
        // 팝업이 키를 덮어도 손가락이 키 위에 그대로면 원래 문자
        let key = CGRect(x: 100, y: 16, width: 36, height: 42)
        let g = AlternatePopupGeometry(keyFrame: key, cellCount: 3, bounds: bounds)
        XCTAssertEqual(g.candidate(at: CGPoint(x: 110, y: 40)), 0)
    }

    func testWideKeyUsesKeyWidthAsCell() {
        let key = CGRect(x: 40, y: 170, width: 60, height: 42)
        let g = AlternatePopupGeometry(keyFrame: key, cellCount: 3, bounds: bounds)
        XCTAssertEqual(g.cellWidth, 60)
        XCTAssertEqual(g.frame.width, 180)
    }

    func testTooManyCellsClampInsideBounds() {
        // 뒤집어도 왼쪽으로 넘치면 경계 안으로 민다
        let key = CGRect(x: 200, y: 120, width: 36, height: 42)
        let g = AlternatePopupGeometry(keyFrame: key, cellCount: 12, bounds: bounds)
        XCTAssertTrue(g.reversed)
        XCTAssertEqual(g.frame.minX, AlternatePopupGeometry.edgeMargin)
    }

    func testSlotAndCandidateAreInverse() {
        for keyX in [CGFloat(100), 340] {
            let g = AlternatePopupGeometry(keyFrame: CGRect(x: keyX, y: 120, width: 36, height: 42), cellCount: 5, bounds: bounds)
            for i in 0..<5 {
                XCTAssertEqual(g.candidateIndex(forSlot: g.slot(forCandidate: i)), i)
                XCTAssertEqual(g.slot(forCandidate: g.candidateIndex(forSlot: i)), i)
            }
        }
    }

    func testFarVerticalMoveCancels() {
        let key = CGRect(x: 100, y: 120, width: 36, height: 42)
        let g = AlternatePopupGeometry(keyFrame: key, cellCount: 3, bounds: bounds)
        XCTAssertNil(g.candidate(at: CGPoint(x: 110, y: 120 + 42 + AlternatePopupGeometry.cancelSlack + 1)))
        XCTAssertNil(g.candidate(at: CGPoint(x: 110, y: g.frame.minY - AlternatePopupGeometry.cancelSlack - 1)))
        XCTAssertNotNil(g.candidate(at: CGPoint(x: 110, y: g.frame.minY - 10)))
    }
}
