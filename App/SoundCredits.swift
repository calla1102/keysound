import Foundation

/// 타건음 한 종의 출처. 원본 근거는 ThirdParty/CREDITS.md 와 ThirdParty/<녹음자>/LICENSE* 이고, 여기는 그 내용을 앱 안 표기용으로 옮긴 것이다.
/// 소리를 추가하면 `SwitchSound.credit` 의 switch 에 case 를 더한다(빠뜨리면 컴파일 에러).
/// 작품명은 CC BY 4.0 의 필수 표기가 아니라서, 원제목에 상표명이 있으면 nil 로 두고 출처 링크로 원본을 가리킨다.
struct SoundCredit: Equatable {
    enum License: Equatable {
        case cc0
        case ccBy4

        var name: String {
            switch self {
            case .cc0: "CC0 1.0"
            case .ccBy4: "CC BY 4.0"
            }
        }

        var uri: URL {
            switch self {
            case .cc0: URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")!
            case .ccBy4: URL(string: "https://creativecommons.org/licenses/by/4.0/")!
            }
        }

        /// CC BY 는 저작자·라이선스·변경 고지를 반드시 표시해야 한다.
        var requiresAttribution: Bool { self == .ccBy4 }
    }

    struct Link: Equatable {
        let title: String
        let url: URL
    }

    enum Origin: Equatable {
        /// 외부 녹음을 쓴 소리
        case recording(recorder: String, workTitle: String?, links: [Link], license: License, modification: String)
        /// 자체 합성음 — 외부 녹음 없음
        case synthesized
    }

    let origin: Origin
}

private func link(_ title: String, _ url: String) -> SoundCredit.Link {
    SoundCredit.Link(title: title, url: URL(string: url)!)
}

/// 모든 녹음 원본에 공통인 가공 내역(ThirdParty/CREDITS.md 「공통 가공」).
private let commonModification = "원본에서 키 한 번 분량을 잘라 모노 44.1kHz 로 변환하고 음량·페이드를 조정함"

/// 적축·청축 외에는 특수키 전용 녹음이 없어 눌림을 0.90~0.97 배로 낮춰 만든다(CREDITS.md 「파일별 구성」).
private let derivedSpecialKeys = "스페이스·엔터·백스페이스 소리는 눌림 음높이를 낮춰 만듦"

extension SwitchSound {
    /// 출처. 소리 없음(`.off`)은 소리 자체가 없어 nil.
    /// exhaustive switch 라 새 case 를 추가하면 여기서 컴파일러가 알려 준다.
    var credit: SoundCredit? {
        switch self {
        case .red:
            .init(origin: .recording(
                recorder: "Sadiquecat", workTitle: nil,
                links: [
                    link("Freesound 789628 (개별 키)", "https://freesound.org/people/Sadiquecat/sounds/789628/"),
                    link("Freesound 789629 (엔터)", "https://freesound.org/people/Sadiquecat/sounds/789629/"),
                    link("Freesound 789630 (스페이스)", "https://freesound.org/people/Sadiquecat/sounds/789630/"),
                ],
                license: .cc0,
                modification: commonModification))
        case .brown:
            .init(origin: .recording(
                recorder: "Foxfire-", workTitle: nil,
                links: [link("Freesound 570754", "https://freesound.org/people/Foxfire-/sounds/570754/")],
                license: .cc0,
                modification: "눌림 녹음 하나를 음높이·길이를 바꿔 여러 변주와 뗌 소리로 만들고 음량·페이드를 조정함, " + derivedSpecialKeys))
        case .blue:
            .init(origin: .recording(
                recorder: "UberBosser", workTitle: nil,
                links: [link("Freesound 팩 23846", "https://freesound.org/people/UberBosser/packs/23846/")],
                license: .cc0,
                modification: commonModification))
        case .black:
            .init(origin: .recording(
                recorder: "el_boss", workTitle: nil,
                links: [link("Freesound 643559", "https://freesound.org/people/el_boss/sounds/643559/")],
                license: .cc0,
                modification: commonModification + ", 잡음을 줄임, " + derivedSpecialKeys))
        case .topre:
            .init(origin: .recording(
                recorder: "MakotoHiramatsu", workTitle: "Press and Click FREE",
                links: [link("itch.io", "https://makotohiramatsu.itch.io/press-click-free")],
                license: .ccBy4,
                modification: "KEY_PRESS 녹음 9개를 골라 모노 44.1kHz 로 변환하고 키 단위로 잘라 음량·페이드를 조정함, " + derivedSpecialKeys))
        case .membrane:
            .init(origin: .recording(
                recorder: "Geoff Bremner (Geoff-Bremner-Audio)", workTitle: nil,
                links: [link("Freesound 705787", "https://freesound.org/s/705787/")],
                license: .ccBy4,
                modification: "연속 타이핑 녹음에서 키 단위로 잘라 모노 44.1kHz 로 변환하고 음량·페이드를 조정함, " + derivedSpecialKeys))
        case .buckling:
            .init(origin: .recording(
                recorder: "SamsterBirdies", workTitle: nil,
                links: [link("Freesound 489423", "https://freesound.org/s/489423/")],
                license: .cc0,
                modification: commonModification + ", 잡음을 줄임, " + derivedSpecialKeys))
        case .laptop:
            .init(origin: .recording(
                recorder: "justamudkip", workTitle: nil,
                links: [link("Freesound 853602", "https://freesound.org/s/853602/")],
                license: .cc0,
                modification: commonModification + ", " + derivedSpecialKeys))
        case .thock:
            .init(origin: .recording(
                recorder: "Techrul", workTitle: nil,
                links: [link("Freesound 815614", "https://freesound.org/s/815614/")],
                license: .cc0,
                modification: commonModification + ", " + derivedSpecialKeys))
        case .desktop:
            .init(origin: .recording(
                recorder: "suckmadeck", workTitle: nil,
                links: [link("Freesound 676417", "https://freesound.org/people/suckmadeck/sounds/676417/")],
                license: .cc0,
                modification: commonModification + ", " + derivedSpecialKeys))
        case .slim:
            .init(origin: .recording(
                recorder: "SoundsLikeFoley", workTitle: nil,
                links: [link("Freesound 421031", "https://freesound.org/people/SoundsLikeFoley/sounds/421031/")],
                license: .ccBy4,
                modification: "연속 타이핑 녹음에서 키 단위로 잘라 모노 44.1kHz 로 변환하고 음량·페이드를 조정함, " + derivedSpecialKeys))
        case .typewriter:
            .init(origin: .recording(
                recorder: "secretmojo", workTitle: nil,
                links: [link("Freesound 224012", "https://freesound.org/people/secretmojo/sounds/224012/")],
                license: .cc0,
                modification: commonModification + ", " + derivedSpecialKeys + ", 뗌 소리는 눌림을 높여 짧게 깎아 만듦"))
        case .click:
            .init(origin: .synthesized)
        case .off:
            nil
        }
    }
}

/// 번들 글꼴 한 종의 출처(자판 디자인 「픽셀」). 근거는 ThirdParty/CREDITS.md 「글꼴」과 ThirdParty/galmuri/OFL.txt.
struct FontCredit: Equatable {
    let name: String
    let author: String
    let copyright: String
    let licenseName: String
    let licenseURL: URL
    let sourceURL: URL
    let note: String

    static let galmuri = FontCredit(
        name: "갈무리11 (Galmuri11)",
        author: "Lee Minseo",
        copyright: "Copyright (c) 2019–2025 Lee Minseo (quiple@quiple.dev)",
        licenseName: "SIL Open Font License 1.1",
        licenseURL: URL(string: "https://openfontlicense.org")!,
        sourceURL: URL(string: "https://github.com/quiple/galmuri")!,
        note: "「픽셀」 자판 디자인에 원본 그대로(수정 없이) 포함함")
}
