import CoreGraphics

/// 길게 누르기 대체 문자 팝업의 위치와 선택 계산. 화면 그리기와 분리해 테스트한다.
///
/// - 팝업은 누른 키 바로 위에 놓고 첫 칸(원래 문자)이 키 위에 오게 한다. 오른쪽 끝 키처럼 넘치면 키의 오른쪽 변에 맞추고 순서를 뒤집는다.
/// - 키 위 공간이 모자라(첫 줄) 위로 잘리면 키보드 위 가장자리에 붙이고 키를 덮는다. 익스텐션은 자기 뷰 밖에 그릴 수 없다.
/// - 손가락 x 는 가장 가까운 칸으로 가고(가장자리 밖은 끝 칸), y 가 팝업·키 영역에서 `cancelSlack` 넘게 벗어나면 취소(nil)다.
public struct AlternatePopupGeometry: Equatable {
    public static let cellHeight: CGFloat = 50
    public static let minCellWidth: CGFloat = 38
    /// 키 위쪽과 팝업 아래쪽 사이 틈
    public static let gap: CGFloat = 4
    /// 팝업과 키 영역 위·아래로 이만큼까지는 선택이 유지된다
    public static let cancelSlack: CGFloat = 50
    static let edgeMargin: CGFloat = 3

    /// 팝업 전체 프레임(키보드 뷰 좌표)
    public let frame: CGRect
    public let cellWidth: CGFloat
    public let cellCount: Int
    /// true 면 칸 순서를 뒤집어 그린다(첫 칸이 오른쪽 끝)
    public let reversed: Bool
    let keyFrame: CGRect

    /// - Parameters:
    ///   - keyFrame: 누른 키의 프레임(키보드 뷰 좌표)
    ///   - cellCount: 원래 문자를 포함한 칸 수
    ///   - bounds: 키보드 뷰 경계
    public init(keyFrame: CGRect, cellCount: Int, bounds: CGRect) {
        let cellWidth = max(keyFrame.width, Self.minCellWidth)
        let total = cellWidth * CGFloat(cellCount)
        var x = keyFrame.minX
        var reversed = false
        if x + total > bounds.maxX - Self.edgeMargin {
            x = keyFrame.maxX - total
            reversed = true
        }
        // 그래도 넘치면(칸이 아주 많을 때) 경계 안으로 민다
        x = min(max(x, bounds.minX + Self.edgeMargin), max(bounds.minX + Self.edgeMargin, bounds.maxX - Self.edgeMargin - total))
        let y = max(bounds.minY, keyFrame.minY - Self.gap - Self.cellHeight)
        self.frame = CGRect(x: x, y: y, width: total, height: Self.cellHeight)
        self.cellWidth = cellWidth
        self.cellCount = cellCount
        self.reversed = reversed
        self.keyFrame = keyFrame
    }

    /// 화면의 왼쪽부터 `slot` 번째 칸이 가리키는 후보 번호(0 = 원래 문자).
    public func candidateIndex(forSlot slot: Int) -> Int {
        reversed ? cellCount - 1 - slot : slot
    }

    /// 후보 번호가 그려지는 화면 칸(왼쪽부터).
    public func slot(forCandidate index: Int) -> Int {
        reversed ? cellCount - 1 - index : index
    }

    /// 손가락 위치가 가리키는 후보 번호. 취소 영역이면 nil.
    public func candidate(at point: CGPoint) -> Int? {
        let top = min(frame.minY, keyFrame.minY) - Self.cancelSlack
        let bottom = max(frame.maxY, keyFrame.maxY) + Self.cancelSlack
        guard point.y >= top, point.y <= bottom else { return nil }
        let raw = Int(((point.x - frame.minX) / cellWidth).rounded(.down))
        return candidateIndex(forSlot: min(max(raw, 0), cellCount - 1))
    }
}
