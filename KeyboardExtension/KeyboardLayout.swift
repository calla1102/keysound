import Foundation

/// 키 하나가 하는 일.
enum KeyAction: Equatable {
    /// 자모·숫자·기호 입력
    case character(Character)
    case shift
    case backspace
    case space
    case enter
    /// 한글·영문 ↔ 숫자·기호 ↔ 기호 두 번째 화면 전환
    case layer(KeyboardLayer)
    /// 다음 키보드(🌐)
    case nextKeyboard
    /// 줄 가운데 정렬용 빈칸
    case spacer
}

enum KeyboardLayer: String, Equatable {
    case hangul, english, symbols, moreSymbols

    /// 글자 레이어(한글·영문)인가. 기호 레이어에서 돌아갈 곳이 되고, 마지막 선택으로 기억된다.
    var isLetters: Bool { self == .hangul || self == .english }
}

/// 키 폭. `units` 는 글자 키 1칸 기준 배수, `flexible` 은 줄의 남는 폭을 같은 줄의 flexible 키끼리 나눠 갖는다.
enum KeyWidth: Equatable {
    case units(CGFloat)
    case flexible
}

struct KeySpec {
    let action: KeyAction
    let width: KeyWidth

    init(_ action: KeyAction, width: KeyWidth = .units(1)) {
        self.action = action
        self.width = width
    }
}

/// iOS 기본 두벌식·QWERTY 배열을 따른 키 배치.
enum KeyboardLayout {
    /// `lettersLayer` 는 기호 레이어에서 돌아갈 글자 레이어.
    static func rows(for layer: KeyboardLayer, showsGlobe: Bool, lettersLayer: KeyboardLayer = .hangul) -> [[KeySpec]] {
        switch layer {
        case .hangul:
            return [
                chars("ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ"),
                [KeySpec(.spacer, width: .flexible)] + chars("ㅁㄴㅇㄹㅎㅗㅓㅏㅣ") + [KeySpec(.spacer, width: .flexible)],
                [KeySpec(.shift, width: .flexible)] + chars("ㅋㅌㅊㅍㅠㅜㅡ") + [KeySpec(.backspace, width: .flexible)],
                bottomRow(toggle: .symbols, language: .english, showsGlobe: showsGlobe),
            ]
        case .english:
            return [
                chars("qwertyuiop"),
                [KeySpec(.spacer, width: .flexible)] + chars("asdfghjkl") + [KeySpec(.spacer, width: .flexible)],
                [KeySpec(.shift, width: .flexible)] + chars("zxcvbnm") + [KeySpec(.backspace, width: .flexible)],
                bottomRow(toggle: .symbols, language: .hangul, showsGlobe: showsGlobe),
            ]
        case .symbols:
            return [
                chars("1234567890"),
                chars("-/:;()₩&@\""),
                [KeySpec(.layer(.moreSymbols), width: Self.sideKeyWidth)] + chars(".,?!'", width: .flexible) + [KeySpec(.backspace, width: Self.sideKeyWidth)],
                bottomRow(toggle: lettersLayer, language: nil, showsGlobe: showsGlobe),
            ]
        case .moreSymbols:
            return [
                chars("[]{}#%^*+="),
                chars("_\\|~<>€£¥•"),
                [KeySpec(.layer(.symbols), width: Self.sideKeyWidth)] + chars(".,?!'", width: .flexible) + [KeySpec(.backspace, width: Self.sideKeyWidth)],
                bottomRow(toggle: lettersLayer, language: nil, showsGlobe: showsGlobe),
            ]
        }
    }

    /// 기호 화면 셋째 줄 양끝 키(#+=/123, 백스페이스) 폭. 글자 화면의 Shift·백스페이스(1.5칸+간격 절반)와 거의 같다.
    private static let sideKeyWidth = KeyWidth.units(1.5)

    /// Shift 를 누르면 바뀌는 자모(나머지는 그대로).
    static let shifted: [Character: Character] = [
        "ㅂ": "ㅃ", "ㅈ": "ㅉ", "ㄷ": "ㄸ", "ㄱ": "ㄲ", "ㅅ": "ㅆ",
        "ㅐ": "ㅒ", "ㅔ": "ㅖ",
    ]

    private static func chars(_ s: String, width: KeyWidth = .units(1)) -> [KeySpec] {
        s.map { KeySpec(.character($0), width: width) }
    }

    /// `language` 는 한/영 전환 키(🌐 와 별개). 기호 레이어에는 없다.
    private static func bottomRow(toggle: KeyboardLayer, language: KeyboardLayer?, showsGlobe: Bool) -> [KeySpec] {
        var row = [KeySpec(.layer(toggle), width: .units(1.25))]
        if let language {
            row.append(KeySpec(.layer(language), width: .units(1.25)))
        }
        if showsGlobe {
            row.append(KeySpec(.nextKeyboard, width: .units(1.25)))
        }
        row.append(KeySpec(.space, width: .flexible))
        row.append(KeySpec(.enter, width: .units(2)))
        return row
    }
}
