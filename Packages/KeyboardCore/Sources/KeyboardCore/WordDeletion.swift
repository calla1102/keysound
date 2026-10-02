/// 백스페이스 길게 누르기 가속 단계의 「단어 단위 삭제」가 지울 글자 수를 계산한다.
/// 한글 오토마타와 무관한 문자열 계산이라 HangulEngine 이 아니라 KeyboardCore 에 둔다.
public enum WordDeletion {
    /// `before`(커서 앞 문맥) 끝에서 한 단어를 지우는 데 필요한 글자(Character) 수.
    /// 끝의 공백·탭을 먼저 지우고, 이어서 공백이 아닌 글자 덩어리(단어)를 지운다. 단어 앞 공백은 남긴다.
    /// 줄바꿈은 경계다 — 줄바꿈을 넘어 앞 줄 단어까지 지우지 않으며, 지울 게 줄바꿈뿐이면 그 하나만 지운다.
    /// 눈에 안 보이는 제로폭 문자(U+200B 등)는 공백처럼 취급해 뒤쪽 공백과 함께 지운다.
    /// 아니면 단어 뒤 제로폭 문자 하나만 지워져 눌러도 화면이 안 바뀌는 틱이 생긴다. 단어 한가운데 것은 단어의 일부다.
    /// 문맥이 비어 있으면 0.
    public static func count(before: String) -> Int {
        var count = 0
        var index = before.endIndex
        // 1) 뒤쪽 공백(줄바꿈 제외)
        while index > before.startIndex {
            let prev = before.index(before: index)
            let ch = before[prev]
            guard (ch.isWhitespace && !ch.isNewline) || isZeroWidth(ch) else { break }
            count += 1
            index = prev
        }
        // 2) 단어 본문
        while index > before.startIndex {
            let prev = before.index(before: index)
            if before[prev].isWhitespace { break }
            count += 1
            index = prev
        }
        // 3) 공백도 단어도 없었고 바로 앞이 줄바꿈이면 줄바꿈 하나
        if count == 0, let last = before.last, last.isNewline { return 1 }
        return count
    }

    /// 한 스칼라짜리 제로폭 문자. 이모지 결합 시퀀스 안의 ZWJ 는 그 시퀀스가 한 Character 라 해당하지 않는다.
    private static func isZeroWidth(_ ch: Character) -> Bool {
        guard ch.unicodeScalars.count == 1, let v = ch.unicodeScalars.first?.value else { return false }
        return (0x200B...0x200D).contains(v) || v == 0x2060 || v == 0xFEFF
    }
}
