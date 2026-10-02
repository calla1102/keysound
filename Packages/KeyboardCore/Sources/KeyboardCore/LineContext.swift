/// 커서 앞뒤 문맥. 위아래 줄 이동에 필요한 오프셋을 계산하고, 우리가 옮긴 커서를 로컬에서 따라간다.
///
/// 키보드 익스텐션은 커서를 `adjustTextPosition(byCharacterOffset:)` 로만 옮길 수 있고 세로 이동 API 가 없다.
/// 그래서 `documentContextBeforeInput`/`AfterInput` 의 줄바꿈(하드 개행)으로 줄을 나눠 같은 열로 가는 글자 수를 계산한다.
/// 자동 줄바꿈(soft wrap)은 알 수 없으므로 개행으로 나뉜 줄만 다룬다. 글자 수는 Character 단위다.
public struct LineContext: Equatable {
    public enum Direction { case up, down }

    public struct Move: Equatable {
        /// `adjustTextPosition` 에 넘길 글자 수(위 -, 아래 +).
        public var offset: Int
        /// 연속 이동 때 유지할 목표 열.
        public var goalColumn: Int
    }

    public var before: String
    public var after: String

    public init(before: String, after: String) {
        self.before = before
        self.after = after
    }

    /// 한 줄 위/아래의 같은 열(목표 열, 줄이 짧으면 줄 끝)로 가는 이동. 이동할 수 없으면 nil.
    /// - 이동 방향 쪽 문맥에 개행이 없으면 첫/마지막 줄이거나 문맥이 잘린 것이라 구분할 수 없어 움직이지 않는다.
    ///   (잘린 문맥에서 엉뚱한 줄로 가는 것보다 안 움직이는 쪽이 안전하다.)
    /// - `goalColumn` 이 nil 이면 현재 열을 목표로 삼는다. 짧은 줄을 지나도 원래 열로 돌아오게 호출자가 `Move.goalColumn` 을 되넘긴다.
    public func verticalMove(_ direction: Direction, goalColumn: Int?) -> Move? {
        let b = Array(before)
        let a = Array(after)
        let lastBreakBefore = b.lastIndex(where: \.isNewline)
        let currentColumn = lastBreakBefore.map { b.count - $0 - 1 } ?? b.count
        let goal = goalColumn ?? currentColumn
        switch direction {
        case .up:
            guard let lineStart = lastBreakBefore else { return nil }
            let prevStart = b[..<lineStart].lastIndex(where: \.isNewline).map { $0 + 1 } ?? 0
            let prevLength = lineStart - prevStart
            let target = min(goal, prevLength)
            // 현재 줄 처음까지(열) + 개행 1 + 이전 줄 끝에서 목표 열까지 되돌아감
            return Move(offset: -(currentColumn + 1 + prevLength - target), goalColumn: goal)
        case .down:
            guard let lineEnd = a.firstIndex(where: \.isNewline) else { return nil }
            let nextStart = lineEnd + 1
            let nextEnd = a[nextStart...].firstIndex(where: \.isNewline) ?? a.count
            let target = min(goal, nextEnd - nextStart)
            return Move(offset: lineEnd + 1 + target, goalColumn: goal)
        }
    }

    /// 커서가 `offset` 글자 옮겨진 것으로 문맥을 갱신한다. 아는 범위를 넘으면 거기서 멈춘다.
    /// 호스트 앱의 문맥은 `adjustTextPosition` 직후 한발 늦게 갱신되므로, 연속 이동은 이 로컬 추정으로 계산한다.
    public mutating func shift(by offset: Int) {
        if offset > 0 {
            let moved = after.prefix(offset)
            before += moved
            after.removeFirst(moved.count)
        } else if offset < 0 {
            let moved = before.suffix(-offset)
            after = String(moved) + after
            before.removeLast(moved.count)
        }
    }
}
