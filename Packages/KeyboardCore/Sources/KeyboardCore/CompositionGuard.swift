/// 한글 조합 확정 판정. 시계 없이 시각을 호출 쪽에서 넘기므로 단위 테스트할 수 있다.
///
/// 호스트 앱은 문맥(documentContextBeforeInput)을 한발 늦게 갱신하므로, 우리 마지막 편집 직후(유예 중)엔
/// 문맥이 옛 조합 글자로 끝날 수 있다. 오탐(정상 타이핑 중 조합이 끊김)이 미탐(드문 오삭제)보다 나쁘므로
/// 유예 중엔 관대하게 판정한다.
public struct CompositionGuard: Equatable {
    /// 마지막 편집 뒤 호스트 문맥의 불일치를 믿지 않는 시간(초).
    public static let grace: Double = 0.3
    /// 조합 기록을 유지하고 참조하는 창(초). 유예의 2배.
    public static let recordWindow: Double = grace * 2

    /// 우리가 만든 조합 글자와 그 시각. 빈 `text` 는 「조합이 없던 상태」라 그 앞 문맥을 알 수 없다는 뜻이다.
    public struct Record: Equatable {
        public var text: String
        public var at: Double
        public init(text: String, at: Double) {
            self.text = text
            self.at = at
        }
    }

    /// 최근 조합 기록(오래된 순).
    public private(set) var records: [Record] = []

    public init() {}

    /// 조합 상태가 바뀐 시점의 조합 글자를 기록하고 창 밖의 오래된 기록을 버린다.
    public mutating func note(composing: String, at now: Double) {
        records.append(Record(text: composing, at: now))
        records.removeAll { now - $0.at > Self.recordWindow }
    }

    /// 기록을 모두 비운다(키보드가 사라질 때).
    public mutating func reset() {
        records.removeAll()
    }

    /// 조합 중인 글자(`composing`)가 문맥(`before`)과 어긋났는지(커서가 옮겨졌거나 앱이 글을 바꿨는지).
    /// 조합 중이 아닐 때의 판단은 호출 쪽 몫이다.
    ///
    /// - `before == nil`: UIKit 은 문서가 비어도(보내기·전체 삭제) 빈 문자열이 아니라 nil 을 준다.
    ///   그래서 `documentEmpty`(hasText == false 이고 커서 뒤 문맥도 없음)이면 비어 버린 문서로 보고,
    ///   마지막 편집 뒤 유예가 지났을 때 stale 로 판정한다(유예 중엔 호스트 갱신이 늦은 것일 수 있어 유지).
    ///   `documentEmpty` 가 아니면 문맥을 못 읽는 앱으로 보고 조합을 유지한다(stale 아님).
    /// - 문맥이 조합 글자로 끝나면 정상(stale 아님).
    /// - 불일치라도 마지막 편집(`lastEditTime`) 뒤 `grace` 안이면 호스트 문맥이 늦은 것일 수 있어 **불일치를 믿지 않는다**
    ///   (= stale 아님으로 본다). 단 최근 `recordWindow` 안의 기록 중 하나로 문맥이 끝나거나(옛 값),
    ///   빈 기록(조합 시작 직후라 옛 문맥을 알 수 없음)이 있을 때만 그렇다. 둘 다 없으면 stale.
    ///   그래서 조합을 확정한 직후 `recordWindow` 동안은 빈 기록이 남아 유예 판정이 더 관대하다.
    /// - 유예가 지난 불일치는 stale.
    public func isStale(composing: String, before: String?, documentEmpty: Bool = false,
                        lastEditTime: Double, now: Double) -> Bool {
        guard let before else {
            return documentEmpty && now - lastEditTime >= Self.grace
        }
        if before.hasSuffix(composing) { return false }
        if now - lastEditTime < Self.grace {
            return !records.contains { now - $0.at <= Self.recordWindow && ($0.text.isEmpty || before.hasSuffix($0.text)) }
        }
        return true
    }
}
