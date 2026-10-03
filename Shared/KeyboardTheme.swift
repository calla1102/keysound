import Foundation

/// 색 하나(sRGB 0...1). UIKit·SwiftUI 변환은 각 타깃의 `KeyboardTheme+UIKit.swift`·`KeyboardTheme+SwiftUI.swift` 에서 한다.
struct ThemeColor: Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(_ red: Double, _ green: Double, _ blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(white: Double, alpha: Double = 1) {
        self.init(white, white, white, alpha: alpha)
    }

    static let clear = ThemeColor(white: 0, alpha: 0)

    /// 알파는 그대로 두고 밝기만 `amount`(0...1) 비율로 낮춘 색. 눌림 색 계산에 쓴다.
    func darkened(by amount: Double = 0.12) -> ThemeColor {
        let k = 1 - min(max(amount, 0), 1)
        return ThemeColor(red * k, green * k, blue * k, alpha: alpha)
    }

    /// 알파는 그대로 두고 흰색 쪽으로 `amount` 비율만큼 섞은 색.
    func lightened(by amount: Double = 0.15) -> ThemeColor {
        let a = min(max(amount, 0), 1)
        return ThemeColor(red + (1 - red) * a, green + (1 - green) * a, blue + (1 - blue) * a, alpha: alpha)
    }

    /// 대략적인 밝기(0...1)
    var luminance: Double { 0.299 * red + 0.587 * green + 0.114 * blue }

    func withAlpha(_ alpha: Double) -> ThemeColor {
        ThemeColor(red, green, blue, alpha: alpha)
    }

    /// `colors` 를 균등 간격 지점으로 보고 `t`(0...1)에서 선형 보간한 색. 비어 있으면 clear.
    static func interpolate(_ colors: [ThemeColor], at t: Double) -> ThemeColor {
        guard let first = colors.first else { return .clear }
        guard colors.count > 1 else { return first }
        let x = min(max(t, 0), 1) * Double(colors.count - 1)
        let i = min(Int(x), colors.count - 2)
        let f = x - Double(i)
        let a = colors[i], b = colors[i + 1]
        return ThemeColor(
            a.red + (b.red - a.red) * f, a.green + (b.green - a.green) * f,
            a.blue + (b.blue - a.blue) * f, alpha: a.alpha + (b.alpha - a.alpha) * f)
    }

    /// 색상(0...1)·채도·밝기. 알파는 따로 둔다.
    var hsb: (hue: Double, saturation: Double, brightness: Double) {
        let mx = max(red, green, blue), mn = min(red, green, blue)
        let d = mx - mn
        guard d > 0 else { return (0, 0, mx) }
        var h: Double
        if mx == red { h = ((green - blue) / d).truncatingRemainder(dividingBy: 6) }
        else if mx == green { h = (blue - red) / d + 2 }
        else { h = (red - green) / d + 4 }
        h /= 6
        if h < 0 { h += 1 }
        return (h, d / mx, mx)
    }

    init(hue: Double, saturation: Double, brightness: Double, alpha: Double = 1) {
        let h = (hue - hue.rounded(.down)) * 6
        let c = brightness * saturation
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        let (r, g, b): (Double, Double, Double)
        switch Int(h) {
        case 0: (r, g, b) = (c, x, 0)
        case 1: (r, g, b) = (x, c, 0)
        case 2: (r, g, b) = (0, c, x)
        case 3: (r, g, b) = (0, x, c)
        case 4: (r, g, b) = (x, 0, c)
        default: (r, g, b) = (c, 0, x)
        }
        self.init(r + m, g + m, b + m, alpha: alpha)
    }

    /// 다크용: 색상은 두고 밝기만 `brightness` 배로 낮추며, 탁해 보이지 않게 채도를 `saturationBoost` 배(최대 1)로 올린다.
    func dimmed(brightness: Double = 0.55, saturationBoost: Double = 1.15) -> ThemeColor {
        let c = hsb
        return ThemeColor(
            hue: c.hue, saturation: min(1, c.saturation * saturationBoost),
            brightness: c.brightness * brightness, alpha: alpha)
    }

    /// 팔레트·강조 키의 눌림 색: 어둡게 하되, 이미 거의 검정이면 밝게 해 눌림이 보이게 한다.
    func pressedDarkened() -> ThemeColor {
        luminance < 0.15 ? lightened(by: 0.18) : darkened()
    }

    /// 눌렀을 때 색. 밝은 색은 어둡게, 어두운 색은 밝게 하고, 반투명이면 조금 더 짙게(불투명 쪽으로) 한다.
    func pressedVariant() -> ThemeColor {
        let shifted = luminance > 0.4 ? darkened() : lightened()
        return alpha < 1 ? shifted.withAlpha(min(1, alpha + 0.2)) : shifted
    }
}

/// 키 외곽선
struct ThemeBorder: Equatable {
    var color: ThemeColor
    var width: Double
}

/// 키 글꼴 종류. `.pixel` 은 번들 글꼴 Galmuri11(SIL OFL, ThirdParty/galmuri).
enum ThemeFont: Equatable {
    case system
    case pixel

    /// Galmuri11.ttf 의 PostScript 이름(CoreText 로 확인)
    static let pixelFontName = "Galmuri11-Regular"
    /// Galmuri11 은 12px 격자라 1pt = 1px(12pt), 2배 = 24pt 처럼 정수 배여야 비트맵이 번지지 않는다.
    static let pixelBase: Double = 12

    /// 시스템 글꼴 기준 크기(글자 키 22·특수 키 16)에 대응하는 글꼴 크기.
    /// 픽셀은 가장 가까운 정수 배(최소 1배)로 맞춘다 — 22 → 24, 16 → 12(1배)·24(2배) 중 가까운 쪽.
    func size(forSystemSize size: Double) -> Double {
        switch self {
        case .system: size
        case .pixel: Self.pixelBase * max(1, (size / Self.pixelBase).rounded())
        }
    }
}

/// 글자 키에 깔 무늬. 점·체크는 키 색 위에 아주 옅은 농담으로만 보인다.
enum KeyPattern: Equatable {
    case gingham
    case dots
    /// 체크와 점을 번갈아
    case mixed

    enum Tile: Equatable {
        case gingham
        case dots
    }

    /// 글자 키 `index`(0부터, 키보드 순서)에 입힐 무늬. `.alternate` 는 3개마다 하나씩 입히고 mixed 는 번갈아 쓴다.
    func tile(forCharacterIndex index: Int, scope: PatternScope = .alternate) -> Tile? {
        guard index >= 0 else { return nil }
        if scope == .all {
            switch self {
            case .gingham: return .gingham
            case .dots: return .dots
            case .mixed: return index % 2 == 0 ? .gingham : .dots
            }
        }
        guard index % Self.interval == 0 else { return nil }
        switch self {
        case .gingham: return .gingham
        case .dots: return .dots
        case .mixed: return (index / Self.interval) % 2 == 0 ? .gingham : .dots
        }
    }

    static let interval = 3
}

/// `characterKeyPalette` 를 쓰는 방식
enum PaletteMode: Equatable {
    /// 글자 키 순서대로 순환
    case cycle
    /// 키의 가로 위치(0...1)에 따라 팔레트를 선형 보간(왼쪽→오른쪽 그라데이션)
    case horizontal
    /// 키의 세로 위치(0=맨 위 행 ... 1=맨 아래 행)에 따라 보간(위→아래 그라데이션)
    case vertical
}

/// 키 윤곽
enum KeyShape: Equatable {
    /// `cornerRadius` 를 쓴다
    case rounded
    /// 반경 = 키 높이 / 2. 좁은 키는 원, 넓은 키는 알약
    case capsule
}

/// 무늬를 입힐 글자 키 범위
enum PatternScope: Equatable {
    /// 모든 글자 키
    case all
    /// 3개마다 하나씩, 무늬가 둘이면 번갈아
    case alternate
}

/// 키 윗면·옆면의 입체감. 레이어는 키당 최대 1개(그라데이션)만 더한다.
enum KeyRelief: Equatable {
    /// 단색 + 얇은 그림자
    case flat
    /// 볼록: 아래쪽 측면 띠(두께)와 윗부분 옅은 하이라이트
    case raised
    /// 오목: 가운데가 살짝 어둡고 가장자리가 밝은 접시 모양 윗면
    case dished
    /// 반투명 유리·젤리: 키 위쪽 35% 흰 하이라이트(옛 `gloss`)
    case glass
}

/// 프리셋의 라이트 또는 다크 한쪽 값.
struct ThemeAppearance: Equatable {
    var characterKey: ThemeColor
    /// 시프트·백스페이스·전환 등 특수 키
    var functionKey: ThemeColor
    var characterKeyPressed: ThemeColor
    var functionKeyPressed: ThemeColor
    var text: ThemeColor
    /// nil 이면 그림자 없음
    var shadow: ThemeColor?
    /// 그림자 번짐 반경(pt). 0 이면 선명한 1pt 그림자, 0 보다 크면 그 반경으로 번져 백라이트처럼 보인다.
    var shadowBlur: Double
    var border: ThemeBorder?
    /// 비어 있지 않으면 글자 키 색을 키 순서대로 순환한다(`characterKey` 대신)
    var characterKeyPalette: [ThemeColor]
    /// 엔터 키 전용 색. nil 이면 `functionKey`
    var accentKey: ThemeColor?
    /// 특수 키·엔터 키 글자색. nil 이면 `text`(색이 `text` 와 대비가 안 되는 프리셋만 지정)
    var functionKeyText: ThemeColor?
    var accentKeyText: ThemeColor?
    /// 글자 키 색의 밝기가 0.5 미만일 때만 쓰는 글자색(팔레트 색마다 대비를 자동으로 고른다). nil 이면 항상 `text`.
    var textOnDarkKey: ThemeColor?

    init(
        characterKey: ThemeColor,
        functionKey: ThemeColor,
        characterKeyPressed: ThemeColor? = nil,
        functionKeyPressed: ThemeColor? = nil,
        text: ThemeColor,
        shadow: ThemeColor?,
        shadowBlur: Double = 0,
        border: ThemeBorder? = nil,
        characterKeyPalette: [ThemeColor] = [],
        accentKey: ThemeColor? = nil,
        functionKeyText: ThemeColor? = nil,
        accentKeyText: ThemeColor? = nil,
        textOnDarkKey: ThemeColor? = nil
    ) {
        self.characterKey = characterKey
        self.functionKey = functionKey
        self.characterKeyPressed = characterKeyPressed ?? characterKey.pressedVariant()
        self.functionKeyPressed = functionKeyPressed ?? functionKey.pressedVariant()
        self.text = text
        self.shadow = shadow
        self.shadowBlur = shadowBlur
        self.border = border
        self.characterKeyPalette = characterKeyPalette
        self.accentKey = accentKey
        self.functionKeyText = functionKeyText
        self.accentKeyText = accentKeyText
        self.textOnDarkKey = textOnDarkKey
    }

    /// 글자 키 `index` 번째의 색. 팔레트가 있으면 순환한다.
    func characterColor(at index: Int) -> ThemeColor {
        guard !characterKeyPalette.isEmpty else { return characterKey }
        let n = characterKeyPalette.count
        return characterKeyPalette[((index % n) + n) % n]
    }

    /// 글자 키 `index` 번째의 눌림 색. 팔레트 색은 그 색을 어둡게 한 값이다.
    func characterPressedColor(at index: Int) -> ThemeColor {
        characterKeyPalette.isEmpty ? characterKeyPressed : characterColor(at: index).pressedDarkened()
    }

    var enterKey: ThemeColor { accentKey ?? functionKey }
    var enterKeyPressed: ThemeColor { accentKey?.pressedDarkened() ?? functionKeyPressed }
    var functionText: ThemeColor { functionKeyText ?? text }
    var enterText: ThemeColor { accentKeyText ?? functionKeyText ?? text }
}

/// 키보드에서 고를 수 있는 자판 디자인 프리셋. rawValue(고유 id)가 App Group 에 저장된다.
/// 새 프리셋은 case 와 `displayName`·`summary`·`cornerRadius`·`lightAppearance`·`darkAppearance` 를 추가한다.
/// 옛 프리셋(charcoal·vintage·pastel) 값이 저장돼 있어도 `init(storedValue:)` 가 기본으로 되돌린다.
enum KeyboardTheme: String, CaseIterable, Identifiable {
    /// 현재 iOS 기본 키보드와 비슷한 색
    case classic
    case milk
    case matcha
    case strawberry
    case blueberry
    case toast
    case retro
    case mono
    case pixel
    case crystal
    case soda
    case outline
    case toffee
    case sherbet
    case rainbow
    case cottonCandy
    case roseTypewriter
    case slateTypewriter
    case biscuit
    case chocolate
    case nightSky
    case aurora
    case primaryBlocks
    case neonViolet
    case brass
    case pearl

    static let `default`: KeyboardTheme = .classic

    var id: String { rawValue }

    /// 저장되지 않았거나 알 수 없는 값이면 기본 프리셋
    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .default
    }

    var displayName: String {
        switch self {
        case .classic: "기본"
        case .milk: "우유"
        case .matcha: "말차"
        case .strawberry: "딸기우유"
        case .blueberry: "블루베리"
        case .toast: "토스트"
        case .retro: "레트로"
        case .mono: "모노"
        case .pixel: "픽셀"
        case .crystal: "크리스탈"
        case .soda: "소다"
        case .outline: "라인"
        case .toffee: "토피"
        case .sherbet: "셔벗"
        case .rainbow: "무지개"
        case .cottonCandy: "솜사탕"
        case .roseTypewriter: "분홍 타자기"
        case .slateTypewriter: "청회 타자기"
        case .biscuit: "비스킷"
        case .chocolate: "초콜릿"
        case .nightSky: "밤하늘"
        case .aurora: "오로라"
        case .primaryBlocks: "원색 블록"
        case .neonViolet: "네온 보라"
        case .brass: "놋쇠"
        case .pearl: "진주"
        }
    }

    var summary: String {
        switch self {
        case .classic: "시스템 키보드와 어우러지는 기본 색"
        case .milk: "크림색 키에 웜그레이 특수 키"
        case .matcha: "크림색 키에 세이지 그린, 진한 녹색 엔터"
        case .strawberry: "연분홍 키에 딸기 빨강 특수 키"
        case .blueberry: "흰 키에 연한 하늘색, 진한 파랑 엔터"
        case .toast: "연한 베이지 키에 주황빛 갈색 특수 키"
        case .retro: "베이지와 회색 두 톤의 각진 구형 키보드"
        case .mono: "흑백 두 색, 다크 모드에서는 반전"
        case .pixel: "도트 글꼴과 체크·점 무늬 키"
        case .crystal: "반투명 흰 유리에 연분홍 특수 키"
        case .soda: "비치는 하늘색 젤리 키"
        case .outline: "흰 키에 검은 선만 그린 간결한 모양"
        case .toffee: "크림·분홍·모카 색이 번갈아 나오는 둥근 키"
        case .sherbet: "크림노랑·연두·살구·하늘색이 번갈아 나오는 오목한 키"
        case .rainbow: "민트에서 하늘색까지 왼쪽에서 오른쪽으로 흐르는 파스텔 키"
        case .cottonCandy: "분홍·흰·하늘색이 번지는 알약 모양 키"
        case .roseTypewriter: "비치는 분홍 유리 알약 키"
        case .slateTypewriter: "청회색 타자기 키에 따뜻한 불빛이 번지는 모양"
        case .biscuit: "점 구멍이 난 황갈색 비스킷 키"
        case .chocolate: "크림색 키에 진한 초콜릿색 특수 키"
        case .nightSky: "위에서 아래로 남색에서 보라로 깊어지는 별 무늬 키"
        case .aurora: "분홍·라벤더·하늘색이 비치며 번지는 유리 키"
        case .primaryBlocks: "흰 블록에 빨강·파랑·노랑이 섞인 각진 키"
        case .neonViolet: "검은 키에 보라 네온 글자와 빛 번짐"
        case .brass: "올리브 베이지 키에 짙은 갈색 특수 키"
        case .pearl: "진주처럼 은은하게 비치는 흰 유리 키"
        }
    }

    func appearance(dark: Bool) -> ThemeAppearance {
        dark ? darkAppearance : lightAppearance
    }
}

/// 키 색을 고르는 기준. 스페이스는 특수 키가 아니라 글자 키 색을 쓰되 팔레트 순환은 따르지 않는다.
enum KeyColorRole: Equatable {
    case character(index: Int)
    case space
    case function
    case enter
}

extension KeyboardTheme {
    /// 키 색. `position` 은 팔레트 보간 위치(0...1)다. `.horizontal` 이면 키 중심 x 비율, `.vertical` 이면 y 비율이며
    /// 순환 팔레트에서는 쓰지 않는다(모르면 0.5).
    func keyColor(role: KeyColorRole, pressed: Bool, look: ThemeAppearance, position: Double? = nil) -> ThemeColor {
        if paletteMode != .cycle, !look.characterKeyPalette.isEmpty {
            let ramp = ThemeColor.interpolate(look.characterKeyPalette, at: position ?? 0.5)
            let base: ThemeColor
            switch role {
            case .character, .space: base = ramp
            case .function: base = ramp.darkened(by: 0.08)
            case .enter: base = look.accentKey ?? ramp.darkened(by: 0.08)
            }
            return pressed ? base.pressedDarkened() : base
        }
        switch role {
        case .character(let index):
            return pressed ? look.characterPressedColor(at: index) : look.characterColor(at: index)
        case .space: return pressed ? look.characterKeyPressed : look.characterKey
        case .function: return pressed ? look.functionKeyPressed : look.functionKey
        case .enter: return pressed ? look.enterKeyPressed : look.enterKey
        }
    }

    /// 글자색. `keyColor` 를 주면 `textOnDarkKey` 가 있는 프리셋은 어두운 키에서 그 색으로 바꾼다.
    static func textColor(role: KeyColorRole, in look: ThemeAppearance, keyColor: ThemeColor? = nil) -> ThemeColor {
        switch role {
        case .character, .space:
            if let dark = look.textOnDarkKey, let keyColor, keyColor.luminance < 0.5 { dark } else { look.text }
        case .function: look.functionText
        case .enter: look.enterText
        }
    }

    /// 키 높이에 대한 모서리 반경. 캡슐은 높이의 절반.
    func cornerRadius(forHeight height: Double) -> Double {
        keyShape == .capsule ? height / 2 : cornerRadius
    }
}
