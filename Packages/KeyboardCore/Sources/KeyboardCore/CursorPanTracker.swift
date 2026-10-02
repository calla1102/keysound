import CoreGraphics

/// 스페이스바 커서 이동 모드에서 손가락 위치를 「가로 칸 수 + 세로 줄 수」로 바꾼다.
///
/// 기준점(origin)에서 지금 위치까지의 변위로 축을 고른다: 가로 변위가 세로 이상이면 가로만, 아니면 세로만 센다.
/// 한 축이 칸을 넘기면 그 축은 넘긴 칸만큼만 기준점을 옮기고(남은 거리는 쌓아 둠), 다른 축의 기준점은 현재 위치로 다시 잡는다.
///
/// 세로로 끌 때 엄지가 호를 그려 옆으로 10pt 넘게 새도, 세로 변위가 더 크면 가로 칸이 나가지 않아 세로 누적이 지워지지 않는다.
/// (예전 방식은 각 축을 따로 세서 가로 1칸이 먼저 나가면 세로 누적을 버려, 위아래 이동이 됐다 안 됐다 했다.)
/// iOS 기본 트랙패드처럼 자유 대각선은 아니고 지배 축 우선이다. 줄 이동이 열 계산에 의존해 두 축이 섞이면 결과가 읽기 어렵기 때문이다.
public struct CursorPanTracker: Equatable {
    /// 한 줄을 옮기는 데 필요한 세로 거리(pt).
    /// 스페이스는 맨 아랫줄이라 아래로 끌 여유가 적어 키 높이(42pt)보다 작게 잡은 30pt. 설계상 추정이며 실기기에서 조정한다.
    public static let defaultLineStep: CGFloat = 30
    /// 한 칸을 옮기는 데 필요한 가로 거리(pt). 키 한 칸(약 35pt) 가로폭의 1/3 이내라 키보드 폭을 한 번 훑으면 한 줄 대부분을 지나가면서,
    /// 손 떨림(수 pt)에는 커서가 흔들리지 않는 크기(#25 에서 실기기 체감 확인).
    public static let defaultStep: CGFloat = 10

    public struct Delta: Equatable {
        public var columns: Int
        public var lines: Int
        public init(columns: Int, lines: Int) {
            self.columns = columns
            self.lines = lines
        }
    }

    public let step: CGFloat
    public let lineStep: CGFloat
    private var origin: CGPoint = .zero

    public init(step: CGFloat = CursorPanTracker.defaultStep, lineStep: CGFloat = CursorPanTracker.defaultLineStep) {
        precondition(step > 0 && lineStep > 0)
        self.step = step
        self.lineStep = lineStep
    }

    public mutating func begin(at point: CGPoint) {
        origin = point
    }

    /// 새로 옮길 칸 수(오른쪽 +)와 줄 수(아래 +). 둘 중 하나만 0 이 아니다.
    public mutating func move(to point: CGPoint) -> Delta {
        let dx = point.x - origin.x
        let dy = point.y - origin.y
        if abs(dx) >= abs(dy) {
            let columns = Int((dx / step).rounded(.towardZero))
            guard columns != 0 else { return Delta(columns: 0, lines: 0) }
            origin = CGPoint(x: origin.x + CGFloat(columns) * step, y: point.y)
            return Delta(columns: columns, lines: 0)
        } else {
            let lines = Int((dy / lineStep).rounded(.towardZero))
            guard lines != 0 else { return Delta(columns: 0, lines: 0) }
            origin = CGPoint(x: point.x, y: origin.y + CGFloat(lines) * lineStep)
            return Delta(columns: 0, lines: lines)
        }
    }
}
