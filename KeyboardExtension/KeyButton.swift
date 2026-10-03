import UIKit

/// 키 하나. 눌림 상태에 따라 배경색만 바꾸고, 입력·소리 처리는 컨트롤러가 한다.
final class KeyButton: UIButton {
    let spec: KeySpec
    let soundKind: KeySoundPlayer.Kind

    /// 접근성 요소(`KeyboardTouchView`)가 상태 트레잇을 계산할 때 읽는다.
    private(set) var isDimmed = false
    private(set) var isEmphasized = false

    private var normalColor: UIColor
    private let pressedColor: UIColor
    private let baseColor: UIColor

    private let theme: KeyboardTheme

    init(spec: KeySpec, soundKind: KeySoundPlayer.Kind, theme: KeyboardTheme) {
        self.spec = spec
        self.theme = theme
        self.soundKind = soundKind
        let isFunction = Self.isFunctionKey(spec.action)
        baseColor = isFunction ? theme.dynamicColor(\.functionKey) : theme.dynamicColor(\.characterKey)
        normalColor = baseColor
        pressedColor = isFunction ? theme.dynamicColor(\.functionKeyPressed) : theme.dynamicColor(\.characterKeyPressed)
        super.init(frame: .zero)

        backgroundColor = normalColor
        let textColor = theme.dynamicColor(\.text)
        tintColor = textColor
        setTitleColor(textColor, for: .normal)
        titleLabel?.font = .systemFont(ofSize: Self.isCharacterKey(spec.action) ? 22 : 16)
        layer.cornerRadius = CGFloat(theme.cornerRadius)
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 0
        updateShadow()
        // CGColor 는 라이트↔다크를 자동으로 따르지 않아 모드가 바뀔 때 다시 칠한다
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (key: KeyButton, _) in
            key.updateShadow()
        }
    }

    private func updateShadow() {
        if let color = theme.shadowUIColor(for: traitCollection) {
            layer.shadowColor = color.cgColor
            layer.shadowOpacity = 1
        } else {
            layer.shadowOpacity = 0
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 그림자 모양을 미리 알려 줘야 키마다 offscreen 렌더링을 하지 않는다
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
    }

    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? pressedColor : normalColor }
    }

    /// 켜진 토글(캡스락 등)은 글자 키 색으로 밝게 보인다.
    func setEmphasized(_ on: Bool) {
        isEmphasized = on
        normalColor = on ? theme.dynamicColor(\.characterKey) : baseColor
        backgroundColor = isHighlighted ? pressedColor : normalColor
    }

    /// 스페이스 커서 이동 모드에서 라벨(글자·아이콘)을 숨긴다. 키 배경은 그대로 둬 트랙패드처럼 보인다.
    func setLabelHidden(_ hidden: Bool) {
        titleLabel?.alpha = hidden ? 0 : 1
        imageView?.alpha = hidden ? 0 : 1
    }

    /// 비활성으로 보이게만 한다(리턴 키 자동 비활성). 실제 입력 차단은 컨트롤러가 한다.
    func setDimmed(_ dimmed: Bool) {
        isDimmed = dimmed
        alpha = dimmed ? 0.5 : 1
    }

    func setLabel(title: String? = nil, symbol: String? = nil) {
        setTitle(title, for: .normal)
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        setImage(symbol.flatMap { UIImage(systemName: $0, withConfiguration: config) }, for: .normal)
    }

    private static func isCharacterKey(_ action: KeyAction) -> Bool {
        if case .character = action { return true }
        return false
    }

    private static func isFunctionKey(_ action: KeyAction) -> Bool {
        switch action {
        case .character, .space, .spacer: false
        case .shift, .backspace, .enter, .layer, .nextKeyboard: true
        }
    }
}
