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

    /// 가로·세로 그라데이션 팔레트용 키 중심 위치 비율(x: 0=왼쪽, y: 0=맨 위 행, 모두 0...1). 컨트롤러가 레이아웃 뒤에 넘긴다.
    private(set) var palettePosition: (x: Double, y: Double)?

    func setPalettePosition(x: Double, y: Double) {
        guard theme.paletteMode != .cycle else { return }
        if let old = palettePosition, old.x == x, old.y == y { return }
        palettePosition = (x, y)
        updateAppearance()
    }

    /// 현재 팔레트 모드에서 보간에 쓸 위치
    private var rampPosition: Double? {
        switch theme.paletteMode {
        case .cycle: nil
        case .horizontal: palettePosition?.x
        case .vertical, .verticalSteps: palettePosition?.y
        }
    }

    /// - Parameter characterIndex: 글자 키 순서(0부터, 키보드 순서). 팔레트·무늬를 고르는 데 쓴다.
    /// - Parameter estimatedPosition: 레이아웃 전에 쓸 위치 추정값(행 수·행 안 순서로 계산). 레이아웃 뒤 실제 값으로 바뀐다.
    init(spec: KeySpec, soundKind: KeySoundPlayer.Kind, theme: KeyboardTheme, characterIndex: Int = 0,
         estimatedPosition: (x: Double, y: Double)? = nil) {
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
        if theme.paletteMode != .cycle { palettePosition = estimatedPosition }

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
        faceLayer?.zPosition = -2
        let gradient = CAGradientLayer()
        gradient.zPosition = -1
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
        if isHighlighted { return theme.keyColor(role: colorRole, pressed: true, look: look, position: rampPosition) }
        if isEmphasized { return theme.keyColor(role: .space, pressed: false, look: look, position: rampPosition) }
        return theme.keyColor(role: colorRole, pressed: false, look: look, position: rampPosition)
    }

    /// 배경·그림자·외곽선·그라데이션을 현재 상태·라이트/다크에 맞게 칠한다. 레이어는 새로 만들지 않는다.
    private func updateAppearance() {
        let look = theme.appearance(dark: isDark)
        let relief = theme.relief
        let base = currentThemeColor
        let scale = traitCollection.displayScale
        let surface = theme.surfaceColor(base, look: look, tile: tile, scale: scale)

        let textColor = KeyboardTheme.textColor(role: colorRole, in: look, keyColor: base).uiColor
        tintColor = textColor
        imageView?.tintColor = textColor
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
            // `backgroundColor = nil` 이 layer.backgroundColor 도 지우므로 먼저 비우고 측면색을 넣는다
            backgroundColor = nil
            layer.backgroundColor = base.darkened(by: 0.28).withAlpha(1).uiColor.cgColor
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

    /// 프레임·모서리를 bounds 에 맞춘다. 반경은 레이어마다 자기 높이·폭으로 따로 계산해 막는다(`clampedRadius`).
    private func layoutLayers() {
        let width = Double(bounds.width), height = Double(bounds.height)
        let capsule = theme.keyShape == .capsule
        layer.cornerRadius = CGFloat(theme.keyRadius(width: width, height: height))
        layer.cornerCurve = .circular

        var surface = (width: width, height: height)
        if let faceLayer {
            let thickness = theme.sideThickness
            let visible = isHighlighted ? 1 : thickness
            surface.height = max(0, height - thickness)
            // 눌리면 면이 (두께 - 1)pt 내려와 측면 띠가 1pt 만 남는다
            faceLayer.frame = CGRect(x: 0, y: thickness - visible, width: width, height: surface.height)
            faceLayer.cornerRadius = CGFloat(theme.keyRadius(width: surface.width, height: surface.height))
            faceLayer.cornerCurve = .circular
        }
        guard let reliefLayer else { return }
        let surfaceRadius = theme.keyRadius(width: surface.width, height: surface.height)
        reliefLayer.cornerCurve = .circular
        switch theme.relief {
        case .raised, .glass:
            let h = surface.height * (theme.relief == .raised ? 0.25 : 0.35)
            // 면의 둥근 모서리 밖으로 하이라이트가 삐져나오지 않게 가로를 모서리 반경만큼 들인다
            let inset = capsule ? surface.height * 0.28 : min(surfaceRadius * 0.6, surface.width / 4)
            let w = max(0, surface.width - inset * 2)
            let y = capsule ? 2.0 : 0.0
            reliefLayer.frame = CGRect(x: inset, y: y, width: w, height: h)
            reliefLayer.cornerRadius = CGFloat(KeyboardTheme.clampedRadius(capsule ? h / 2 : surfaceRadius, width: w, height: h))
            reliefLayer.maskedCorners = capsule
                ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                : [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        case .dished:
            reliefLayer.frame = CGRect(x: 0, y: 0, width: surface.width, height: surface.height)
            reliefLayer.cornerRadius = CGFloat(surfaceRadius)
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
            // 그림자 모양을 미리 알려 줘야 키마다 offscreen 렌더링을 하지 않는다. 반경은 본체 레이어와 같다
            layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        }
    }

    /// 볼록 키는 아래 측면 띠를 뺀 윗면 가운데에 라벨·아이콘을 둔다(레이아웃 뒤에 center 를 옮기지 않고 콘텐츠 영역을 줄인다).
    override func contentRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.contentRect(forBounds: bounds)
        guard faceLayer != nil else { return rect }
        return CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: max(0, rect.height - CGFloat(theme.sideThickness)))
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
        // 아이콘은 항상 템플릿으로 그려 tintColor(글자색)를 따르게 한다
        setImage(symbol.flatMap { UIImage(systemName: $0, withConfiguration: config)?.withRenderingMode(.alwaysTemplate) }, for: .normal)
    }

    private static func isCharacterKey(_ action: KeyAction) -> Bool {
        if case .character = action { return true }
        return false
    }
}
