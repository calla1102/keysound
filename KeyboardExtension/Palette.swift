import UIKit

/// 선택된 자판 디자인의 색·모양. 키보드가 보일 때 `reload()` 로 App Group 선택값을 읽는다.
/// 색은 라이트·다크 동적 UIColor 라 모드가 바뀌면 키 배경은 자동으로 따라간다(그림자 색은 `KeyButton` 이 다시 칠한다).
enum Palette {
    private(set) static var theme: KeyboardTheme = .default

    /// 선택이 바뀌었으면 true
    @discardableResult
    static func reload() -> Bool {
        let selected = AppGroup.selectedTheme
        defer { theme = selected }
        return selected != theme
    }

    static var cornerRadius: CGFloat { CGFloat(theme.cornerRadius) }

    static var characterKey: UIColor { theme.dynamicColor(\.characterKey) }
    static var functionKey: UIColor { theme.dynamicColor(\.functionKey) }
    static var characterKeyPressed: UIColor { theme.dynamicColor(\.characterKeyPressed) }
    static var functionKeyPressed: UIColor { theme.dynamicColor(\.functionKeyPressed) }
    static var text: UIColor { theme.dynamicColor(\.text) }

    /// 키보드 뷰 배경. 투명(alpha 0)이면 시스템 배경이 비친다.
    /// 완전 투명 영역의 터치가 호스팅 쪽에서 빠진다는 경험칙(미검증)에 대비해 alpha 를 0.001 로 올린다.
    static var background: UIColor {
        let t = theme
        return UIColor { trait in
            let color = t.appearance(dark: trait.userInterfaceStyle == .dark).background
            return color.alpha == 0 ? UIColor(white: 0, alpha: 0.001) : color.uiColor
        }
    }

    /// 현재 trait 에서의 그림자 색. nil 이면 그림자 없음.
    static func shadowColor(for trait: UITraitCollection) -> UIColor? {
        theme.appearance(dark: trait.userInterfaceStyle == .dark).shadow?.uiColor
    }
}
