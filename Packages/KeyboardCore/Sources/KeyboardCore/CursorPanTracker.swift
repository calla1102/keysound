import CoreGraphics

/// 스페이스바 커서 이동 모드에서 손가락 위치를 「가로 칸 수 + 세로 줄 수」로 바꾼다.
/// 각 축은 `CursorDragTracker` 로 누적 계산하고, 한 축이 움직이면 다른 축의 기준점을 현재 위치로 다시 잡는다.
///
/// 대각선 처리: 사선으로 끌면 두 축이 서로 부분 이동량을 쌓아 커서가 가로·세로로 번갈아 흔들린다.
/// 그래서 한 번의 `move` 에서 둘 다 넘으면 이동 거리(pt)가 큰 쪽만 취하고, 한 축이 나가면 다른 축의 쌓인 거리를 버린다.
/// 세로 줄 간격이 가로 칸보다 훨씬 크므로(40pt 대 10pt) 세로로 끌다 손가락이 살짝 옆으로 새도 가로 이동이 끼어들지 않는다.
/// (iOS 기본 트랙패드처럼 자유 대각선은 아니고 지배 축 우선이다. 줄 이동이 열 계산에 의존해 두 축이 섞이면 결과가 읽기 어렵기 때문이다.)
public struct CursorPanTracker: Equatable {
    /// 한 줄을 옮기는 데 필요한 세로 거리(pt). 키 높이(42pt)와 비슷하게 잡아 키보드 한 번 훑으면 3~4줄을 지나가고,
    /// 가로 step(10pt)보다 훨씬 커서 한 줄 이동이 한 칸보다 가볍게 일어나지 않는다. 설계상 추정이며 실기기에서 조정한다.
    public static let defaultLineStep: CGFloat = 40

    public struct Delta: Equatable {
        public var columns: Int
        public var lines: Int
        public init(columns: Int, lines: Int) {
            self.columns = columns
            self.lines = lines
        }
    }

    private var horizontal: CursorDragTracker
    private var vertical: CursorDragTracker

    public init(step: CGFloat = CursorDragTracker.defaultStep, lineStep: CGFloat = CursorPanTracker.defaultLineStep) {
        horizontal = CursorDragTracker(step: step)
        vertical = CursorDragTracker(step: lineStep)
    }

    public mutating func begin(at point: CGPoint) {
        horizontal.begin(at: point.x)
        vertical.begin(at: point.y)
    }

    /// 새로 옮길 칸 수(오른쪽 +)와 줄 수(아래 +). 둘 중 하나만 0 이 아니다.
    public mutating func move(to point: CGPoint) -> Delta {
        var h = horizontal
        var v = vertical
        var dx = h.move(to: point.x)
        var dy = v.move(to: point.y)
        if dx != 0 && dy != 0 {
            if abs(CGFloat(dx)) * horizontal.step >= abs(CGFloat(dy)) * vertical.step { dy = 0 } else { dx = 0 }
        }
        if dx != 0 {
            horizontal = h
            vertical.begin(at: point.y)
        } else if dy != 0 {
            vertical = v
            horizontal.begin(at: point.x)
        } else {
            horizontal = h
            vertical = v
        }
        return Delta(columns: dx, lines: dy)
    }
}
