import CoreGraphics

/// 스페이스바 커서 이동 모드에서 가로 드래그 거리를 「옮길 칸 수」로 바꾼다.
/// 시작점 기준 누적 칸 수(0 방향 버림)에서 이미 옮긴 칸 수를 뺀 값을 돌려주므로,
/// 한 번에 덜 움직인 거리가 버려지지 않고 쌓이며, 되돌아오면 반대로 같은 칸 수만큼 돌아간다.
public struct CursorDragTracker: Equatable {
    /// 한 칸을 옮기는 데 필요한 가로 거리(pt).
    /// 키 한 칸(약 35pt) 가로폭의 1/3 이내라 키보드 폭(약 390pt)을 한 번 훑으면 한 줄 대부분을 지나가면서,
    /// 손 떨림(수 pt)에는 커서가 흔들리지 않는 크기로 잡은 10pt. 근거는 설계상 추정이며 실기기에서 조정한다.
    public static let defaultStep: CGFloat = 10

    public let step: CGFloat
    private var anchor: CGFloat = 0
    private var consumed = 0

    public init(step: CGFloat = CursorDragTracker.defaultStep) {
        precondition(step > 0)
        self.step = step
    }

    /// 이동 모드 진입 시점의 x 를 기준점으로 삼는다.
    public mutating func begin(at x: CGFloat) {
        anchor = x
        consumed = 0
    }

    /// 손가락이 `x` 로 옮겨졌다. 이번에 새로 옮겨야 할 칸 수(오른쪽 +, 왼쪽 -)를 돌려준다.
    public mutating func move(to x: CGFloat) -> Int {
        let cells = Int(((x - anchor) / step).rounded(.towardZero))
        let delta = cells - consumed
        consumed = cells
        return delta
    }
}
