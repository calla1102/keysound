import UIKit

/// 키 하나. 눌림 상태에 따라 배경색만 바꾸고, 입력·소리 처리는 컨트롤러가 한다.
final class KeyButton: UIButton {
    let spec: KeySpec
    let soundKind: KeySoundPlayer.Kind
    /// 길게 누르면 고를 수 있는 대체 문자. 비어 있으면 평소처럼 누르는 즉시 입력한다.
    var alternates: [Character] = []

    /// 접근성 요소(`KeyboardTouchView`)가 상태 트레잇을 계산할 때 읽는다.
    private(set) var isDimmed = false
    private(set) var isEmphasized = false

    private let theme: KeyboardTheme
    private let colorRole: KeyColorRole
    private let tile: KeyPattern.Tile?
    /// 볼록: 키 본체(`layer`)가 측면색이고 이 면이 윗면이다. 눌리면 면이 내려와 측면이 줄어든다. 그 외에는 nil
    private var faceLayer: CALayer?
    /// 볼록·유리(위쪽 하이라이트)·오목(방사형) 중 해당하는 그라데이션 1개. flat 이면 nil
    private var reliefLayer: CAGradientLayer?
    private var laidOutBounds: CGRect = .zero

    /// `.horizontal` 팔레트용 키 중심의 가로 위치 비율(0...1). 컨트롤러가 레이아웃 뒤에 넘긴다.
    var horizontalPosition: Double? {
        didSet {
            guard theme.paletteMode == .horizontal, horizontalPosition != oldValue else { return }
            updateAppearance()
        }
    }

    /// - Parameter characterIndex: 글자 키 순서(0부터, 키보드 순서). 팔레트·무늬를 고르는 데 쓴다.
    init(spec: KeySpec, soundKind: KeySoundPlayer.Kind, theme: KeyboardTheme, characterIndex: Int = 0) {
        self.spec = spec
        self.theme = theme
        self.soundKind = soundKind
        switch spec.action {
        case .character: colorRole = .character(index: characterIndex)
        case .space, .spacer: colorRole = .space
        case .enter: colorRole = .enter
        case .shift, .backspace, .layer, .nextKeyboard: colorRole = .function
        }
        if case .character = colorRole {
            tile = theme.keyPattern?.tile(forCharacterIndex: characterIndex, scope: theme.patternScope)
        } else {
            tile = nil
        }
        super.init(frame: .zero)

        titleLabel?.font = theme.keyFont(characterKey: Self.isCharacterKey(spec.action))
        installLayers()
        updateAppearance()
        // CGColor 는 라이트↔다크를 자동으로 따르지 않아 모드가 바뀔 때 다시 칠한다
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (key: KeyButton, _) in
            key.updateAppearance()
        }
    }

    private func installLayers() {
        let relief = theme.relief
        if relief == .raised {
            let face = CALayer()
            layer.insertSublayer(face, at: 0)
            faceLayer = face
        }
        let gradient = CAGradientLayer()
        switch relief {
        case .flat:
            return
        case .raised, .glass:
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
        case .dished:
            gradient.type = .radial
            gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradient.endPoint = CGPoint(x: 1, y: 1)
        }
        // 라벨(서브뷰)보다 아래에 깔리도록 레이어 안쪽에 넣는다
        (faceLayer ?? layer).insertSublayer(gradient, at: 0)
        reliefLayer = gradient
    }

    private var isDark: Bool { traitCollection.userInterfaceStyle == .dark }

    private var currentThemeColor: ThemeColor {
        let look = theme.appearance(dark: isDark)
        if isHighlighted { return theme.keyColor(role: colorRole, pressed: true, look: look, position: horizontalPosition) }
        if isEmphasized { return theme.keyColor(role: .space, pressed: false, look: look, position: horizontalPosition) }
        return theme.keyColor(role: colorRole, pressed: false, look: look, position: horizontalPosition)
    }

    /// 배경·그림자·외곽선·그라데이션을 현재 상태·라이트/다크에 맞게 칠한다. 레이어는 새로 만들지 않는다.
    private func updateAppearance() {
        let look = theme.appearance(dark: isDark)
        let relief = theme.relief
        let base = currentThemeColor
        let scale = traitCollection.displayScale
        let surface = theme.surfaceColor(base, look: look, tile: tile, scale: scale)

        let textColor = KeyboardTheme.textColor(role: colorRole, in: look).uiColor
        tintColor = textColor
        setTitleColor(textColor, for: .normal)

        // 그림자: blur 가 있으면 번지는 불빛, 없으면 선명한 1pt. 모양은 layoutSubviews 에서 shadowPath 로 알려 준다
        if let color = look.shadow {
            layer.shadowColor = color.uiColor.cgColor
            layer.shadowOpacity = 1
            layer.shadowRadius = CGFloat(look.shadowBlur)
            layer.shadowOffset = CGSize(width: 0, height: look.shadowBlur > 0 ? 0 : 1)
        } else {
            layer.shadowOpacity = 0
        }

        // 외곽선: 오목은 테마 값이 없으면 1pt 밝은 선. 볼록은 윗면에 그린다
        let border = look.border ?? (relief == .dished ? ThemeBorder(color: ThemeColor(white: 1, alpha: isDark ? 0.22 : 0.55), width: 1) : nil)
        let borderTarget = faceLayer ?? layer
        borderTarget.borderWidth = CGFloat(border?.width ?? 0)
        borderTarget.borderColor = border?.color.uiColor.cgColor

        if let faceLayer {
            layer.backgroundColor = base.darkened(by: 0.28).withAlpha(1).uiColor.cgColor
            backgroundColor = nil
            faceLayer.backgroundColor = surface.cgColor
        } else {
            backgroundColor = surface
        }

        switch relief {
        case .flat:
            break
        case .raised:
            reliefLayer?.colors = [ThemeColor(white: 1, alpha: 0.12).uiColor.cgColor, ThemeColor(white: 1, alpha: 0).uiColor.cgColor]
        case .glass:
            reliefLayer?.colors = [ThemeColor(white: 1, alpha: isDark ? 0.35 : 0.6).uiColor.cgColor, ThemeColor(white: 1, alpha: 0).uiColor.cgColor]
            reliefLayer?.isHidden = isHighlighted
        case .dished:
            reliefLayer?.colors = [base.darkened(by: 0.06).uiColor.cgColor, base.lightened(by: 0.06).uiColor.cgColor]
        }
        layoutLayers()
    }

    /// 프레임·모서리를 bounds 에 맞춘다. 키 높이가 바뀔 때(캡슐 반경)와 눌림(볼록 면 위치)에 부른다.
    private func layoutLayers() {
        let height = bounds.height
        let width = bounds.width
        let radius = CGFloat(theme.cornerRadius(forHeight: Double(height)))
        layer.cornerRadius = radius

        var surfaceSize = CGSize(width: width, height: height)
        if let faceLayer {
            let thickness = CGFloat(theme.sideThickness)
            let visible = isHighlighted ? 1 : thickness
            surfaceSize.height = max(0, height - thickness)
            // 눌리면 면이 (두께 - 1)pt 내려와 측면 띠가 1pt 만 남는다
            faceLayer.frame = CGRect(x: 0, y: thickness - visible, width: width, height: surfaceSize.height)
            faceLayer.cornerRadius = theme.keyShape == .capsule ? surfaceSize.height / 2 : radius
        }
        guard let reliefLayer else { return }
        let capsule = theme.keyShape == .capsule
        switch theme.relief {
        case .raised, .glass:
            let fraction: CGFloat = theme.relief == .raised ? 0.25 : 0.35
            if capsule {
                // 알약·원은 위쪽 띠가 모서리 밖으로 나오지 않게 안쪽으로 들여 작은 반사광으로 그린다
                let inset = surfaceSize.height * 0.28
                let h = surfaceSize.height * fraction
                reliefLayer.frame = CGRect(x: inset, y: 2, width: max(0, surfaceSize.width - inset * 2), height: h)
                reliefLayer.cornerRadius = h / 2
                reliefLayer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            } else {
                reliefLayer.frame = CGRect(x: 0, y: 0, width: surfaceSize.width, height: surfaceSize.height * fraction)
                reliefLayer.cornerRadius = faceLayer?.cornerRadius ?? radius
                // 위쪽 띠는 위 모서리만 둥글게(mask 없이 maskedCorners 만 쓴다)
                reliefLayer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            }
        case .dished:
            reliefLayer.frame = CGRect(origin: .zero, size: surfaceSize)
            reliefLayer.cornerRadius = radius
            reliefLayer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        case .flat:
            break
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds != laidOutBounds {
            laidOutBounds = bounds
            layoutLayers()
            // 그림자 모양을 미리 알려 줘야 키마다 offscreen 렌더링을 하지 않는다
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        }
        if faceLayer != nil {
            // 볼록 키의 라벨은 아래 측면 띠를 뺀 윗면 중앙에 둔다
            let shift = CGFloat(theme.sideThickness) / 2
            titleLabel?.center.y -= shift
            imageView?.center.y -= shift
        }
    }

    override var isHighlighted: Bool {
        didSet { if isHighlighted != oldValue { updateAppearance() } }
    }

    /// 켜진 토글(캡스락 등)은 글자 키 색으로 밝게 보인다.
    func setEmphasized(_ on: Bool) {
        isEmphasized = on
        updateAppearance()
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
}
