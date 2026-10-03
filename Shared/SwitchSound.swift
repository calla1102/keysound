/// 키보드에서 고를 수 있는 타건음. rawValue 가 App Group 에 저장된다.
enum SwitchSound: String, CaseIterable, Identifiable {
    // allCases 순서 = 묶음 안 표시 순서(묶음 순서는 Group.allCases). 묶음 순서와 맞춰 두면 읽기 쉽다.

    /// UberBosser 녹음(Freesound 421581~421584, CC0). 스페이스·엔터·백스페이스 전용 녹음 없음 → 일반 키 소리로 대체
    case blue
    /// SamsterBirdies 녹음(Freesound 489423, CC0)
    case buckling
    /// Foxfire- 녹음(Freesound 570754, CC0). 뗌은 눌림을 깎아 만든 틱
    case brown
    /// Sadiquecat 녹음(Freesound 789628~789630, CC0)
    case red
    /// el_boss Gateron 흑축 녹음(Freesound 643559, CC0) + 잡음 제거
    case black
    /// Techrul 녹음(Freesound 815614, CC0)
    case thock
    /// MakotoHiramatsu HHKB 녹음(itch.io 「Press and Click FREE」, CC BY 4.0 — 앱 출처 표기 필수)
    case topre
    /// Geoff-Bremner-Audio 녹음(Freesound 705787, CC BY 4.0 — 앱 출처 표기 필수)
    case membrane
    /// justamudkip 녹음(Freesound 853602, CC0)
    case laptop
    /// suckmadeck 녹음(Freesound 676417, 2002년 데스크탑 키보드, CC0)
    case desktop
    /// SoundsLikeFoley 녹음(Freesound 421031, 소형 블루투스 키보드, CC BY 4.0 — 앱 출처 표기 필수)
    case slim
    /// secretmojo 녹음(Freesound 224012, 전동 타자기, CC0). 뗌 소리가 없어 눌림을 깎은 틱으로 대체
    case typewriter
    /// 자체 합성 40ms 클릭
    case click
    case off

    static let `default`: SwitchSound = .brown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brown: "갈축"
        case .blue: "청축"
        case .red: "적축"
        case .black: "흑축"
        case .topre: "무접점"
        case .buckling: "버클링 스프링"
        case .membrane: "멤브레인"
        case .laptop: "노트북"
        case .desktop: "구형 데스크탑"
        case .slim: "얇은 무선 키보드"
        case .typewriter: "전동 타자기"
        case .thock: "도각 리니어"
        case .click: "기본 클릭"
        case .off: "소리 끔"
        }
    }

    var summary: String {
        switch self {
        case .brown: "부드러운 걸림이 있는 택타일 축"
        case .blue: "또렷한 클릭음이 나는 클리키 축"
        case .red: "걸림 없이 가볍고 조용한 리니어 축"
        case .black: "묵직하고 낮은 리니어 축"
        case .topre: "도톰하고 둔탁한 정전용량 무접점"
        case .buckling: "스프링이 꺾이며 울리는 금속성 클릭"
        case .membrane: "사무용 멤브레인 키보드의 가볍고 둔한 소리"
        case .laptop: "노트북 가위식 키의 얇고 짧은 소리"
        case .desktop: "오래된 데스크탑 키보드의 푹신하고 둔탁한 소리"
        case .slim: "작고 얇은 무선 키보드의 가볍고 건조한 소리"
        case .typewriter: "활자가 종이를 때리는 듯 날카로운 타자기 소리"
        case .thock: "둔탁하게 도각거리는 커스텀 키보드 소리"
        case .click: "짧고 가벼운 합성음"
        case .off: "타건음 없이 입력만"
        }
    }

    /// 번들 wav 파일 이름 접두어. nil 이면 소리가 없다(소리 끔).
    /// 파일 이름 규칙 `<접두어>_<press|release>_<이름>` 은 `KeySoundPlayer.fileName`·`previewFileName`·project.yml 앱 타깃 includes 가 함께 따른다.
    var filePrefix: String? {
        switch self {
        case .brown: "brown"
        case .blue: "blue"
        case .red: "red"
        case .black: "black"
        case .topre: "topre"
        case .buckling: "buckling"
        case .membrane: "membrane"
        case .laptop: "laptop"
        case .desktop: "desktop"
        case .slim: "scissor"
        case .typewriter: "typewriter"
        case .thock: "thock"
        case .click: "click"
        case .off: nil
        }
    }

    /// 스페이스·엔터·백스페이스 전용 녹음이 있는지. 없으면 일반 키 소리를 쓴다.
    /// 새 축을 추가하면 여기서 반드시 정한다(true 인데 파일이 없으면 그 키는 무음).
    var hasSpecialKeySounds: Bool {
        switch self {
        case .brown, .red, .black, .topre, .buckling, .membrane, .laptop, .thock, .desktop, .slim, .typewriter: true
        case .blue, .click, .off: false
        }
    }

    /// 메인 앱 미리듣기용 번들 wav (두 타깃 모두에 들어 있다).
    /// 이름을 바꾸면 project.yml 앱 타깃의 `*_press_generic_r2.wav` includes 도 맞춘다.
    var previewFileName: String? {
        switch self {
        case .brown, .blue, .red, .black, .topre, .buckling, .membrane, .laptop, .thock, .desktop, .slim, .typewriter: filePrefix.map { "\($0)_press_generic_r2" }
        case .click: "click_press"
        case .off: nil
        }
    }

    /// 앱 목록의 묶음. 소리 특성 기준이며 선언 순서가 표시 순서다. 종류가 늘면 case 와 `group` 한 줄씩 추가한다.
    enum Group: CaseIterable, Identifiable {
        case clicky, tactile, linear, capacitiveAndMembrane, laptop, typewriter, other

        var id: Self { self }

        var displayName: String {
            switch self {
            case .clicky: "클릭"
            case .tactile: "택타일"
            case .linear: "리니어"
            case .capacitiveAndMembrane: "무접점·멤브레인"
            case .laptop: "노트북·슬림"
            case .typewriter: "타자기"
            case .other: "기타"
            }
        }

        /// 이 묶음에 속한 소리. `SwitchSound.allCases` 순서를 따른다.
        var sounds: [SwitchSound] { SwitchSound.allCases.filter { $0.group == self } }
    }

    var group: Group {
        switch self {
        case .blue, .buckling: .clicky
        case .brown: .tactile
        case .red, .black, .thock: .linear
        case .topre, .membrane, .desktop: .capacitiveAndMembrane
        case .laptop, .slim: .laptop
        case .typewriter: .typewriter
        case .click, .off: .other
        }
    }
}
