/// 커서를 한 줄 위/아래로 옮기는 두 단계 계산.
///
/// 키보드 익스텐션은 커서를 `adjustTextPosition(byCharacterOffset:)` 로만 옮길 수 있고 세로 이동 API 가 없다.
/// 게다가 호스트가 주는 `documentContextBeforeInput`/`AfterInput` 은 앱에 따라 **현재 문단(개행 사이)까지만** 온다
/// (2026-10-02 메시지 앱 실측: 줄 끝에서 after 가 nil, 다음 줄 처음에서 before 가 "\n" 하나).
/// 그래서 한 번에 목표 위치를 계산하지 않고, 줄 경계를 먼저 넘은 뒤(1단계) 호스트가 새로 준 문맥으로 목표 열을 찾는다(2단계).
///
/// 개행으로 나뉜 줄만 다룬다. 자동 줄바꿈(soft wrap)은 알 수 없어, 접힌 문단 안에서 위로 가면 문단 처음
/// (첫 문단이면 문서 처음)으로 간다 — 「막혀서 안 움직임」보다 낫다고 정했다(2026-10-02 사용자 결정).
/// 아래로 가면 다음 문단으로 건너뛰고, 목표 열이 문단 안 오프셋이라 다음 문단이 짧으면 그 끝에 붙는다(같은 한계).
/// 글자 수는 Character 단위다. `adjustTextPosition` 이 호스트에서 같은 단위로 움직이는지는 실기기에서 확인한다.
public enum LineStep {
    public enum Direction { case up, down }

    /// 현재 줄에서 커서 앞 글자 수. 문맥에 개행이 없으면 문맥 처음을 줄 처음으로 본다(문단 단위로 잘려 오는 앱 기준).
    public static func column(before: String) -> Int {
        var count = 0
        for ch in before.reversed() {
            if ch.isNewline { break }
            count += 1
        }
        return count
    }

    /// 1단계: 줄 경계를 넘는 이동. 위는 이전 줄 끝, 아래는 다음 줄 처음으로 간다.
    /// 첫/마지막 줄이면 호스트가 문서 처음/끝에서 멈추고, 2단계가 0 을 돌려준다.
    public static func cross(_ direction: Direction, before: String, after: String) -> Int {
        switch direction {
        case .up:
            return -(column(before: before) + 1)
        case .down:
            return lineRemainder(after) + 1
        }
    }

    /// 2단계: 1단계 뒤 호스트 문맥에서 목표 열로 가는 이동. 줄이 짧으면 줄 끝.
    public static func settle(_ direction: Direction, before: String, after: String, goalColumn: Int) -> Int {
        switch direction {
        case .up:
            // 커서가 이전 줄 끝에 있으므로 줄 길이 = 커서 앞 글자 수
            let length = column(before: before)
            return -max(0, length - goalColumn)
        case .down:
            // 커서가 다음 줄 처음에 있으므로 줄 길이 = 커서 뒤 첫 개행까지
            return min(goalColumn, lineRemainder(after))
        }
    }

    /// 커서 뒤 첫 개행까지 글자 수. 개행이 없으면 문맥 끝을 줄 끝으로 본다.
    private static func lineRemainder(_ after: String) -> Int {
        var count = 0
        for ch in after {
            if ch.isNewline { break }
            count += 1
        }
        return count
    }
}
