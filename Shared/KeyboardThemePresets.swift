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
        case .rainbow: 8
        case .cottonCandy: 12
        case .roseTypewriter: 12
        case .slateTypewriter: 12
        case .biscuit: 7
        }
    }

    var keyShape: KeyShape {
        switch self {
        case .cottonCandy, .roseTypewriter, .slateTypewriter: .capsule
        default: .rounded
        }
    }

    var font: ThemeFont {
        self == .pixel ? .pixel : .system
    }

    var keyPattern: KeyPattern? {
        switch self {
        case .pixel: .mixed
        case .biscuit: .dots
        default: nil
        }
    }

    var patternScope: PatternScope {
        self == .biscuit ? .all : .alternate
    }

    /// 무늬 농담(alpha). nil 이면 무늬 기본값(체크 0.08·점 0.10)
    var patternInkAlpha: Double? {
        self == .biscuit ? 0.15 : nil
    }

    var paletteMode: PaletteMode {
        switch self {
        case .rainbow, .cottonCandy: .horizontal
        default: .cycle
        }
    }

    var relief: KeyRelief {
        switch self {
        case .milk, .toast, .toffee, .retro, .mono, .rainbow, .slateTypewriter, .biscuit: .raised
        case .matcha, .strawberry, .blueberry, .sherbet, .cottonCandy: .dished
        case .crystal, .soda, .roseTypewriter: .glass
        case .classic, .pixel, .outline: .flat
        }
    }

    /// `.raised` 측면 띠 두께(pt). 레트로는 두껍게.
    var sideThickness: Double {
        self == .retro ? 4 : 3
    }

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
                characterKeyPalette: [
                    ThemeColor(1.0, 0.96, 0.78),
                    ThemeColor(0.84, 0.95, 0.76),
                    ThemeColor(1.0, 0.85, 0.74),
                    ThemeColor(0.80, 0.91, 0.98),
                ])
        case .rainbow:
            ThemeAppearance(
                characterKey: Self.rainbowStops[0],
                functionKey: Self.rainbowStops[2],
                text: ThemeColor(white: 1),
                shadow: ThemeColor(0.30, 0.30, 0.40, alpha: 0.25),
                characterKeyPalette: Self.rainbowStops)
        case .cottonCandy:
            ThemeAppearance(
                characterKey: ThemeColor(1.0, 0.82, 0.88),
                functionKey: ThemeColor(0.80, 0.91, 0.99),
                text: ThemeColor(0.45, 0.45, 0.50),
                shadow: ThemeColor(0.40, 0.40, 0.50, alpha: 0.20),
                characterKeyPalette: [ThemeColor(1.0, 0.82, 0.88), ThemeColor(0.99, 0.98, 1.0), ThemeColor(0.80, 0.91, 0.99)])
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
                characterKey: ThemeColor(0.50, 0.46, 0.30),
                functionKey: ThemeColor(0.45, 0.33, 0.26),
                text: ThemeColor(1.0, 0.95, 0.88),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                characterKeyPalette: [
                    ThemeColor(0.50, 0.46, 0.30),
                    ThemeColor(0.34, 0.46, 0.32),
                    ThemeColor(0.52, 0.38, 0.30),
                    ThemeColor(0.30, 0.42, 0.52),
                ])
        case .rainbow:
            // 같은 색을 채도는 두고 밝기만 낮춘다
            ThemeAppearance(
                characterKey: Self.rainbowStops[0].darkened(by: 0.45),
                functionKey: Self.rainbowStops[2].darkened(by: 0.45),
                text: ThemeColor(white: 1),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                characterKeyPalette: Self.rainbowStops.map { $0.darkened(by: 0.45) })
        case .cottonCandy:
            ThemeAppearance(
                characterKey: ThemeColor(0.50, 0.34, 0.40),
                functionKey: ThemeColor(0.30, 0.40, 0.52),
                text: ThemeColor(0.92, 0.92, 0.96),
                shadow: ThemeColor(white: 0, alpha: 0.4),
                characterKeyPalette: [ThemeColor(0.50, 0.34, 0.40), ThemeColor(0.42, 0.42, 0.48), ThemeColor(0.30, 0.40, 0.52)])
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
        }
    }
}
