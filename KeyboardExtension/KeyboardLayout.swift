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
    /// 숫자 입력란용 패드. 글자 레이어와 오가는 키가 없고, 입력란이 바뀌면 InputProfile 이 고른다.
    /// ascii 는 리턴 키가 있는 패드, decimal 은 소수점, phone 은 `*`·`#` 이 있다.
    case numberPad, asciiNumberPad, decimalPad, phonePad

    /// 글자 레이어(한글·영문)인가. 기호 레이어에서 돌아갈 곳이 되고, 마지막 선택으로 기억된다.
    var isLetters: Bool { self == .hangul || self == .english }

    /// 한/영 전환 키가 가리킬 반대쪽 글자 레이어.
    var otherLanguage: KeyboardLayer { self == .english ? .hangul : .english }
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
    /// `accessories` 는 글자 레이어 맨 아랫줄 스페이스 옆에 더할 보조 키(이메일 `@` 등).
    static func rows(for layer: KeyboardLayer, showsGlobe: Bool, lettersLayer: KeyboardLayer = .hangul, accessories: [Character] = []) -> [[KeySpec]] {
        switch layer {
        case .hangul:
            return [
                chars("ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ"),
                [KeySpec(.spacer, width: .flexible)] + chars("ㅁㄴㅇㄹㅎㅗㅓㅏㅣ") + [KeySpec(.spacer, width: .flexible)],
                [KeySpec(.shift, width: .flexible)] + chars("ㅋㅌㅊㅍㅠㅜㅡ") + [KeySpec(.backspace, width: .flexible)],
                bottomRow(toggle: .symbols, language: .english, showsGlobe: showsGlobe, accessories: accessories),
            ]
        case .english:
            return [
                chars("qwertyuiop"),
                [KeySpec(.spacer, width: .flexible)] + chars("asdfghjkl") + [KeySpec(.spacer, width: .flexible)],
                [KeySpec(.shift, width: .flexible)] + chars("zxcvbnm") + [KeySpec(.backspace, width: .flexible)],
                bottomRow(toggle: .symbols, language: .hangul, showsGlobe: showsGlobe, accessories: accessories),
            ]
        case .symbols:
            return [
                chars("1234567890"),
                chars("-/:;()₩&@\""),
                [KeySpec(.layer(.moreSymbols), width: Self.sideKeyWidth)] + chars(".,?!'", width: .flexible) + [KeySpec(.backspace, width: Self.sideKeyWidth)],
                bottomRow(toggle: lettersLayer, language: lettersLayer.otherLanguage, showsGlobe: showsGlobe),
            ]
        case .moreSymbols:
            return [
                chars("[]{}#%^*+="),
                chars("_\\|~<>$£¥•"),
                [KeySpec(.layer(.symbols), width: Self.sideKeyWidth)] + chars(".,?!'", width: .flexible) + [KeySpec(.backspace, width: Self.sideKeyWidth)],
                bottomRow(toggle: lettersLayer, language: lettersLayer.otherLanguage, showsGlobe: showsGlobe),
            ]
        case .numberPad, .asciiNumberPad, .decimalPad, .phonePad:
            return padRows(for: layer, showsGlobe: showsGlobe)
        }
    }

    /// 숫자 패드. 위 세 줄은 1~9, 맨 아랫줄만 종류별로 다르다. 폭은 모두 줄 안에서 균등하게 나눈다.
    private static func padRows(for layer: KeyboardLayer, showsGlobe: Bool) -> [[KeySpec]] {
        func flex(_ action: KeyAction) -> KeySpec { KeySpec(action, width: .flexible) }
        func digits(_ s: String) -> [KeySpec] { s.map { flex(.character($0)) } }
        let globe = [flex(.nextKeyboard)]
        // 🌐 가 없으면 0 이 가운데 오도록 빈칸으로 맞춘다
        let leading = showsGlobe ? globe : [flex(.spacer)]
        let bottom: [KeySpec]
        switch layer {
        case .decimalPad:
            bottom = (showsGlobe ? globe : []) + [flex(.character(".")), flex(.character("0")), flex(.backspace)]
        case .phonePad:
            bottom = (showsGlobe ? globe : []) + digits("*0#") + [flex(.backspace)]
        case .asciiNumberPad:
            bottom = leading + [flex(.character("0")), flex(.backspace), flex(.enter)]
        default:
            bottom = leading + [flex(.character("0")), flex(.backspace)]
        }
        return [digits("123"), digits("456"), digits("789"), bottom]
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

    /// `language` 는 한/영 전환 키(🌐 와 별개). 기호 레이어에서는 돌아갈 글자 레이어의 반대쪽 언어로 바로 간다.
    private static func bottomRow(toggle: KeyboardLayer, language: KeyboardLayer?, showsGlobe: Bool, accessories: [Character] = []) -> [KeySpec] {
        var row = [KeySpec(.layer(toggle), width: .units(1.25))]
        if let language {
            row.append(KeySpec(.layer(language), width: .units(1.25)))
        }
        if showsGlobe {
            row.append(KeySpec(.nextKeyboard, width: .units(1.25)))
        }
        row += chars(String(accessories))
        row.append(KeySpec(.space, width: .flexible))
        row.append(KeySpec(.enter, width: .units(2)))
        return row
    }
}
