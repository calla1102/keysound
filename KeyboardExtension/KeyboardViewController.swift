import HangulEngine
import UIKit

/// 두벌식 한글 키보드. 키를 누를 때 press 음, 뗄 때 release 음을 낸다.
/// 조합 중 글자는 marked text 없이 「지우고 다시 쓰기」로 갱신한다.
final class KeyboardViewController: UIInputViewController {
    private let player = KeySoundPlayer()
    private var automaton = HangulAutomaton()

    private var currentLayer: KeyboardLayer = .hangul
    private var showsGlobe = true
    private var shiftOn = false

    private let rowsStack = UIStackView()
    private var keyButtons: [KeyButton] = []

    /// 백스페이스 길게 누르기 반복
    private var deleteTimer: Timer?
    /// 우리 편집 도중 textDidChange 가 불려도 조합을 끊지 않기 위한 표시
    private var isApplyingEdit = false

    private enum Metric {
        static let rowHeight: CGFloat = 42
        static let rowSpacing: CGFloat = 10
        static let keySpacing: CGFloat = 6
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.background

        rowsStack.axis = .vertical
        rowsStack.spacing = Metric.rowSpacing
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            rowsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 3),
            rowsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -3),
            rowsStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4),
        ])
        rebuildKeys()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 앱에서 바꾼 타건음을 키보드가 다시 열릴 때 반영한다
        player.load(AppGroup.selectedSound)
        automaton.commit()
        if showsGlobe != needsInputModeSwitchKey {
            showsGlobe = needsInputModeSwitchKey
            rebuildKeys()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopDeleteRepeat()
    }

    /// 사용자가 커서를 옮기거나 앱이 글을 바꾸면 조합을 확정한다.
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        guard !isApplyingEdit, automaton.isComposing else { return }
        // 문맥을 못 읽는 앱(nil)에선 조합을 유지한다
        if let before = textDocumentProxy.documentContextBeforeInput, !before.hasSuffix(automaton.composing) {
            automaton.commit()
        }
    }

    // MARK: - Layout

    private func rebuildKeys() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyButtons = []

        let rows = KeyboardLayout.rows(for: currentLayer, showsGlobe: showsGlobe)
        // 첫 줄 첫 키를 1칸 폭 기준으로 삼는다
        var unitKey: UIView?
        for (index, specs) in rows.enumerated() {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = Metric.keySpacing
            let height = row.heightAnchor.constraint(equalToConstant: Metric.rowHeight)
            height.priority = .defaultHigh + 1
            height.isActive = true

            // kbsim 녹음은 줄(R0~R4)마다 음높이가 다르다. 숫자 줄 R0 은 비우고 글자 줄을 R1~R3, 맨 아랫줄을 R4 로 쓴다.
            let soundRow = index == rows.count - 1 ? 4 : index + 1
            var flexibles: [UIView] = []
            for spec in specs {
                let keyView = spec.action == .spacer ? UIView() : makeKey(spec, soundRow: soundRow)
                row.addArrangedSubview(keyView)
                switch spec.width {
                case .units(let units):
                    if let unitKey {
                        keyView.widthAnchor.constraint(equalTo: unitKey.widthAnchor, multiplier: units).isActive = true
                    } else {
                        unitKey = keyView
                    }
                case .flexible:
                    if let first = flexibles.first {
                        keyView.widthAnchor.constraint(equalTo: first.widthAnchor).isActive = true
                    }
                    flexibles.append(keyView)
                }
            }
            rowsStack.addArrangedSubview(row)
        }
        refreshLabels()
    }

    private func makeKey(_ spec: KeySpec, soundRow: Int) -> KeyButton {
        let kind: KeySoundPlayer.Kind
        switch spec.action {
        case .space: kind = .space
        case .backspace: kind = .backspace
        case .enter: kind = .enter
        default: kind = .generic(row: soundRow)
        }

        let key = KeyButton(spec: spec, soundKind: kind)
        key.addTarget(self, action: #selector(keyDown(_:)), for: .touchDown)
        key.addTarget(self, action: #selector(keyUpInside(_:)), for: .touchUpInside)
        key.addTarget(self, action: #selector(keyUpOutside(_:)), for: [.touchUpOutside, .touchCancel])
        if spec.action == .nextKeyboard {
            key.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        }
        keyButtons.append(key)
        return key
    }

    private func refreshLabels() {
        for key in keyButtons {
            switch key.spec.action {
            case .character(let c):
                key.setLabel(title: String(shiftOn ? KeyboardLayout.shifted[c] ?? c : c))
            case .shift:
                key.setLabel(symbol: shiftOn ? "shift.fill" : "shift")
            case .backspace:
                key.setLabel(symbol: "delete.left")
            case .space:
                key.setLabel(title: "스페이스")
            case .enter:
                key.setLabel(symbol: "return")
            case .layer(.symbols):
                key.setLabel(title: "123")
            case .layer(.hangul):
                key.setLabel(title: "한")
            case .nextKeyboard:
                key.setLabel(symbol: "globe")
            case .spacer:
                break
            }
        }
    }

    // MARK: - Touch

    @objc private func keyDown(_ key: KeyButton) {
        player.play(.press, key.soundKind)
        if key.spec.action == .backspace {
            deleteBackward()
            startDeleteRepeat()
        }
    }

    @objc private func keyUpInside(_ key: KeyButton) {
        player.play(.release, key.soundKind)
        stopDeleteRepeat()
        perform(key.spec.action)
    }

    @objc private func keyUpOutside(_ key: KeyButton) {
        player.play(.release, key.soundKind)
        stopDeleteRepeat()
    }

    private func perform(_ action: KeyAction) {
        switch action {
        case .character(let c):
            let key = shiftOn ? KeyboardLayout.shifted[c] ?? c : c
            apply(automaton.input(key))
            if shiftOn {
                shiftOn = false
                refreshLabels()
            }
        case .shift:
            shiftOn.toggle()
            refreshLabels()
        case .space:
            automaton.commit()
            textDocumentProxy.insertText(" ")
        case .enter:
            automaton.commit()
            textDocumentProxy.insertText("\n")
        case .layer(let layer):
            automaton.commit()
            currentLayer = layer
            shiftOn = false
            rebuildKeys()
        case .backspace, .nextKeyboard, .spacer:
            // 백스페이스는 touchDown 에서, 🌐 는 시스템 핸들러가 처리한다
            break
        }
    }

    // MARK: - Editing

    private func apply(_ edit: TextEdit) {
        isApplyingEdit = true
        defer { isApplyingEdit = false }
        for _ in 0..<edit.deleteCount {
            textDocumentProxy.deleteBackward()
        }
        if !edit.insert.isEmpty {
            textDocumentProxy.insertText(edit.insert)
        }
    }

    private func deleteBackward() {
        if let edit = automaton.backspace() {
            apply(edit)
        } else {
            textDocumentProxy.deleteBackward()
        }
    }

    private func startDeleteRepeat() {
        stopDeleteRepeat()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.player.play(.press, .backspace)
                self?.deleteBackward()
            }
        }
    }

    private func stopDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
}
