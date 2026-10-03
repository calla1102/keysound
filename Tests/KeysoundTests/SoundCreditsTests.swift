import XCTest

final class SoundCreditsTests: XCTestCase {
    /// `.off` 를 뺀 모든 소리에 출처가 있고, `.off` 에는 없다.
    func testEverySoundHasCreditExceptOff() {
        for sound in SwitchSound.allCases {
            if sound == .off {
                XCTAssertNil(sound.credit)
            } else {
                XCTAssertNotNil(sound.credit, "\(sound.rawValue) 출처 누락")
            }
        }
    }

    func testRecordingCreditsHaveRequiredFields() {
        for sound in SwitchSound.allCases {
            guard case let .recording(recorder, workTitle, links, license, modification)? = sound.credit?.origin else { continue }
            XCTAssertFalse(recorder.isEmpty, sound.rawValue)
            XCTAssertFalse(links.isEmpty, sound.rawValue)
            XCTAssertFalse(modification.isEmpty, sound.rawValue)
            for link in links {
                XCTAssertEqual(link.url.scheme, "https", sound.rawValue)
                XCTAssertFalse(link.title.isEmpty, sound.rawValue)
            }
            // CC BY 4.0 §3(a)(1): 저작자·라이선스 URI·변경 고지 + 작품명(관례상 함께 적는다)
            if license.requiresAttribution {
                XCTAssertFalse(workTitle?.isEmpty ?? true, "\(sound.rawValue) CC BY 작품명 누락")
            }
        }
    }

    /// 합성음은 「기본 클릭」뿐이다.
    func testOnlyClickIsSynthesized() {
        for sound in SwitchSound.allCases {
            XCTAssertEqual(sound.credit?.origin == .synthesized, sound == .click, sound.rawValue)
        }
    }

    /// 현재 CC BY 4.0 인 소리(CREDITS.md). 늘거나 줄면 이 목록과 CREDITS.md 를 함께 고친다.
    func testCcByRows() {
        let ccBy = SwitchSound.allCases.filter {
            if case .recording(_, _, _, .ccBy4, _)? = $0.credit?.origin { return true }
            return false
        }
        XCTAssertEqual(Set(ccBy), [.topre, .membrane, .slim])
    }
}
