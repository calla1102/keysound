import Testing
@testable import HangulEngine

/// 문서 버퍼에 편집을 적용해 최종 결과를 본다. 입력 문자열의 "⌫" 는 백스페이스, "␣" 는 스페이스(조합 확정 후 공백).
private func type(_ input: String, from initial: String = "") -> String {
    var automaton = HangulAutomaton()
    var doc = initial
    func apply(_ edit: TextEdit) {
        doc.removeLast(min(edit.deleteCount, doc.count))
        doc += edit.insert
    }
    for key in input {
        switch key {
        case "⌫":
            if let edit = automaton.backspace() {
                apply(edit)
            } else if !doc.isEmpty {
                doc.removeLast()
            }
        case "␣":
            automaton.commit()
            doc += " "
        default:
            apply(automaton.input(key))
        }
    }
    return doc
}

struct 기본조합 {
    @Test(arguments: [
        ("ㄱ", "ㄱ"),
        ("ㅏ", "ㅏ"),
        ("ㄱㅏ", "가"),
        ("ㄱㅏㄴ", "간"),
        ("ㅎㅏㄴㄱㅡㄹ", "한글"),
        ("ㅇㅏㄴㄴㅕㅇㅎㅏㅅㅔㅇㅛ", "안녕하세요"),
        ("ㄲㅗㅊ", "꽃"),
        ("ㅆㅏㄹ", "쌀"),
        ("ㄱㅒ", "걔"),
    ])
    func 음절(input: String, expected: String) {
        #expect(type(input) == expected)
    }

    @Test func 연속자음은_각각_남는다() {
        #expect(type("ㄱㄱ") == "ㄱㄱ")
        #expect(type("ㄱㅅ") == "ㄱㅅ")
    }

    @Test func 모음_뒤_자음은_새_글자() {
        #expect(type("ㅏㄱ") == "ㅏㄱ")
    }

    @Test func 쌍자음_받침() {
        #expect(type("ㄱㅏㄲ") == "갂")
        #expect(type("ㅇㅣㅆㄷㅏ") == "있다")
    }

    @Test func 받침이_될_수_없는_자음은_새_음절() {
        #expect(type("ㄱㅏㄸ") == "가ㄸ")
        #expect(type("ㄱㅏㅃ") == "가ㅃ")
        #expect(type("ㄱㅏㅉ") == "가ㅉ")
    }
}

struct 겹모음 {
    @Test(arguments: [
        ("ㄱㅗㅏ", "과"), ("ㄱㅗㅐ", "괘"), ("ㅎㅗㅣ", "회"),
        ("ㅁㅜㅓ", "뭐"), ("ㄱㅜㅔ", "궤"), ("ㅇㅜㅣ", "위"), ("ㅇㅡㅣ", "의"),
    ])
    func 조합(input: String, expected: String) {
        #expect(type(input) == expected)
    }

    @Test func 홀로_선_겹모음() {
        #expect(type("ㅗㅏ") == "ㅘ")
        #expect(type("ㅡㅣ") == "ㅢ")
    }

    @Test func 겹모음이_안_되면_새_글자() {
        #expect(type("ㄱㅏㅏ") == "가ㅏ")
        #expect(type("ㄱㅗㅓ") == "고ㅓ")
    }

    @Test func 겹모음_뒤_받침() {
        #expect(type("ㄱㅗㅏㄴ") == "관")
        #expect(type("ㅇㅜㅓㄴ") == "원")
    }
}

struct 겹받침 {
    @Test(arguments: [
        ("ㄴㅓㄱㅅ", "넋"), ("ㅇㅏㄴㅈ", "앉"), ("ㅁㅏㄴㅎ", "많"),
        ("ㄷㅏㄹㄱ", "닭"), ("ㅅㅏㄹㅁ", "삶"), ("ㅇㅕㄹㅂ", "엷"), ("ㄱㅗㄹㅅ", "곬"),
        ("ㅎㅏㄹㅌ", "핥"), ("ㅇㅡㄹㅍ", "읊"), ("ㅇㅣㄹㅎ", "잃"), ("ㄱㅏㅂㅅ", "값"),
    ])
    func 조합(input: String, expected: String) {
        #expect(type(input) == expected)
    }

    @Test func 겹받침이_안_되면_새_음절() {
        #expect(type("ㄷㅏㄹㄱㄱ") == "닭ㄱ")
        #expect(type("ㄱㅏㄴㄱ") == "간ㄱ")
    }
}

struct 받침_이동 {
    @Test func 홑받침이_다음_초성으로() {
        #expect(type("ㄱㅏㄴㅏ") == "가나")
        #expect(type("ㅇㅓㄴㅓ") == "어너")
    }

    @Test func 겹받침은_뒤_자음만_이동() {
        #expect(type("ㅇㅏㄴㅈㅏ") == "안자")
        #expect(type("ㄷㅏㄹㄱㅣ") == "달기")
        #expect(type("ㄷㅏㄹㄱㅇㅣ") == "닭이")
        #expect(type("ㄱㅏㅂㅅㅣ") == "갑시")
    }

    @Test func 쌍자음_받침_이동() {
        #expect(type("ㄱㅏㄲㅏ") == "가까")
    }

    @Test func 이동_후_겹모음() {
        #expect(type("ㄱㅏㄴㅗㅏ") == "가놔")
    }
}

struct 백스페이스 {
    @Test func 자모_단위로_되돌린다() {
        #expect(type("ㄷㅏㄹㄱ⌫") == "달")
        #expect(type("ㄷㅏㄹㄱ⌫⌫") == "다")
        #expect(type("ㄷㅏㄹㄱ⌫⌫⌫") == "ㄷ")
        #expect(type("ㄷㅏㄹㄱ⌫⌫⌫⌫") == "")
    }

    @Test func 겹모음을_한_단계_되돌린다() {
        #expect(type("ㄱㅗㅏ⌫") == "고")
        #expect(type("ㄱㅗㅏㄴ⌫⌫") == "고")
    }

    @Test func 되돌린_뒤_다시_조합된다() {
        #expect(type("ㄷㅏㄹ⌫ㄴ") == "단")
        #expect(type("ㄱㅗㅏ⌫ㅐ") == "괘")
    }

    @Test func 받침_이동_후_되돌리면_이전_음절은_확정된_채() {
        #expect(type("ㅇㅏㄴㅈㅏ⌫") == "안ㅈ")
        #expect(type("ㅇㅏㄴㅈㅏ⌫⌫") == "안")
    }

    @Test func 조합이_끝나면_평범하게_지운다() {
        #expect(type("ㄱㅏ⌫⌫⌫") == "")
        #expect(type("ㄱㅏ⌫⌫", from: "ab") == "ab")
        #expect(type("ㄱㅏ⌫⌫⌫", from: "ab") == "a")
        #expect(type("ㅎㅏㄴ␣⌫⌫") == "")
    }
}

struct 확정과_비자모 {
    @Test func 스페이스로_확정() {
        #expect(type("ㄱㅏ␣ㄴㅏ") == "가 나")
        #expect(type("ㄱㅏㄴ␣ㅏ") == "간 ㅏ")
    }

    @Test func 비자모는_확정_후_그대로() {
        #expect(type("ㄱㅏ1ㅏ") == "가1ㅏ")
        #expect(type("ㄱㅏㄴ.") == "간.")
    }

    @Test func 조합_상태() {
        var a = HangulAutomaton()
        #expect(!a.isComposing)
        _ = a.input("ㄱ")
        _ = a.input("ㅏ")
        #expect(a.isComposing)
        #expect(a.composing == "가")
        a.commit()
        #expect(!a.isComposing)
        #expect(a.composing == "")
    }

    @Test func 편집_명령() {
        var a = HangulAutomaton()
        #expect(a.input("ㄱ") == TextEdit(deleteCount: 0, insert: "ㄱ"))
        #expect(a.input("ㅏ") == TextEdit(deleteCount: 1, insert: "가"))
        #expect(a.input("ㄴ") == TextEdit(deleteCount: 1, insert: "간"))
        #expect(a.input("ㅏ") == TextEdit(deleteCount: 1, insert: "가나"))
        #expect(a.backspace() == TextEdit(deleteCount: 1, insert: "ㄴ"))
        #expect(a.backspace() == TextEdit(deleteCount: 1, insert: ""))
        #expect(a.backspace() == nil)
    }
}
