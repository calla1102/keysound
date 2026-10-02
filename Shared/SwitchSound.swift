/// 키보드에서 고를 수 있는 타건음. rawValue 가 App Group 에 저장된다.
enum SwitchSound: String, CaseIterable, Identifiable {
    /// kbsim `mxbrown` 녹음
    case brown
    /// kbsim `mxblue` 녹음 (스페이스·엔터·백스페이스 전용 녹음 없음 → 일반 키 소리로 대체)
    case blue
    /// kbsim `redink` 녹음
    case red
    /// kbsim `mxblack` 녹음
    case black
    /// kbsim `topre` 녹음
    case topre
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
        case .click: "짧고 가벼운 합성음"
        case .off: "타건음 없이 입력만"
        }
    }

    /// 번들 wav 파일 이름 접두어. nil 이면 녹음 파일이 없다(소리 끔).
    var filePrefix: String? {
        switch self {
        case .brown: "brown"
        case .blue: "blue"
        case .red: "red"
        case .black: "black"
        case .topre: "topre"
        case .click: "click"
        case .off: nil
        }
    }

    /// 스페이스·엔터·백스페이스 전용 녹음이 있는지. 없으면 일반 키 소리를 쓴다.
    var hasSpecialKeySounds: Bool {
        self != .blue
    }

    /// 메인 앱 미리듣기용 번들 wav (두 타깃 모두에 들어 있다).
    var previewFileName: String? {
        switch self {
        case .off: nil
        case .click: "click_press"
        default: filePrefix.map { "\($0)_press_generic_r2" }
        }
    }
}
