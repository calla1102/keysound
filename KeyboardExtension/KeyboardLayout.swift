import Foundation

/// 키 하나가 하는 일.
enum KeyAction: Equatable {
    /// 자모·숫자·기호 입력
    case character(Character)
    case shift
    case backspace
    case space
    case enter
    /// 한글 ↔ 숫자·기호 전환
    case layer(KeyboardLayer)
    /// 다음 키보드(🌐)
    case nextKeyboard
    /// 줄 가운데 정렬용 빈칸
    case spacer
}

enum KeyboardLayer: Equatable {
    case hangul, symbols
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

/// iOS 기본 두벌식 배열을 따른 키 배치.
enum KeyboardLayout {
    static func rows(for layer: KeyboardLayer, showsGlobe: Bool) -> [[KeySpec]] {
        switch layer {
        case .hangul:
            return [
                chars("ㅂㅈㄷㄱㅅㅛㅕㅑㅐㅔ"),
                [KeySpec(.spacer, width: .flexible)] + chars("ㅁㄴㅇㄹㅎㅗㅓㅏㅣ") + [KeySpec(.spacer, width: .flexible)],
                [KeySpec(.shift, width: .flexible)] + chars("ㅋㅌㅊㅍㅠㅜㅡ") + [KeySpec(.backspace, width: .flexible)],
                bottomRow(toggle: .symbols, showsGlobe: showsGlobe),
            ]
        case .symbols:
            return [
                chars("1234567890"),
                chars("-/:;()₩&@\""),
                [KeySpec(.spacer, width: .flexible)] + chars(".,?!'~") + [KeySpec(.backspace, width: .flexible)],
                bottomRow(toggle: .hangul, showsGlobe: showsGlobe),
            ]
        }
    }

    /// Shift 를 누르면 바뀌는 자모(나머지는 그대로).
    static let shifted: [Character: Character] = [
        "ㅂ": "ㅃ", "ㅈ": "ㅉ", "ㄷ": "ㄸ", "ㄱ": "ㄲ", "ㅅ": "ㅆ",
        "ㅐ": "ㅒ", "ㅔ": "ㅖ",
    ]

    private static func chars(_ s: String) -> [KeySpec] {
        s.map { KeySpec(.character($0)) }
    }

    private static func bottomRow(toggle: KeyboardLayer, showsGlobe: Bool) -> [KeySpec] {
        var row = [KeySpec(.layer(toggle), width: .units(1.25))]
        if showsGlobe {
            row.append(KeySpec(.nextKeyboard, width: .units(1.25)))
        }
        row.append(KeySpec(.space, width: .flexible))
        row.append(KeySpec(.enter, width: .units(2)))
        return row
    }
}
