import AudioToolbox

/// 타건음 재생기. 전체 접근 없이 동작하는 AudioServices 시스템 사운드만 쓴다.
/// (2026-10-02 실기기 검증: AVAudioPlayer 는 전체 접근 OFF 에서 play() 실패)
/// 제약: 볼륨은 시스템 볼륨을 따르고, 무음 스위치가 켜지면 나지 않는다.
final class KeySoundPlayer {
    enum Phase: String {
        case press, release
    }

    enum Kind {
        /// kbsim 은 키보드 줄(0~4)마다 음높이가 다른 녹음을 쓴다.
        case generic(row: Int)
        case space, backspace, enter
    }

    private(set) var sound: SwitchSound?
    private var ids: [String: SystemSoundID] = [:]

    deinit {
        disposeAll()
    }

    /// 선택된 타건음의 파일을 미리 SystemSoundID 로 만들어 둔다. 같은 소리면 아무것도 하지 않는다.
    func load(_ sound: SwitchSound) {
        guard sound != self.sound else { return }
        disposeAll()
        self.sound = sound

        let kinds: [Kind] = (0...4).map { .generic(row: $0) } + [.space, .backspace, .enter]
        for phase in [Phase.press, .release] {
            for kind in kinds {
                guard let name = Self.fileName(sound, phase, kind), ids[name] == nil else { continue }
                guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else { continue }
                var id: SystemSoundID = 0
                if AudioServicesCreateSystemSoundID(url as CFURL, &id) == kAudioServicesNoError {
                    ids[name] = id
                }
            }
        }
    }

    func play(_ phase: Phase, _ kind: Kind) {
        guard let sound, let name = Self.fileName(sound, phase, kind), let id = ids[name] else { return }
        AudioServicesPlaySystemSound(id)
    }

    private func disposeAll() {
        ids.values.forEach { AudioServicesDisposeSystemSoundID($0) }
        ids = [:]
    }

    /// 번들 안 wav 파일 이름(확장자 제외). nil 이면 그 동작엔 소리가 없다.
    private static func fileName(_ sound: SwitchSound, _ phase: Phase, _ kind: Kind) -> String? {
        guard let prefix = sound.filePrefix else { return nil }
        if sound == .click {
            return phase == .press ? "click_press" : nil
        }
        var kind = kind
        if !sound.hasSpecialKeySounds {
            switch kind {
            case .generic: break
            case .space, .backspace, .enter: kind = .generic(row: 2)
            }
        }
        let suffix: String
        switch kind {
        case .generic(let row):
            suffix = phase == .press ? "generic_r\(min(max(row, 0), 4))" : "generic"
        case .space: suffix = "space"
        case .backspace: suffix = "backspace"
        case .enter: suffix = "enter"
        }
        return "\(prefix)_\(phase.rawValue)_\(suffix)"
    }
}
