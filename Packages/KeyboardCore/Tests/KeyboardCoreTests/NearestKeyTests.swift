import CoreGraphics
import XCTest
@testable import KeyboardCore

final class NearestKeyTests: XCTestCase {
    // 폭 30 키 3개, 가로 간격 6, 높이 42 두 줄, 줄 간격 10
    private let frames: [CGRect] = [
        CGRect(x: 0, y: 0, width: 30, height: 42),
        CGRect(x: 36, y: 0, width: 30, height: 42),
        CGRect(x: 72, y: 0, width: 30, height: 42),
        CGRect(x: 0, y: 52, width: 30, height: 42),
        CGRect(x: 36, y: 52, width: 30, height: 42),
    ]

    func testInsideKey() {
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 40, y: 10), in: frames), 1)
    }

    func testHorizontalGapGoesToCloserKey() {
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 32, y: 10), in: frames), 0)
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 34, y: 10), in: frames), 1)
    }

    func testVerticalGapGoesToCloserKey() {
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 10, y: 45), in: frames), 0)
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 10, y: 50), in: frames), 3)
    }

    func testTieGoesToEarlierKey() {
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 33, y: 10), in: frames), 0)
    }

    func testOutsideEdgesMapToNearestKey() {
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: -20, y: -20), in: frames), 0)
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 200, y: 10), in: frames), 2)
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 60, y: 200), in: frames), 4)
    }

    func testEmptyFramesAreSkipped() {
        XCTAssertNil(NearestKey.index(at: .zero, in: []))
        XCTAssertEqual(NearestKey.index(at: CGPoint(x: 5, y: 5), in: [.zero, CGRect(x: 100, y: 0, width: 10, height: 10)]), 1)
    }
}
