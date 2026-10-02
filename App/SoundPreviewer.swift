import AudioToolbox
import Foundation

/// 축 선택 화면 미리듣기. 키보드와 같은 AudioServices 로 재생한다.
/// SystemSoundID 는 마지막 하나만 들고 있다가 다른 소리를 고르면 해제한다.
final class SoundPreviewer {
    private var current: (name: String, id: SystemSoundID)?

    deinit {
        dispose()
    }

    func preview(_ sound: SwitchSound) {
        guard let name = sound.previewFileName else { return }
        if current?.name != name {
            dispose()
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
                assertionFailure("앱 번들에 \(name).wav 가 없다 — project.yml 앱 타깃 includes 확인")
                return
            }
            var id: SystemSoundID = 0
            guard AudioServicesCreateSystemSoundID(url as CFURL, &id) == kAudioServicesNoError else { return }
            current = (name, id)
        }
        if let id = current?.id {
            AudioServicesPlaySystemSound(id)
        }
    }

    private func dispose() {
        if let id = current?.id { AudioServicesDisposeSystemSoundID(id) }
        current = nil
    }
}
