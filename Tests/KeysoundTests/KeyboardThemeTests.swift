import XCTest

final class KeyboardThemeTests: XCTestCase {
    func testDefaultIsClassic() {
        XCTAssertEqual(KeyboardTheme.default, .classic)
    }

    func testMissingOrUnknownValueFallsBackToDefault() {
        XCTAssertEqual(KeyboardTheme(storedValue: nil), .default)
        XCTAssertEqual(KeyboardTheme(storedValue: "no-such-theme"), .default)
        XCTAssertEqual(KeyboardTheme(storedValue: ""), .default)
    }

    func testStoredRawValueRoundTrip() {
        for theme in KeyboardTheme.allCases {
            XCTAssertEqual(KeyboardTheme(storedValue: theme.rawValue), theme)
        }
    }

    func testIDsAreUniqueAndNonEmpty() {
        let ids = KeyboardTheme.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertFalse(ids.contains(""))
        XCTAssertGreaterThanOrEqual(KeyboardTheme.allCases.count, 1)
    }

    func testClassicKeepsOriginalPalette() {
        XCTAssertEqual(KeyboardTheme.classic.darkAppearance.characterKey, ThemeColor(white: 0.42))
        XCTAssertEqual(KeyboardTheme.classic.darkAppearance.functionKey, ThemeColor(white: 0.27))
        XCTAssertEqual(KeyboardTheme.classic.lightAppearance.characterKey, ThemeColor(white: 1))
    }

    func testColorsAreInRange() {
        for theme in KeyboardTheme.allCases {
            for look in [theme.lightAppearance, theme.darkAppearance] {
                let colors = [look.characterKey, look.functionKey,
                              look.characterKeyPressed, look.functionKeyPressed, look.text]
                    + [look.shadow, look.border?.color, look.accentKey, look.functionKeyText, look.accentKeyText].compactMap { $0 }
                    + look.characterKeyPalette
                for c in colors {
                    for v in [c.red, c.green, c.blue, c.alpha] {
                        XCTAssertTrue((0...1).contains(v), theme.rawValue)
                    }
                }
            }
            XCTAssertFalse(theme.displayName.isEmpty)
        }
    }

    func testNineteenPresetsWithClassicFirst() {
        XCTAssertEqual(KeyboardTheme.allCases.count, 19)
        XCTAssertEqual(KeyboardTheme.allCases.first, .classic)
    }

    func testRemovedLegacyValuesFallBackToDefault() {
        for old in ["charcoal", "vintage", "pastel"] {
            XCTAssertEqual(KeyboardTheme(storedValue: old), .default, old)
        }
    }

    func testDarkenKeepsAlphaAndScalesRGB() {
        let c = ThemeColor(0.5, 0.8, 1.0, alpha: 0.6).darkened(by: 0.5)
        XCTAssertEqual(c.red, 0.25, accuracy: 1e-9)
        XCTAssertEqual(c.green, 0.4, accuracy: 1e-9)
        XCTAssertEqual(c.blue, 0.5, accuracy: 1e-9)
        XCTAssertEqual(c.alpha, 0.6, accuracy: 1e-9)
        XCTAssertEqual(ThemeColor(white: 1).darkened(by: 2), ThemeColor(white: 0))
    }

    func testPressedVariantDarkensLightAndLightensDarkColors() {
        XCTAssertLessThan(ThemeColor(white: 0.9).pressedVariant().red, 0.9)
        XCTAssertGreaterThan(ThemeColor(white: 0.1).pressedVariant().red, 0.1)
        XCTAssertGreaterThan(ThemeColor(white: 1, alpha: 0.5).pressedVariant().alpha, 0.5)
    }

    func testPaletteCyclesInKeyOrder() {
        let look = KeyboardTheme.toffee.lightAppearance
        let palette = look.characterKeyPalette
        XCTAssertEqual(palette.count, 3)
        for i in 0..<7 {
            XCTAssertEqual(look.characterColor(at: i), palette[i % 3])
            XCTAssertEqual(look.characterPressedColor(at: i), palette[i % 3].darkened())
        }
        // 팔레트가 없으면 글자 키 색 그대로
        let milk = KeyboardTheme.milk.lightAppearance
        XCTAssertEqual(milk.characterColor(at: 5), milk.characterKey)
    }

    func testEnterUsesAccentOrFunctionKey() {
        let matcha = KeyboardTheme.matcha.lightAppearance
        XCTAssertEqual(matcha.enterKey, matcha.accentKey)
        XCTAssertEqual(matcha.enterKeyPressed, matcha.accentKey?.darkened())
        let milk = KeyboardTheme.milk.lightAppearance
        XCTAssertEqual(milk.enterKey, milk.functionKey)
    }

    func testInterpolateEndpointsAndMidpoint() {
        let stops = [ThemeColor(0, 0, 0), ThemeColor(1, 1, 1), ThemeColor(1, 0, 0)]
        XCTAssertEqual(ThemeColor.interpolate(stops, at: 0), stops[0])
        XCTAssertEqual(ThemeColor.interpolate(stops, at: 1), stops[2])
        XCTAssertEqual(ThemeColor.interpolate(stops, at: 0.5), stops[1])
        XCTAssertEqual(ThemeColor.interpolate(stops, at: 0.25).red, 0.5, accuracy: 1e-9)
        XCTAssertEqual(ThemeColor.interpolate(stops, at: -3), stops[0])
        XCTAssertEqual(ThemeColor.interpolate([], at: 0.5), .clear)
    }

    func testHorizontalPaletteFollowsPositionAndDarkensFunctionKeys() {
        let theme = KeyboardTheme.rainbow
        let look = theme.lightAppearance
        let left = theme.keyColor(role: .character(index: 0), pressed: false, look: look, position: 0)
        let right = theme.keyColor(role: .character(index: 0), pressed: false, look: look, position: 1)
        XCTAssertEqual(left, look.characterKeyPalette.first)
        XCTAssertEqual(right, look.characterKeyPalette.last)
        let fn = theme.keyColor(role: .function, pressed: false, look: look, position: 0)
        XCTAssertEqual(fn, left.darkened(by: 0.08))
        // 순환 프리셋은 위치를 무시한다
        let toffee = KeyboardTheme.toffee
        XCTAssertEqual(
            toffee.keyColor(role: .character(index: 1), pressed: false, look: toffee.lightAppearance, position: 0.9),
            toffee.lightAppearance.characterKeyPalette[1])
    }

    func testPatternScope() {
        XCTAssertEqual(KeyPattern.gingham.tile(forCharacterIndex: 3), .gingham)
        XCTAssertNil(KeyPattern.gingham.tile(forCharacterIndex: 4))
        XCTAssertEqual(KeyPattern.mixed.tile(forCharacterIndex: 0), .gingham)
        XCTAssertEqual(KeyPattern.mixed.tile(forCharacterIndex: 3), .dots)
        XCTAssertEqual(KeyPattern.dots.tile(forCharacterIndex: 4, scope: .all), .dots)
        XCTAssertEqual(KeyboardTheme.biscuit.patternScope, .all)
        XCTAssertEqual(KeyboardTheme.pixel.patternScope, .alternate)
    }

    func testPixelFontSizeIsIntegerMultipleOfGrid() {
        XCTAssertEqual(ThemeFont.system.size(forSystemSize: 22), 22)
        XCTAssertEqual(ThemeFont.pixel.size(forSystemSize: 22), 24)
        XCTAssertEqual(ThemeFont.pixel.size(forSystemSize: 16), 12)
        XCTAssertEqual(ThemeFont.pixel.size(forSystemSize: 24), 24)
        XCTAssertEqual(ThemeFont.pixel.size(forSystemSize: 1), 12)
    }

    func testCapsuleRadiusIsHalfHeight() {
        XCTAssertEqual(KeyboardTheme.cottonCandy.cornerRadius(forHeight: 42), 21)
        XCTAssertEqual(KeyboardTheme.milk.cornerRadius(forHeight: 42), 7)
    }

    func testReliefAssignmentsAndStructure() {
        for t in [KeyboardTheme.milk, .toast, .toffee, .retro, .mono, .rainbow, .slateTypewriter, .biscuit] { XCTAssertEqual(t.relief, .raised) }
        for t in [KeyboardTheme.matcha, .strawberry, .blueberry, .sherbet, .cottonCandy] { XCTAssertEqual(t.relief, .dished) }
        for t in [KeyboardTheme.crystal, .soda, .roseTypewriter] { XCTAssertEqual(t.relief, .glass) }
        XCTAssertEqual(KeyboardTheme.retro.sideThickness, 4)
        XCTAssertEqual(KeyboardTheme.slateTypewriter.lightAppearance.shadowBlur, 6)
        XCTAssertEqual(KeyboardTheme.classic.keyShape, .rounded)
        // 팔레트가 있는 프리셋만 palette 를 쓴다
        for t in KeyboardTheme.allCases where t.paletteMode == .horizontal {
            XCTAssertFalse(t.lightAppearance.characterKeyPalette.isEmpty)
            XCTAssertFalse(t.darkAppearance.characterKeyPalette.isEmpty)
        }
    }
}
