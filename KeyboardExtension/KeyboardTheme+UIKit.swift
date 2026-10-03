import UIKit

extension ThemeColor {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension KeyboardTheme {
    /// 라이트·다크에 따라 바뀌는 UIColor. 뷰의 backgroundColor 에 넣으면 trait 변화 때 자동으로 다시 해석된다.
    func dynamicColor(_ pick: @escaping (ThemeAppearance) -> ThemeColor) -> UIColor {
        UIColor { trait in
            pick(self.appearance(dark: trait.userInterfaceStyle == .dark)).uiColor
        }
    }

    /// 키보드 뷰 배경. 투명(alpha 0)이면 시스템 배경이 비친다.
    /// 완전 투명 영역의 터치가 호스팅 쪽에서 빠진다는 경험칙(미검증)에 대비해 alpha 를 0.001 로 올린다.
    var backgroundUIColor: UIColor {
        UIColor { trait in
            let color = self.appearance(dark: trait.userInterfaceStyle == .dark).background
            return color.alpha == 0 ? UIColor(white: 0, alpha: 0.001) : color.uiColor
        }
    }

    /// 주어진 trait 에서의 그림자 색. nil 이면 그림자 없음.
    func shadowUIColor(for trait: UITraitCollection) -> UIColor? {
        appearance(dark: trait.userInterfaceStyle == .dark).shadow?.uiColor
    }
}
