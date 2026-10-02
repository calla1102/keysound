/// Shift 키 상태 머신.
/// - 한 번 탭: 다음 글자 1개만 대문자(`once`)
/// - 짧은 간격 안에 다시 탭: 캡스락(`caps`)
/// - `once` 에서 간격이 지난 뒤 탭, 또는 `caps` 에서 탭: 해제(`off`)
/// 시각을 호출 쪽에서 넘기므로 시계 없이 테스트할 수 있다.
public struct ShiftState: Equatable {
    public enum Mode: Equatable {
        case off, once, caps
    }

    /// 두 번 탭으로 인정하는 최대 간격(초).
    public static let doubleTapInterval: Double = 0.4

    public private(set) var mode: Mode = .off
    private var lastTapTime: Double?

    public init() {}

    public var isActive: Bool { mode != .off }

    /// Shift 키를 탭했다. `allowsCaps` 가 false(한글 레이어)이면 캡스락 없이 켜짐/꺼짐만 오간다.
    public mutating func tap(at time: Double, allowsCaps: Bool) {
        switch mode {
        case .off:
            mode = .once
            lastTapTime = time
        case .once:
            if allowsCaps, let last = lastTapTime, time - last <= Self.doubleTapInterval {
                mode = .caps
            } else {
                mode = .off
            }
            lastTapTime = nil
        case .caps:
            mode = .off
            lastTapTime = nil
        }
    }

    /// 글자 하나를 입력했다. 1회성 Shift 는 풀리고 캡스락은 유지된다.
    public mutating func didInputCharacter() {
        if mode == .once {
            mode = .off
            lastTapTime = nil
        }
    }

    /// 1회성 Shift 만 푼다(키보드가 다시 열릴 때). 캡스락은 유지한다.
    public mutating func clearOnce() {
        if mode == .once { reset() }
    }

    public mutating func reset() {
        mode = .off
        lastTapTime = nil
    }
}
