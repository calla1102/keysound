import KeyboardCore
import UIKit

/// 키보드 영역 전체의 터치를 직접 받아 가장 가까운 키로 매핑하는 컨테이너.
/// - 키 사이 간격·가장자리에 닿은 터치도 버리지 않는다.
/// - 터치다운 순서대로(같은 이벤트 안에서는 timestamp 순) 콜백을 부른다.
/// - 멀티터치: 손가락마다 어떤 키를 눌렀는지 따로 기억해 롤오버 때도 뗄 때 정확한 키를 처리한다.
/// 🌐 키만은 시스템 핸들러(`handleInputModeList`)가 터치 이벤트를 직접 받아야 해서 버튼에 그대로 넘긴다.
final class KeyboardTouchView: UIView {
    /// 터치 판정 대상 키. 컨트롤러가 키를 다시 만들 때마다 갱신한다.
    var keys: [KeyButton] = []
    var onKeyDown: ((KeyButton) -> Void)?
    var onKeyUp: ((KeyButton) -> Void)?

    private var activeTouches: [UITouch: KeyButton] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 터치 지점에 대응하는 키. 레이아웃이 밀려 있으면 먼저 반영한다.
    private func nearestKey(at point: CGPoint) -> KeyButton? {
        layoutIfNeeded()
        let frames = keys.map { $0.superview == nil ? CGRect.zero : $0.convert($0.bounds, to: self) }
        return NearestKey.index(at: point, in: frames).map { keys[$0] }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event), !isHidden, alpha > 0.01 else { return nil }
        if let key = nearestKey(at: point), key.spec.action == .nextKeyboard {
            return key
        }
        return self
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let key = nearestKey(at: touch.location(in: self)) else { continue }
            activeTouches[touch] = key
            key.isHighlighted = true
            onKeyDown?(key)
        }
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

    private func finish(_ touches: Set<UITouch>) {
        for touch in touches.sorted(by: { $0.timestamp < $1.timestamp }) {
            guard let key = activeTouches.removeValue(forKey: touch) else { continue }
            key.isHighlighted = false
            onKeyUp?(key)
        }
    }
}
