import SwiftUI
import UIKit

extension ThemeColor {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

extension KeyboardTheme {
    /// 라이트·다크에 따라 바뀌는 UIColor. 뷰의 backgroundColor 에 넣으면 trait 변화 때 자동으로 다시 해석된다.
    func dynamicColor(_ pick: @escaping (ThemeAppearance) -> ThemeColor) -> UIColor {
        UIColor { trait in
            pick(self.appearance(dark: trait.userInterfaceStyle == .dark)).uiColor
        }
    }
}
