import Foundation

/// 메인 앱과 키보드 익스텐션이 공유하는 설정 저장소.
/// 익스텐션은 Full Access가 켜져 있을 때만 이 값을 읽을 수 있다.
enum AppGroup {
    static let identifier = "group.com.minnnj.keysound"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    enum Key {
        /// 사용자가 선택한 축(스위치) 식별자
        static let selectedSwitch = "selectedSwitch"
    }
}
