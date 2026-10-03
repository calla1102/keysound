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
}

/// 키보드에서 고를 수 있는 자판 디자인 프리셋. rawValue(고유 id)가 App Group 에 저장된다.
/// 새 프리셋은 case 와 `displayName`·`summary`·`cornerRadius`·`lightAppearance`·`darkAppearance` 를 추가한다.
enum KeyboardTheme: String, CaseIterable, Identifiable {
    /// 현재 iOS 기본 키보드와 비슷한 색
    case classic
    case charcoal
    case vintage
    case pastel

    static let `default`: KeyboardTheme = .classic

    var id: String { rawValue }

    /// 저장되지 않았거나 알 수 없는 값이면 기본 프리셋
    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .default
    }

    var displayName: String {
        switch self {
        case .classic: "기본"
        case .charcoal: "어두운 회색"
        case .vintage: "크림 빈티지"
        case .pastel: "파스텔"
        }
    }

    var summary: String {
        switch self {
        case .classic: "시스템 키보드와 어우러지는 기본 색"
        case .charcoal: "라이트·다크 모두 짙은 회색"
        case .vintage: "크림과 베이지의 차분한 색"
        case .pastel: "하늘색과 분홍의 부드러운 색"
        }
    }

    /// 키 모서리 반경(pt). 라이트·다크 공통
    var cornerRadius: Double {
        switch self {
        case .classic: 5
        case .charcoal: 6
        case .vintage: 4
        case .pastel: 9
        }
    }

    func appearance(dark: Bool) -> ThemeAppearance {
        dark ? darkAppearance : lightAppearance
    }

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
        case .charcoal:
            Self.charcoalAppearance
        case .vintage:
            ThemeAppearance(
                characterKey: ThemeColor(0.98, 0.95, 0.88),
                functionKey: ThemeColor(0.80, 0.73, 0.61),
                characterKeyPressed: ThemeColor(0.86, 0.80, 0.68),
                functionKeyPressed: ThemeColor(0.90, 0.85, 0.74),
                text: ThemeColor(0.25, 0.19, 0.13),
                shadow: ThemeColor(0.35, 0.27, 0.18, alpha: 0.35))
        case .pastel:
            ThemeAppearance(
                characterKey: ThemeColor(0.80, 0.90, 0.98),
                functionKey: ThemeColor(0.98, 0.82, 0.88),
                characterKeyPressed: ThemeColor(0.98, 0.82, 0.88),
                functionKeyPressed: ThemeColor(0.80, 0.90, 0.98),
                text: ThemeColor(0.28, 0.28, 0.40),
                shadow: nil)
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
        case .charcoal:
            Self.charcoalAppearance
        case .vintage:
            ThemeAppearance(
                characterKey: ThemeColor(0.36, 0.31, 0.25),
                functionKey: ThemeColor(0.25, 0.21, 0.17),
                characterKeyPressed: ThemeColor(0.25, 0.21, 0.17),
                functionKeyPressed: ThemeColor(0.36, 0.31, 0.25),
                text: ThemeColor(0.93, 0.88, 0.78),
                shadow: ThemeColor(white: 0, alpha: 0.4))
        case .pastel:
            ThemeAppearance(
                characterKey: ThemeColor(0.34, 0.44, 0.58),
                functionKey: ThemeColor(0.55, 0.38, 0.48),
                characterKeyPressed: ThemeColor(0.55, 0.38, 0.48),
                functionKeyPressed: ThemeColor(0.34, 0.44, 0.58),
                text: ThemeColor(0.95, 0.95, 1),
                shadow: nil)
        }
    }

    /// 라이트·다크가 같은 값이다.
    private static let charcoalAppearance = ThemeAppearance(
        characterKey: ThemeColor(white: 0.30),
        functionKey: ThemeColor(white: 0.20),
        characterKeyPressed: ThemeColor(white: 0.42),
        functionKeyPressed: ThemeColor(white: 0.30),
        text: ThemeColor(white: 0.95),
        shadow: ThemeColor(white: 0, alpha: 0.5))
}
