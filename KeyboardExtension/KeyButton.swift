import UIKit

/// 키 하나. 눌림 상태에 따라 배경색만 바꾸고, 입력·소리 처리는 컨트롤러가 한다.
final class KeyButton: UIButton {
    let spec: KeySpec
    let soundKind: KeySoundPlayer.Kind

    private var normalColor: UIColor
    private let pressedColor: UIColor
    private let baseColor: UIColor

    init(spec: KeySpec, soundKind: KeySoundPlayer.Kind) {
        self.spec = spec
        self.soundKind = soundKind
        let isFunction = Self.isFunctionKey(spec.action)
        baseColor = isFunction ? Palette.functionKey : Palette.characterKey
        normalColor = baseColor
        pressedColor = isFunction ? Palette.characterKey : Palette.functionKey
        super.init(frame: .zero)

        backgroundColor = normalColor
        tintColor = .label
        setTitleColor(.label, for: .normal)
        titleLabel?.font = .systemFont(ofSize: Self.isCharacterKey(spec.action) ? 22 : 16)
        layer.cornerRadius = 5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 0
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
        normalColor = on ? Palette.characterKey : baseColor
        backgroundColor = isHighlighted ? pressedColor : normalColor
    }

    /// 스페이스 커서 이동 모드에서 라벨(글자·아이콘)을 숨긴다. 키 배경은 그대로 둬 트랙패드처럼 보인다.
    func setLabelHidden(_ hidden: Bool) {
        titleLabel?.alpha = hidden ? 0 : 1
        imageView?.alpha = hidden ? 0 : 1
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

/// iOS 기본 키보드와 비슷한 색. 라이트·다크 모드를 따른다.
enum Palette {
    static let characterKey = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 0.42, alpha: 1)
        : .white
    }
    static let functionKey = UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(white: 0.27, alpha: 1)
        : UIColor(red: 0.67, green: 0.70, blue: 0.74, alpha: 1)
    }
}
