import KeyboardCore
import UIKit

/// 키보드 영역 전체의 터치를 직접 받아 가장 가까운 키로 매핑하는 컨테이너.
/// - 키 사이 간격·가장자리에 닿은 터치도 버리지 않는다.
/// - 터치다운 순서대로 콜백을 부른다. 같은 이벤트 안에서는 timestamp 순이고, timestamp 가 같을 수 있어(같은 이벤트의 터치는 같은 값을 가질 수 있다) 동률이면 x 좌표가 작은 쪽을 먼저 처리한다.
/// - 멀티터치: 손가락마다 어떤 키를 눌렀는지 따로 기억해 롤오버 때도 뗄 때 정확한 키를 처리한다.
/// 🌐 키만은 시스템 핸들러(`handleInputModeList`)가 터치 이벤트를 직접 받아야 해서 버튼에 그대로 넘긴다.
final class KeyboardTouchView: UIView {
    /// 터치 판정 대상 키. 컨트롤러가 키를 다시 만들 때마다 갱신한다.
    var keys: [KeyButton] = [] {
        didSet {
            framesDirty = true
            setNeedsLayout()
        }
    }
    /// 콜백에 넘기는 터치 정보. `id` 는 같은 손가락의 down·move·up 을 이어 주고, `x` 는 이 뷰 좌표계의 가로 위치.
    struct TouchInfo {
        let id: ObjectIdentifier
        let x: CGFloat
    }

    /// 키를 눌렀다. 컨트롤러가 이 터치를 받아들이면 true — false(무시)면 눌림 표시를 켜지 않는다.
    var onKeyDown: ((KeyButton, TouchInfo) -> Bool)?
    var onKeyUp: ((KeyButton, TouchInfo) -> Void)?
    /// 키를 누른 채 손가락이 움직였다(그 터치가 처음 누른 키 기준). 스페이스 커서 이동에 쓴다.
    var onKeyMove: ((KeyButton, TouchInfo) -> Void)?

    private var activeTouches: [UITouch: KeyButton] = [:]
    /// 키 프레임(self 좌표계) 캐시. 레이아웃이 바뀌면 무효화만 하고, 다음 터치에서 하위 레이아웃을 마친 뒤 다시 계산한다.
    private var keyFrames: [CGRect] = []
    private var framesDirty = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 여기서 계산하면 손자(행 스택 → 키)가 아직 배치되기 전 frame 을 담을 수 있다
        framesDirty = true
    }

    private func refreshKeyFrames() {
        keyFrames = keys.map { $0.superview == nil ? CGRect.zero : $0.convert($0.bounds, to: self) }
        framesDirty = false
    }

    /// 터치 지점에 대응하는 키. 밀린 레이아웃을 하위 트리까지 반영한 뒤 캐시를 쓴다.
    private func nearestKey(at point: CGPoint) -> KeyButton? {
        layoutIfNeeded()
        if framesDirty { refreshKeyFrames() }
        return NearestKey.index(at: point, in: keyFrames).map { keys[$0] }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event), !isHidden, alpha > 0.01 else { return nil }
        if let key = nearestKey(at: point), key.spec.action == .nextKeyboard {
            return key
        }
        return self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in ordered(touches) {
            guard let key = nearestKey(at: touch.location(in: self)) else { continue }
            activeTouches[touch] = key
            if onKeyDown?(key, info(touch)) ?? true { key.isHighlighted = true }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 이동은 순서가 의미 없어 정렬하지 않는다
        for touch in touches {
            guard let key = activeTouches[touch] else { continue }
            onKeyMove?(key, info(touch))
        }
    }

    private func info(_ touch: UITouch) -> TouchInfo {
        TouchInfo(id: ObjectIdentifier(touch), x: touch.location(in: self).x)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finish(touches)
    }

    /// 키보드가 사라질 때 끝나지 않은 터치를 소리 없이 정리한다(시스템이 cancel 을 안 보낼 수 있다).
    func resetTouches() {
        activeTouches.values.forEach { $0.isHighlighted = false }
        activeTouches = [:]
    }

    /// 아직 떼지 않은 터치 중 조건에 맞는 키가 있는지. `onKeyUp` 시점에는 뗀 터치가 이미 빠져 있다.
    func hasActiveTouch(where predicate: (KeyButton, ObjectIdentifier) -> Bool) -> Bool {
        activeTouches.contains { predicate($0.value, ObjectIdentifier($0.key)) }
    }

    /// timestamp 순, 같으면 x 좌표 순. 같은 이벤트의 터치는 timestamp 가 같을 수 있어 보조 기준이 필요하다.
    private func ordered(_ touches: Set<UITouch>) -> [UITouch] {
        touches.sorted {
            if $0.timestamp != $1.timestamp { return $0.timestamp < $1.timestamp }
            return $0.location(in: self).x < $1.location(in: self).x
        }
    }

    private func finish(_ touches: Set<UITouch>) {
        for touch in ordered(touches) {
            guard let key = activeTouches.removeValue(forKey: touch) else { continue }
            key.isHighlighted = false
            onKeyUp?(key, info(touch))
        }
    }
}
