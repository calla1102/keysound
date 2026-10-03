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

    func testClassicKeepsOriginalPaletteAndClearBackground() {
        XCTAssertEqual(KeyboardTheme.classic.lightAppearance.background.alpha, 0)
        XCTAssertEqual(KeyboardTheme.classic.darkAppearance.background.alpha, 0)
        XCTAssertEqual(KeyboardTheme.classic.darkAppearance.characterKey, ThemeColor(white: 0.42))
        XCTAssertEqual(KeyboardTheme.classic.darkAppearance.functionKey, ThemeColor(white: 0.27))
        XCTAssertEqual(KeyboardTheme.classic.lightAppearance.characterKey, ThemeColor(white: 1))
    }

    func testColorsAreInRange() {
        for theme in KeyboardTheme.allCases {
            for look in [theme.lightAppearance, theme.darkAppearance] {
                let colors = [look.background, look.characterKey, look.functionKey,
                              look.characterKeyPressed, look.functionKeyPressed, look.text] + [look.shadow].compactMap { $0 }
                for c in colors {
                    for v in [c.red, c.green, c.blue, c.alpha] {
                        XCTAssertTrue((0...1).contains(v), theme.rawValue)
                    }
                }
            }
            XCTAssertFalse(theme.displayName.isEmpty)
        }
    }
}
