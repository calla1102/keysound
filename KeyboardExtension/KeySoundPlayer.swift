import AVFoundation
import AudioToolbox

/// 실기기 검증용 재생기. 세 경로를 각각 시도해 어느 것이 Full Access 없이 동작하는지 기록한다.
///  - avPlayer: AVAudioSession(.ambient, mixWithOthers) + AVAudioPlayer (글쇠 방식)
///  - systemSound: AudioServicesPlaySystemSound 로 커스텀 wav 재생
///  - inputClick: UIDevice.playInputClick (시스템 기본 클릭, 항상 가능해야 함)
final class KeySoundPlayer {
    enum Mode: String, CaseIterable {
        case avPlayer = "AVAudioPlayer"
        case systemSound = "AudioServices"
    }

    /// init 단계 로그(세션·플레이어 준비 결과). 화면에 항상 유지된다.
    private(set) var setupLog: [String] = []
    /// 재생 호출 로그(최근 것만).
    private(set) var log: [String] = []
    private var setupDone = false

    private var player: AVAudioPlayer?
    private var systemSoundID: SystemSoundID = 0
    private var sessionReady = false

    private var soundURL: URL? {
        Bundle.main.url(forResource: "test_click", withExtension: "wav")
    }

    init() {
        prepareSession()
        preparePlayer()
        prepareSystemSound()
        setupDone = true
    }

    private func prepareSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            sessionReady = true
            record("session OK")
        } catch {
            record("session FAIL: \(describe(error))")
        }
    }

    private func preparePlayer() {
        guard let url = soundURL else {
            record("wav not found in bundle")
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = 1
            p.prepareToPlay()
            player = p
            record("player prepared")
        } catch {
            record("player FAIL: \(describe(error))")
        }
    }

    private func prepareSystemSound() {
        guard let url = soundURL else { return }
        let status = AudioServicesCreateSystemSoundID(url as CFURL, &systemSoundID)
        record(status == kAudioServicesNoError ? "systemSound prepared" : "systemSound create FAIL \(status)")
    }

    /// 반환값: 호출이 성공했는지(실제 소리가 들렸는지는 사람이 확인).
    @discardableResult
    func play(_ mode: Mode) -> Bool {
        switch mode {
        case .avPlayer:
            guard let player else {
                record("play av: no player")
                return false
            }
            player.currentTime = 0
            let ok = player.play()
            record("play av: \(ok ? "called OK" : "play() returned false")")
            return ok
        case .systemSound:
            guard systemSoundID != 0 else {
                record("play sys: no sound id")
                return false
            }
            AudioServicesPlaySystemSound(systemSoundID)
            record("play sys: called")
            return true
        }
    }

    private func record(_ line: String) {
        if !setupDone {
            setupLog.append(line)
            return
        }
        log.append(line)
        if log.count > 4 { log.removeFirst() }
    }

    private func describe(_ error: Error) -> String {
        let e = error as NSError
        return "\(e.domain) \(e.code)"
    }
}
