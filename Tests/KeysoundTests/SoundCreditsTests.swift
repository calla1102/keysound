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
            guard case let .recording(recorder, workTitle, links, _, modification)? = sound.credit?.origin else { continue }
            XCTAssertFalse(recorder.isEmpty, sound.rawValue)
            XCTAssertFalse(links.isEmpty, sound.rawValue)
            XCTAssertFalse(modification.isEmpty, sound.rawValue)
            for link in links {
                XCTAssertEqual(link.url.scheme, "https", sound.rawValue)
                XCTAssertFalse(link.title.isEmpty, sound.rawValue)
            }
            // 작품명은 CC BY 4.0 필수가 아니다. 적는다면 비어 있으면 안 된다.
            if let workTitle {
                XCTAssertFalse(workTitle.isEmpty, sound.rawValue)
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

    /// 화면에 상표명을 쓰지 않는다(CLAUDE.md 라이선스 규칙). 링크 URL 은 화면 글자가 아니라 검사하지 않는다.
    func testNoTrademarkNamesOnScreen() {
        let trademarks = ["Cherry", "Topre", "Gateron", "Kailh", "Logitech", "HP ", "IBM", "Apple"]
        for sound in SwitchSound.allCases {
            guard case let .recording(recorder, workTitle, links, _, modification)? = sound.credit?.origin else { continue }
            let texts = [sound.displayName, recorder, workTitle ?? "", modification] + links.map(\.title)
            for text in texts {
                for mark in trademarks {
                    XCTAssertFalse(text.localizedCaseInsensitiveContains(mark), "\(sound.rawValue): \(text)")
                }
            }
        }
    }
}
