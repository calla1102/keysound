/// 키보드에서 고를 수 있는 타건음. rawValue 가 App Group 에 저장된다.
enum SwitchSound: String, CaseIterable, Identifiable {
    /// kbsim `mxbrown` 녹음
    case brown
    /// 자체 합성 40ms 클릭
    case click
    case off

    static let `default`: SwitchSound = .brown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .brown: "갈축"
        case .click: "기본 클릭"
        case .off: "소리 끔"
        }
    }

    var summary: String {
        switch self {
        case .brown: "부드러운 걸림이 있는 택타일 축"
        case .click: "짧고 가벼운 합성음"
        case .off: "타건음 없이 입력만"
        }
    }
}
