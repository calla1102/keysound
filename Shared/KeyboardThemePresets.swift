import Foundation

/// 프리셋별 값(모양·색). `KeyboardTheme` 본체(KeyboardTheme.swift)는 종류·이름·저장값 폴백만 맡고,
/// 프리셋을 추가할 때 이 파일의 switch 들에 case 를 더한다(빠뜨리면 컴파일 에러).
extension KeyboardTheme {
    /// 키 모서리 반경(pt). 라이트·다크 공통. `keyShape == .capsule` 이면 쓰지 않는다.
    var cornerRadius: Double {
        switch self {
        case .classic: 5
        case .milk: 7
        case .matcha: 7
        case .strawberry: 7
        case .blueberry: 8
        case .toast: 6
        case .retro: 3
        case .mono: 5
        case .pixel: 4
        case .crystal: 9
        case .soda: 12
        case .outline: 10
        case .toffee: 13
        case .sherbet: 11
        case .chocolate: 7
        case .nightSky: 6
        case .aurora: 9
        case .primaryBlocks: 2
        case .neonViolet: 6
        case .brass: 4
        case .pearl: 8
        case .navy: 6
        case .pastelStripes: 8
        case .creamTypewriter: 12
        case .forest: 7
        case .lavender: 9
        case .rainbow: 8
        case .cottonCandy: 12
        case .roseTypewriter: 12
        case .slateTypewriter: 12
        case .biscuit: 7
        }
    }

    var keyShape: KeyShape {
        switch self {
        case .cottonCandy, .roseTypewriter, .slateTypewriter, .creamTypewriter: .capsule
        default: .rounded
        }
    }

    var font: ThemeFont {
        self == .pixel ? .pixel : .system
    }

    var keyPattern: KeyPattern? {
        switch self {
        case .pixel: .mixed
        case .biscuit, .nightSky: .dots
        default: nil
        }
    }

    var patternScope: PatternScope {
        (self == .biscuit || self == .nightSky) ? .all : .alternate
    }

    /// 무늬 농담(alpha). nil 이면 무늬 기본값(체크 0.08·점 0.10)
    var patternInkAlpha: Double? {
        switch self {
        case .biscuit: 0.15
        case .nightSky: 0.35
        default: nil
        }
    }

    var paletteMode: PaletteMode {
        switch self {
        case .rainbow, .cottonCandy, .aurora, .pearl: .horizontal
        case .nightSky: .vertical
        case .pastelStripes: .verticalSteps
        default: .cycle
        }
    }

    var relief: KeyRelief {
        switch self {
        case .milk, .toast, .toffee, .retro, .mono, .rainbow, .slateTypewriter, .biscuit, .chocolate, .brass, .creamTypewriter, .forest: .raised
        case .matcha, .strawberry, .blueberry, .sherbet, .cottonCandy, .pastelStripes, .lavender: .dished
        case .crystal, .soda, .roseTypewriter, .aurora, .pearl: .glass
        case .classic, .pixel, .outline, .nightSky, .primaryBlocks, .neonViolet, .navy: .flat
        }
    }

    /// `.raised` 측면 띠 두께(pt). 레트로는 두껍게.
    var sideThickness: Double {
        self == .retro ? 4 : 3
    }

    static let cottonCandyStops: [ThemeColor] = [
        ThemeColor(1.0, 0.82, 0.88), ThemeColor(0.99, 0.98, 1.0), ThemeColor(0.80, 0.91, 0.99),
    ]

    static let sherbetStops: [ThemeColor] = [
        ThemeColor(1.0, 0.96, 0.78), ThemeColor(0.84, 0.95, 0.76), ThemeColor(1.0, 0.85, 0.74), ThemeColor(0.80, 0.91, 0.98),
    ]

    static let nightSkyStops: [ThemeColor] = [
        ThemeColor(0.10, 0.12, 0.30), ThemeColor(0.22, 0.14, 0.40), ThemeColor(0.36, 0.20, 0.50),
    ]

    static let auroraStops: [ThemeColor] = [
        ThemeColor(1.0, 0.70, 0.85, alpha: 0.6), ThemeColor(0.78, 0.68, 0.98, alpha: 0.6), ThemeColor(0.65, 0.85, 1.0, alpha: 0.6),
    ]

    static let pearlStops: [ThemeColor] = [
        ThemeColor(1.0, 0.96, 0.97, alpha: 0.75), ThemeColor(1, 1, 1, alpha: 0.75), ThemeColor(0.95, 0.97, 1.0, alpha: 0.75),
    ]

    static let pearlDarkStops: [ThemeColor] = [
        ThemeColor(0.50, 0.46, 0.50, alpha: 0.6), ThemeColor(0.48, 0.48, 0.52, alpha: 0.6), ThemeColor(0.44, 0.48, 0.55, alpha: 0.6),
    ]

    /// 원색 블록 팔레트: `base`(흰 또는 검정) 사이사이에 빨강·파랑·노랑 키(순환 11칸)
    static func primaryBlocksPalette(base: ThemeColor) -> [ThemeColor] {
        let red = ThemeColor(0.85, 0.15, 0.15), blue = ThemeColor(0.15, 0.30, 0.75), yellow = ThemeColor(0.98, 0.82, 0.15)
        return [base, base, base, red, base, base, blue, base, yellow, base, base]
    }

    static let pastelStripeStops: [ThemeColor] = [
        ThemeColor(1.0, 0.80, 0.86), ThemeColor(0.82, 0.94, 0.76), ThemeColor(0.78, 0.90, 1.0), ThemeColor(0.86, 0.80, 0.98),
    ]

    /// 민트→연두→살구→분홍→라벤더→연하늘
    static let rainbowStops: [ThemeColor] = [
        ThemeColor(0.70, 0.92, 0.82),
        ThemeColor(0.82, 0.93, 0.70),
        ThemeColor(1.0, 0.83, 0.68),
        ThemeColor(1.0, 0.76, 0.84),
        ThemeColor(0.82, 0.76, 0.96),
        ThemeColor(0.72, 0.86, 0.98),
    ]

    var lightAppearance: ThemeAppearance {
        switch self {
        case .classic:
            ThemeAppearance(
                characterKey: ThemeColor(white: 1),
                functionKey: ThemeColor(0.67, 0.70, 0.74),
                characterKeyPressed: ThemeColor(0.67, 0.70, 0.74),
                functionKeyPressed: ThemeColor(white: 1),
                text: ThemeColor(white: 0),
                shadow: ThemeColor(white: 0, alpha: 0.3))
        case .milk:
            ThemeAppearance(
                characterKey: ThemeColor(0.99, 0.97, 0.92),
                functionKey: ThemeColor(0.78, 0.74, 0.70),
                text: ThemeColor(0.28, 0.24, 0.21),
                shadow: ThemeColor(0.40, 0.35, 0.30, alpha: 0.30))
        case .matcha:
            ThemeAppearance(
                characterKey: ThemeColor(0.98, 0.97, 0.90),
                functionKey: ThemeColor(0.67, 0.76, 0.62),
                text: ThemeColor(0.20, 0.27, 0.20),
                shadow: ThemeColor(0.20, 0.30, 0.20, alpha: 0.30),
                accentKey: ThemeColor(0.30, 0.48, 0.31),
                accentKeyText: ThemeColor(white: 1))
        case .strawberry:
            ThemeAppearance(
                characterKey: ThemeColor(1.0, 0.93, 0.94),
                functionKey: ThemeColor(0.90, 0.65, 0.68),
                text: ThemeColor(0.42, 0.20, 0.24),
                shadow: ThemeColor(0.50, 0.25, 0.28, alpha: 0.28),
                accentKey: ThemeColor(0.80, 0.30, 0.36),
                accentKeyText: ThemeColor(white: 1))
        case .blueberry:
            ThemeAppearance(
                characterKey: ThemeColor(0.98, 0.98, 0.96),
                functionKey: ThemeColor(0.72, 0.84, 0.95),
                text: ThemeColor(0.17, 0.22, 0.35),
                shadow: ThemeColor(0.20, 0.30, 0.50, alpha: 0.28),
                accentKey: ThemeColor(0.20, 0.38, 0.75),
                accentKeyText: ThemeColor(white: 1))
        case .toast:
            ThemeAppearance(
                characterKey: ThemeColor(0.98, 0.94, 0.86),
                functionKey: ThemeColor(0.80, 0.55, 0.34),
                text: ThemeColor(0.34, 0.22, 0.12),
                shadow: ThemeColor(0.40, 0.25, 0.12, alpha: 0.32))
        case .retro:
            ThemeAppearance(
                characterKey: ThemeColor(0.86, 0.83, 0.76),
                functionKey: ThemeColor(0.62, 0.62, 0.62),
                text: ThemeColor(0.20, 0.20, 0.20),
                shadow: ThemeColor(white: 0, alpha: 0.55))
        case .mono:
            ThemeAppearance(
                characterKey: ThemeColor(white: 1),
                functionKey: ThemeColor(white: 0.08),
                text: ThemeColor(white: 0),
                shadow: ThemeColor(white: 0, alpha: 0.3),
                functionKeyText: ThemeColor(white: 1))
        case .pixel:
            ThemeAppearance(
                characterKey: ThemeColor(white: 1),
                functionKey: ThemeColor(white: 0.85),
                text: ThemeColor(white: 0),
                shadow: ThemeColor(white: 0, alpha: 0.3),
                border: ThemeBorder(color: ThemeColor(white: 0.62), width: 1))
        case .crystal:
            ThemeAppearance(
                characterKey: ThemeColor(white: 1, alpha: 0.55),
                functionKey: ThemeColor(1.0, 0.80, 0.88, alpha: 0.55),
                text: ThemeColor(0.25, 0.25, 0.35),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1, alpha: 0.85), width: 0.75))
        case .soda:
            ThemeAppearance(
                characterKey: ThemeColor(0.55, 0.82, 0.98, alpha: 0.55),
                functionKey: ThemeColor(0.35, 0.65, 0.92, alpha: 0.60),
                text: ThemeColor(0.10, 0.25, 0.40),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1, alpha: 0.6), width: 0.75))
        case .outline:
            ThemeAppearance(
                characterKey: ThemeColor(white: 1),
                functionKey: ThemeColor(white: 0.93),
                text: ThemeColor(white: 0),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 0), width: 1.5))
        case .toffee:
            ThemeAppearance(
                characterKey: ThemeColor(0.99, 0.95, 0.86),
                functionKey: ThemeColor(0.65, 0.47, 0.35),
                text: ThemeColor(0.25, 0.15, 0.10),
                shadow: ThemeColor(0.35, 0.22, 0.14, alpha: 0.30),
                characterKeyPalette: [
                    ThemeColor(0.99, 0.95, 0.86),
                    ThemeColor(0.98, 0.82, 0.85),
                    ThemeColor(0.85, 0.70, 0.58),
                ])
        case .sherbet:
            ThemeAppearance(
                characterKey: ThemeColor(1.0, 0.96, 0.78),
                functionKey: ThemeColor(0.98, 0.84, 0.72),
                text: ThemeColor(0.30, 0.18, 0.10),
                shadow: ThemeColor(0.40, 0.28, 0.15, alpha: 0.25),
                characterKeyPalette: Self.sherbetStops)
        case .rainbow:
            ThemeAppearance(
                characterKey: Self.rainbowStops[0],
                functionKey: Self.rainbowStops[2],
                text: ThemeColor(white: 1),
                shadow: ThemeColor(0.30, 0.30, 0.40, alpha: 0.25),
                characterKeyPalette: Self.rainbowStops)
        case .cottonCandy:
            ThemeAppearance(
                characterKey: Self.cottonCandyStops[0],
                functionKey: Self.cottonCandyStops[2],
                text: ThemeColor(0.45, 0.45, 0.50),
                shadow: ThemeColor(0.40, 0.40, 0.50, alpha: 0.20),
                characterKeyPalette: Self.cottonCandyStops)
        case .roseTypewriter:
            ThemeAppearance(
                characterKey: ThemeColor(1.0, 0.72, 0.82, alpha: 0.70),
                functionKey: ThemeColor(1.0, 0.62, 0.76, alpha: 0.75),
                text: ThemeColor(0.30, 0.17, 0.12),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(0.95, 0.55, 0.70), width: 1.5))
        case .slateTypewriter:
            ThemeAppearance(
                characterKey: ThemeColor(0.38, 0.47, 0.55),
                functionKey: ThemeColor(0.30, 0.38, 0.46),
                text: ThemeColor(0.98, 0.94, 0.82),
                shadow: ThemeColor(1.0, 0.88, 0.55, alpha: 0.45),
                shadowBlur: 6)
        case .biscuit:
            ThemeAppearance(
                characterKey: ThemeColor(0.90, 0.74, 0.50),
                functionKey: ThemeColor(0.82, 0.62, 0.38),
                text: ThemeColor(0.30, 0.17, 0.08),
                shadow: ThemeColor(0.35, 0.20, 0.08, alpha: 0.30),
                border: ThemeBorder(color: ThemeColor(0.50, 0.30, 0.14), width: 1.5))
        case .chocolate:
            ThemeAppearance(
                characterKey: ThemeColor(0.97, 0.93, 0.85),
                functionKey: ThemeColor(0.30, 0.20, 0.15),
                text: ThemeColor(0.25, 0.15, 0.10),
                shadow: ThemeColor(0.25, 0.15, 0.10, alpha: 0.30),
                functionKeyText: ThemeColor(0.97, 0.93, 0.85))
        case .nightSky:
            // 라이트는 아주 조금 밝게. 점 무늬는 글자색(흰색) 기준이라 별처럼 보인다
            ThemeAppearance(
                characterKey: Self.nightSkyStops[0],
                functionKey: Self.nightSkyStops[0].darkened(by: 0.08),
                text: ThemeColor(white: 1),
                shadow: nil,
                characterKeyPalette: Self.nightSkyStops.map { $0.lightened(by: 0.05) })
        case .aurora:
            ThemeAppearance(
                characterKey: Self.auroraStops[0],
                functionKey: Self.auroraStops[1],
                text: ThemeColor(0.30, 0.25, 0.45),
                shadow: nil,
                characterKeyPalette: Self.auroraStops)
        case .primaryBlocks:
            ThemeAppearance(
                characterKey: ThemeColor(white: 1),
                functionKey: ThemeColor(white: 0.90),
                text: ThemeColor(white: 0),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 0), width: 1.5),
                characterKeyPalette: Self.primaryBlocksPalette(base: ThemeColor(white: 1)),
                functionKeyText: ThemeColor(white: 0),
                textOnDarkKey: ThemeColor(white: 1))
        case .neonViolet:
            ThemeAppearance(
                characterKey: ThemeColor(0.10, 0.08, 0.14),
                functionKey: ThemeColor(0.16, 0.12, 0.22),
                text: ThemeColor(0.78, 0.55, 1.0),
                shadow: ThemeColor(0.60, 0.30, 1.0, alpha: 0.55),
                shadowBlur: 6)
        case .brass:
            ThemeAppearance(
                characterKey: ThemeColor(0.78, 0.72, 0.55),
                functionKey: ThemeColor(0.40, 0.32, 0.22),
                text: ThemeColor(0.25, 0.18, 0.10),
                shadow: ThemeColor(0.20, 0.14, 0.06, alpha: 0.50),
                functionKeyText: ThemeColor(0.78, 0.72, 0.55))
        case .pearl:
            ThemeAppearance(
                characterKey: Self.pearlStops[1],
                functionKey: Self.pearlStops[0],
                text: ThemeColor(0.40, 0.40, 0.48),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1, alpha: 0.9), width: 0.75),
                characterKeyPalette: Self.pearlStops)
        case .navy:
            ThemeAppearance(
                characterKey: ThemeColor(0.13, 0.20, 0.38),
                functionKey: ThemeColor(0.09, 0.14, 0.28),
                text: ThemeColor(white: 1),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                accentKey: ThemeColor(0.25, 0.55, 0.95),
                accentKeyText: ThemeColor(white: 1))
        case .pastelStripes:
            ThemeAppearance(
                characterKey: Self.pastelStripeStops[0],
                functionKey: Self.pastelStripeStops[0].darkened(by: 0.08),
                text: ThemeColor(0.35, 0.30, 0.40),
                shadow: ThemeColor(0.30, 0.25, 0.35, alpha: 0.22),
                characterKeyPalette: Self.pastelStripeStops)
        case .creamTypewriter:
            ThemeAppearance(
                characterKey: ThemeColor(0.93, 0.88, 0.78),
                functionKey: ThemeColor(0.80, 0.72, 0.60),
                text: ThemeColor(0.30, 0.22, 0.14),
                shadow: ThemeColor(0.30, 0.20, 0.10, alpha: 0.35))
        case .forest:
            ThemeAppearance(
                characterKey: ThemeColor(0.97, 0.95, 0.88),
                functionKey: ThemeColor(0.40, 0.55, 0.40),
                text: ThemeColor(0.20, 0.25, 0.18),
                shadow: ThemeColor(0.15, 0.25, 0.15, alpha: 0.30),
                accentKey: ThemeColor(0.45, 0.32, 0.22),
                functionKeyText: ThemeColor(0.97, 0.95, 0.88),
                accentKeyText: ThemeColor(0.97, 0.95, 0.88))
        case .lavender:
            ThemeAppearance(
                characterKey: ThemeColor(0.80, 0.74, 0.96),
                functionKey: ThemeColor(0.55, 0.45, 0.80),
                text: ThemeColor(white: 1),
                shadow: ThemeColor(0.30, 0.20, 0.50, alpha: 0.25),
                functionKeyText: ThemeColor(white: 1))
        }
    }

    var darkAppearance: ThemeAppearance {
        switch self {
        case .classic:
            ThemeAppearance(
                characterKey: ThemeColor(white: 0.42),
                functionKey: ThemeColor(white: 0.27),
                characterKeyPressed: ThemeColor(white: 0.27),
                functionKeyPressed: ThemeColor(white: 0.42),
                text: ThemeColor(white: 1),
                shadow: ThemeColor(white: 0, alpha: 0.3))
        case .milk:
            ThemeAppearance(
                characterKey: ThemeColor(0.40, 0.37, 0.34),
                functionKey: ThemeColor(0.26, 0.24, 0.22),
                text: ThemeColor(0.95, 0.92, 0.86),
                shadow: ThemeColor(white: 0, alpha: 0.4))
        case .matcha:
            ThemeAppearance(
                characterKey: ThemeColor(0.33, 0.37, 0.31),
                functionKey: ThemeColor(0.22, 0.28, 0.22),
                text: ThemeColor(0.92, 0.95, 0.88),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                accentKey: ThemeColor(0.42, 0.62, 0.42),
                accentKeyText: ThemeColor(0.06, 0.12, 0.06))
        case .strawberry:
            ThemeAppearance(
                characterKey: ThemeColor(0.45, 0.30, 0.33),
                functionKey: ThemeColor(0.34, 0.20, 0.23),
                text: ThemeColor(1.0, 0.90, 0.92),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                accentKey: ThemeColor(0.75, 0.32, 0.38),
                accentKeyText: ThemeColor(white: 1))
        case .blueberry:
            ThemeAppearance(
                characterKey: ThemeColor(0.30, 0.34, 0.44),
                functionKey: ThemeColor(0.20, 0.25, 0.36),
                text: ThemeColor(0.92, 0.94, 1.0),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                accentKey: ThemeColor(0.35, 0.55, 0.95),
                accentKeyText: ThemeColor(white: 1))
        case .toast:
            ThemeAppearance(
                characterKey: ThemeColor(0.42, 0.34, 0.26),
                functionKey: ThemeColor(0.55, 0.36, 0.20),
                text: ThemeColor(0.97, 0.92, 0.83),
                shadow: ThemeColor(white: 0, alpha: 0.4))
        case .retro:
            ThemeAppearance(
                characterKey: ThemeColor(0.45, 0.43, 0.38),
                functionKey: ThemeColor(0.30, 0.30, 0.30),
                text: ThemeColor(0.95, 0.93, 0.88),
                shadow: ThemeColor(white: 0, alpha: 0.6))
        case .mono:
            ThemeAppearance(
                characterKey: ThemeColor(white: 0.08),
                functionKey: ThemeColor(white: 0.92),
                text: ThemeColor(white: 1),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1, alpha: 0.35), width: 1),
                functionKeyText: ThemeColor(white: 0))
        case .pixel:
            ThemeAppearance(
                characterKey: ThemeColor(white: 0.08),
                functionKey: ThemeColor(white: 0.25),
                text: ThemeColor(white: 1),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                border: ThemeBorder(color: ThemeColor(white: 0.55), width: 1))
        case .crystal:
            ThemeAppearance(
                characterKey: ThemeColor(0.20, 0.20, 0.26, alpha: 0.55),
                functionKey: ThemeColor(0.50, 0.25, 0.35, alpha: 0.55),
                text: ThemeColor(white: 1),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1, alpha: 0.30), width: 0.75))
        case .soda:
            ThemeAppearance(
                characterKey: ThemeColor(0.15, 0.35, 0.55, alpha: 0.60),
                functionKey: ThemeColor(0.10, 0.25, 0.45, alpha: 0.65),
                text: ThemeColor(0.88, 0.96, 1.0),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1, alpha: 0.25), width: 0.75))
        case .outline:
            ThemeAppearance(
                characterKey: ThemeColor(white: 0.05),
                functionKey: ThemeColor(white: 0.18),
                text: ThemeColor(white: 1),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1), width: 1.5))
        case .toffee:
            ThemeAppearance(
                characterKey: ThemeColor(0.45, 0.38, 0.32),
                functionKey: ThemeColor(0.28, 0.20, 0.16),
                text: ThemeColor(0.98, 0.92, 0.85),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                characterKeyPalette: [
                    ThemeColor(0.45, 0.38, 0.32),
                    ThemeColor(0.50, 0.33, 0.37),
                    ThemeColor(0.40, 0.29, 0.23),
                ])
        case .sherbet:
            ThemeAppearance(
                characterKey: Self.sherbetStops[0].dimmed(),
                functionKey: ThemeColor(0.98, 0.84, 0.72).dimmed(),
                text: ThemeColor(1.0, 0.95, 0.88),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                characterKeyPalette: Self.sherbetStops.map { $0.dimmed() })
        case .rainbow:
            // HSB 로 색상은 두고 밝기만 낮추며 채도를 조금 올려 탁해지지 않게 한다
            ThemeAppearance(
                characterKey: Self.rainbowStops[0].dimmed(),
                functionKey: Self.rainbowStops[2].dimmed(),
                text: ThemeColor(white: 1),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                characterKeyPalette: Self.rainbowStops.map { $0.dimmed() })
        case .cottonCandy:
            ThemeAppearance(
                characterKey: Self.cottonCandyStops[0].dimmed(),
                functionKey: Self.cottonCandyStops[2].dimmed(),
                text: ThemeColor(0.92, 0.92, 0.96),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                characterKeyPalette: Self.cottonCandyStops.map { $0.dimmed() })
        case .roseTypewriter:
            ThemeAppearance(
                characterKey: ThemeColor(0.55, 0.25, 0.38, alpha: 0.70),
                functionKey: ThemeColor(0.62, 0.22, 0.38, alpha: 0.75),
                text: ThemeColor(1.0, 0.92, 0.86),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(0.85, 0.45, 0.62), width: 1.5))
        case .slateTypewriter:
            // 키 색은 라이트와 같고, 어두운 배경에서 번짐이 더 보이게 알파만 올린다
            ThemeAppearance(
                characterKey: ThemeColor(0.38, 0.47, 0.55),
                functionKey: ThemeColor(0.30, 0.38, 0.46),
                text: ThemeColor(0.98, 0.94, 0.82),
                shadow: ThemeColor(1.0, 0.88, 0.55, alpha: 0.80),
                shadowBlur: 6)
        case .biscuit:
            ThemeAppearance(
                characterKey: ThemeColor(0.58, 0.43, 0.26),
                functionKey: ThemeColor(0.46, 0.32, 0.18),
                text: ThemeColor(0.98, 0.90, 0.75),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                border: ThemeBorder(color: ThemeColor(0.25, 0.14, 0.06), width: 1.5))
        case .chocolate:
            ThemeAppearance(
                characterKey: ThemeColor(0.36, 0.26, 0.20),
                functionKey: ThemeColor(0.22, 0.14, 0.10),
                text: ThemeColor(0.97, 0.93, 0.85),
                shadow: ThemeColor(white: 0, alpha: 0.4))
        case .nightSky:
            ThemeAppearance(
                characterKey: Self.nightSkyStops[0],
                functionKey: Self.nightSkyStops[0].darkened(by: 0.08),
                text: ThemeColor(white: 1),
                shadow: nil,
                characterKeyPalette: Self.nightSkyStops)
        case .aurora:
            ThemeAppearance(
                characterKey: Self.auroraStops[0].dimmed().withAlpha(0.65),
                functionKey: Self.auroraStops[1].dimmed().withAlpha(0.65),
                text: ThemeColor(0.92, 0.90, 1.0),
                shadow: nil,
                characterKeyPalette: Self.auroraStops.map { $0.dimmed().withAlpha(0.65) })
        case .primaryBlocks:
            // 키는 검정·외곽선은 흰색, 원색은 그대로. 글자는 키 밝기로 자동 대비
            ThemeAppearance(
                characterKey: ThemeColor(white: 0),
                functionKey: ThemeColor(white: 0.20),
                text: ThemeColor(white: 0),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1), width: 1.5),
                characterKeyPalette: Self.primaryBlocksPalette(base: ThemeColor(white: 0)),
                functionKeyText: ThemeColor(white: 1),
                textOnDarkKey: ThemeColor(white: 1))
        case .neonViolet:
            ThemeAppearance(
                characterKey: ThemeColor(0.10, 0.08, 0.14),
                functionKey: ThemeColor(0.16, 0.12, 0.22),
                text: ThemeColor(0.78, 0.55, 1.0),
                shadow: ThemeColor(0.60, 0.30, 1.0, alpha: 0.85),
                shadowBlur: 6)
        case .brass:
            ThemeAppearance(
                characterKey: ThemeColor(0.40, 0.36, 0.26),
                functionKey: ThemeColor(0.22, 0.17, 0.11),
                text: ThemeColor(0.92, 0.85, 0.68),
                shadow: ThemeColor(white: 0, alpha: 0.5),
                functionKeyText: ThemeColor(0.92, 0.85, 0.68))
        case .pearl:
            ThemeAppearance(
                characterKey: Self.pearlDarkStops[1],
                functionKey: Self.pearlDarkStops[0],
                text: ThemeColor(0.92, 0.92, 0.96),
                shadow: nil,
                border: ThemeBorder(color: ThemeColor(white: 1, alpha: 0.35), width: 0.75),
                characterKeyPalette: Self.pearlDarkStops)
        case .navy:
            ThemeAppearance(
                characterKey: ThemeColor(0.10, 0.16, 0.32),
                functionKey: ThemeColor(0.07, 0.11, 0.23),
                text: ThemeColor(white: 1),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                accentKey: ThemeColor(0.25, 0.55, 0.95),
                accentKeyText: ThemeColor(white: 1))
        case .pastelStripes:
            ThemeAppearance(
                characterKey: Self.pastelStripeStops[0].dimmed(),
                functionKey: Self.pastelStripeStops[0].dimmed().darkened(by: 0.08),
                text: ThemeColor(0.95, 0.92, 0.98),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                characterKeyPalette: Self.pastelStripeStops.map { $0.dimmed() })
        case .creamTypewriter:
            ThemeAppearance(
                characterKey: ThemeColor(0.45, 0.40, 0.33),
                functionKey: ThemeColor(0.33, 0.28, 0.22),
                text: ThemeColor(0.97, 0.93, 0.85),
                shadow: ThemeColor(white: 0, alpha: 0.4))
        case .forest:
            ThemeAppearance(
                characterKey: ThemeColor(0.24, 0.33, 0.24),
                functionKey: ThemeColor(0.15, 0.22, 0.15),
                text: ThemeColor(0.93, 0.95, 0.85),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                accentKey: ThemeColor(0.50, 0.36, 0.25),
                functionKeyText: ThemeColor(0.93, 0.95, 0.85),
                accentKeyText: ThemeColor(0.97, 0.95, 0.88))
        case .lavender:
            ThemeAppearance(
                characterKey: ThemeColor(0.40, 0.34, 0.60),
                functionKey: ThemeColor(0.28, 0.22, 0.45),
                text: ThemeColor(white: 1),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                functionKeyText: ThemeColor(white: 1))
        }
    }
}
