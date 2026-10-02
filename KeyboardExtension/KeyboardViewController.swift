import UIKit

/// Full Access ON/OFF 각각에서 아래 네 가지를 확인하는 검증용 키보드.
///  1. App Group UserDefaults 읽기(메인 앱이 쓴 값이 보이는지)
///  2. AVAudioPlayer 커스텀 wav 재생 — 2026-10-02 실측: OFF 에서 play() false
///  3. AudioServices 커스텀 wav 재생 — 2026-10-02 실측: OFF 에서도 들림
///  4. 익스텐션 자체 UserDefaults.standard 쓰기/읽기(키보드 안에서 고른 설정이 유지되는지)
final class KeyboardViewController: UIInputViewController, UIInputViewAudioFeedback {
    var enableInputClicksWhenVisible: Bool { true }

    private let player = KeySoundPlayer()
    private let statusLabel = UILabel()
    private let logLabel = UILabel()
    private var mode: KeySoundPlayer.Mode = .avPlayer

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        refreshStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshStatus()
    }

    // MARK: - UI

    private func setupViews() {
        view.backgroundColor = UIColor.systemGray5

        statusLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center

        logLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        logLabel.numberOfLines = 0
        logLabel.textColor = .secondaryLabel

        let modeControl = UISegmentedControl(items: KeySoundPlayer.Mode.allCases.map(\.rawValue))
        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(modeChanged(_:)), for: .valueChanged)

        let keyRow = UIStackView(arrangedSubviews: ["ㄱ", "ㄴ", "ㄷ", "a", "b"].map(makeKey))
        keyRow.axis = .horizontal
        keyRow.spacing = 6
        keyRow.distribution = .fillEqually

        let controlRow = UIStackView(arrangedSubviews: [
            makeControl("🌐", action: #selector(handleInputModeList(from:with:)), events: .allTouchEvents),
            makeControl("space", action: #selector(spaceTapped)),
            makeControl("⌫", action: #selector(deleteTapped)),
            makeControl("↵", action: #selector(returnTapped)),
            makeControl("save", action: #selector(saveTapped)),
        ])
        controlRow.axis = .horizontal
        controlRow.spacing = 6
        controlRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [statusLabel, modeControl, keyRow, controlRow, logLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            keyRow.heightAnchor.constraint(equalToConstant: 44),
            controlRow.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    private func makeKey(_ title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 20)
        b.backgroundColor = .systemBackground
        b.layer.cornerRadius = 6
        b.addTarget(self, action: #selector(keyTapped(_:)), for: .touchDown)
        return b
    }

    private func makeControl(_ title: String, action: Selector, events: UIControl.Event = .touchUpInside) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.backgroundColor = .systemGray3
        b.layer.cornerRadius = 6
        b.addTarget(self, action: action, for: events)
        return b
    }

    // MARK: - Actions

    @objc private func keyTapped(_ sender: UIButton) {
        textDocumentProxy.insertText(sender.currentTitle ?? "")
        player.play(mode)
        refreshStatus()
    }

    @objc private func spaceTapped() {
        textDocumentProxy.insertText(" ")
        player.play(mode)
        refreshStatus()
    }

    @objc private func deleteTapped() {
        textDocumentProxy.deleteBackward()
        player.play(mode)
        refreshStatus()
    }

    @objc private func returnTapped() {
        textDocumentProxy.insertText("\n")
        player.play(mode)
        refreshStatus()
    }

    /// 익스텐션 자신의 UserDefaults.standard 에 카운터를 저장한다.
    /// 키보드를 닫았다 다시 열어도 Local 값이 남아 있으면 Full Access 없이 설정 유지가 가능하다는 뜻.
    @objc private func saveTapped() {
        let next = UserDefaults.standard.integer(forKey: "localCounter") + 1
        UserDefaults.standard.set(next, forKey: "localCounter")
        refreshStatus()
    }

    @objc private func modeChanged(_ sender: UISegmentedControl) {
        mode = KeySoundPlayer.Mode.allCases[sender.selectedSegmentIndex]
    }

    // MARK: - Status

    private func refreshStatus() {
        let shared = AppGroup.defaults?.string(forKey: AppGroup.Key.selectedSwitch)
        let local = UserDefaults.standard.object(forKey: "localCounter").map { "\($0)" } ?? "nil"
        statusLabel.text = """
        FullAccess: \(hasFullAccess ? "ON" : "OFF")   AppGroup: \(shared ?? "nil")   Local: \(local)
        """
        logLabel.text = (player.setupLog + player.log).joined(separator: "\n")
    }
}
