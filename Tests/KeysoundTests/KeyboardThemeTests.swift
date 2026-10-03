import XCTest

final class KeyboardThemeTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let name = "KeyboardThemeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    func testDefaultIsClassic() {
        XCTAssertEqual(KeyboardTheme.default, .classic)
    }

    func testMissingOrUnknownValueFallsBackToDefault() {
        let defaults = makeDefaults()
        XCTAssertEqual(KeyboardTheme.load(from: defaults), .default)
        defaults.set("no-such-theme", forKey: KeyboardTheme.storageKey)
        XCTAssertEqual(KeyboardTheme.load(from: defaults), .default)
        XCTAssertEqual(KeyboardTheme.load(from: nil), .default)
        XCTAssertEqual(KeyboardTheme(storedValue: nil), .default)
    }

    func testSaveLoadRoundTrip() {
        let defaults = makeDefaults()
        for theme in KeyboardTheme.allCases {
            theme.save(to: defaults)
            XCTAssertEqual(KeyboardTheme.load(from: defaults), theme)
        }
    }

    func testIDsAreUniqueAndNonEmpty() {
        let ids = KeyboardTheme.allCases.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertFalse(ids.contains(""))
        XCTAssertEqual(KeyboardTheme.allCases.count, 4)
    }

    func testClassicKeepsOriginalPaletteAndClearBackground() {
        XCTAssertEqual(KeyboardTheme.classic.light.background.alpha, 0)
        XCTAssertEqual(KeyboardTheme.classic.dark.background.alpha, 0)
        XCTAssertEqual(KeyboardTheme.classic.dark.characterKey, ThemeColor(white: 0.42))
        XCTAssertEqual(KeyboardTheme.classic.dark.functionKey, ThemeColor(white: 0.27))
        XCTAssertEqual(KeyboardTheme.classic.light.characterKey, ThemeColor(white: 1))
    }

    func testColorsAreInRange() {
        for theme in KeyboardTheme.allCases {
            for look in [theme.light, theme.dark] {
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
