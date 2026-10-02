/// 커서 앞 `deleteCount` 글자를 지운 뒤 `insert` 를 넣으라는 편집 명령.
/// 키보드 익스텐션은 조합 중 글자를 marked text 없이 「지우고 다시 쓰기」로 갱신한다.
public struct TextEdit: Equatable {
    public let deleteCount: Int
    public let insert: String

    public init(deleteCount: Int, insert: String) {
        self.deleteCount = deleteCount
        self.insert = insert
    }
}

/// 두벌식 한글 오토마타.
/// 입력은 호환 자모(ㄱ, ㅏ …)이고, 쌍자음(ㄲ ㄸ ㅃ ㅆ ㅉ)과 ㅒ ㅖ 는 Shift 로 직접 들어온다.
/// 조합 중인 음절은 항상 1글자이며, 그 음절을 만든 입력 자모를 기억해 백스페이스로 한 단계씩 되돌린다.
public struct HangulAutomaton {
    private var syllable = Syllable()
    /// 현재 조합 중 음절을 만든 입력 자모. 비어 있으면 조합 중이 아니다.
    private var keys: [Character] = []

    public init() {}

    public var isComposing: Bool { !keys.isEmpty }

    /// 조합 중인 글자(없으면 빈 문자열). 문서 커서 앞 글자와 대조할 때 쓴다.
    public var composing: String { syllable.rendered }

    /// 글자 하나를 입력한다. 한글 자모가 아니면 조합을 끝내고 그대로 넣는다.
    public mutating func input(_ key: Character) -> TextEdit {
        guard Jamo.isConsonant(key) || Jamo.isVowel(key) else {
            commit()
            return TextEdit(deleteCount: 0, insert: String(key))
        }

        let deleteCount = isComposing ? 1 : 0
        switch Self.step(syllable, key) {
        case .merged(let next):
            syllable = next
            keys.append(key)
            return TextEdit(deleteCount: deleteCount, insert: syllable.rendered)
        case .split(let committed, let next, let nextKeys):
            syllable = next
            keys = nextKeys
            return TextEdit(deleteCount: deleteCount, insert: committed.rendered + syllable.rendered)
        }
    }

    /// 조합 중이면 마지막 입력 자모 하나를 되돌린 편집을 돌려준다.
    /// 조합 중이 아니면 nil — 호출 측이 평범하게 한 글자를 지운다.
    public mutating func backspace() -> TextEdit? {
        guard isComposing else { return nil }
        keys.removeLast()
        syllable = Syllable()
        for key in keys {
            guard case .merged(let next) = Self.step(syllable, key) else {
                // 전이 규칙상 도달하지 않는다. 키보드가 죽지 않도록 조합 중 글자를 지우고 끝낸다
                assertionFailure("조합 기록 재생 중 음절이 분리됨: \(keys)")
                commit()
                return TextEdit(deleteCount: 1, insert: "")
            }
            syllable = next
        }
        return TextEdit(deleteCount: 1, insert: syllable.rendered)
    }

    /// 조합을 확정한다. 문서에는 이미 글자가 들어가 있으므로 편집은 없다.
    public mutating func commit() {
        syllable = Syllable()
        keys = []
    }

    // MARK: - 상태 전이

    private enum Step {
        /// 현재 음절에 합쳐짐
        case merged(Syllable)
        /// 현재 음절을 확정하고 새 음절을 시작함
        case split(committed: Syllable, next: Syllable, nextKeys: [Character])
    }

    private static func step(_ s: Syllable, _ key: Character) -> Step {
        if Jamo.isConsonant(key) {
            return consonantStep(s, key)
        }
        return vowelStep(s, key)
    }

    private static func consonantStep(_ s: Syllable, _ key: Character) -> Step {
        let fresh = Syllable(cho: key)
        guard let jong = s.jong else {
            if s.isEmpty { return .merged(fresh) }
            // 초성만 있거나 중성만 있으면 받침을 붙일 수 없다
            guard s.cho != nil, s.jung != nil, Jamo.jongseong.contains(key) else {
                return .split(committed: s, next: fresh, nextKeys: [key])
            }
            var next = s
            next.jong = key
            return .merged(next)
        }
        guard let compound = Jamo.compoundJong[[jong, key]] else {
            return .split(committed: s, next: fresh, nextKeys: [key])
        }
        var next = s
        next.jong = compound
        return .merged(next)
    }

    private static func vowelStep(_ s: Syllable, _ key: Character) -> Step {
        let fresh = Syllable(jung: key)
        if let jong = s.jong {
            // 받침이 다음 음절의 초성으로 넘어간다. 겹받침이면 뒤 자음만 넘어간다.
            var committed = s
            let moved: Character
            if let parts = Jamo.compoundJong.first(where: { $0.value == jong })?.key {
                committed.jong = parts[0]
                moved = parts[1]
            } else {
                committed.jong = nil
                moved = jong
            }
            return .split(committed: committed, next: Syllable(cho: moved, jung: key), nextKeys: [moved, key])
        }
        guard let jung = s.jung else {
            var next = s
            next.jung = key
            return .merged(next)
        }
        guard let compound = Jamo.compoundJung[[jung, key]] else {
            return .split(committed: s, next: fresh, nextKeys: [key])
        }
        var next = s
        next.jung = compound
        return .merged(next)
    }
}

/// 조합 중인 음절. 각 자리는 호환 자모이며 겹모음·겹받침이 들어갈 수 있다.
private struct Syllable {
    var cho: Character?
    var jung: Character?
    var jong: Character?

    var isEmpty: Bool { cho == nil && jung == nil }

    var rendered: String {
        guard let cho, let jung else {
            return (cho ?? jung).map { String($0) } ?? ""
        }
        guard
            let l = Jamo.choseong.firstIndex(of: cho),
            let v = Jamo.jungseong.firstIndex(of: jung)
        else { return String(cho) + String(jung) }
        let t = jong.flatMap { Jamo.jongseong.firstIndex(of: $0).map { $0 + 1 } } ?? 0
        let scalar = Unicode.Scalar(0xAC00 + (l * 21 + v) * 28 + t)!
        return String(Character(scalar))
    }
}

/// 유니코드 한글 음절 조합 순서표(호환 자모).
enum Jamo {
    static let choseong = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
    static let jungseong = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
    /// 받침 없음(0)을 뺀 종성 27개. 음절 계산 시 인덱스에 1을 더한다.
    static let jongseong = Array("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")

    static let compoundJung: [[Character]: Character] = [
        ["ㅗ", "ㅏ"]: "ㅘ", ["ㅗ", "ㅐ"]: "ㅙ", ["ㅗ", "ㅣ"]: "ㅚ",
        ["ㅜ", "ㅓ"]: "ㅝ", ["ㅜ", "ㅔ"]: "ㅞ", ["ㅜ", "ㅣ"]: "ㅟ",
        ["ㅡ", "ㅣ"]: "ㅢ",
    ]

    static let compoundJong: [[Character]: Character] = [
        ["ㄱ", "ㅅ"]: "ㄳ", ["ㄴ", "ㅈ"]: "ㄵ", ["ㄴ", "ㅎ"]: "ㄶ",
        ["ㄹ", "ㄱ"]: "ㄺ", ["ㄹ", "ㅁ"]: "ㄻ", ["ㄹ", "ㅂ"]: "ㄼ", ["ㄹ", "ㅅ"]: "ㄽ",
        ["ㄹ", "ㅌ"]: "ㄾ", ["ㄹ", "ㅍ"]: "ㄿ", ["ㄹ", "ㅎ"]: "ㅀ",
        ["ㅂ", "ㅅ"]: "ㅄ",
    ]

    static func isConsonant(_ c: Character) -> Bool { choseong.contains(c) }

    /// 키로 직접 입력 가능한 모음(겹모음 ㅘ 등은 조합으로만 생긴다).
    static func isVowel(_ c: Character) -> Bool {
        jungseong.contains(c) && !compoundJung.values.contains(c)
    }
}
