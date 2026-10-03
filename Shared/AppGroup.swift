import Foundation

/// 메인 앱과 키보드 익스텐션이 공유하는 설정 저장소.
/// 2026-10-02 실기기(iOS 27) 검증: 전체 접근 OFF 에서도 익스텐션이 이 값을 읽는다.
enum AppGroup {
    static let identifier = "group.com.minnnj.keysound"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    enum Key {
        /// 사용자가 선택한 타건음(`SwitchSound.rawValue`)
        static let selectedSound = "selectedSound"
        /// 사용자가 선택한 자판 디자인(`KeyboardTheme.rawValue`)
        static let selectedTheme = KeyboardTheme.storageKey
    }

    static var selectedSound: SwitchSound {
        defaults?.string(forKey: Key.selectedSound).flatMap(SwitchSound.init(rawValue:)) ?? .default
    }

    static var selectedTheme: KeyboardTheme {
        KeyboardTheme.load(from: defaults)
    }
}
