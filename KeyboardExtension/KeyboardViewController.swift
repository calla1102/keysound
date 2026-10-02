import HangulEngine
import UIKit

/// 두벌식 한글 키보드. 키를 누를 때(touchDown) 입력하고 press 음, 뗄 때 release 음을 낸다.
/// 입력을 touchDown 에 하는 이유: 롤오버로 앞 키를 떼기 전에 다음 키를 눌러도 누른 순서대로 들어가고,
/// 손가락이 키 밖에서 떨어져도 입력이 사라지지 않으며, 소리와 글자가 같은 순간에 나온다(iOS 기본 키보드와 같다).
/// 조합 중 글자는 marked text 없이 「지우고 다시 쓰기」로 갱신한다.
final class KeyboardViewController: UIInputViewController {
    private let player = KeySoundPlayer()
    private var automaton = HangulAutomaton()

    private var currentLayer: KeyboardLayer = .hangul
    private var showsGlobe = true
    private var shiftOn = false

    private let touchView = KeyboardTouchView()
    private let rowsStack = UIStackView()
    private var keyButtons: [KeyButton] = []

    /// 백스페이스 길게 누르기 반복
    private var deleteTimer: Timer?
    /// 우리 편집 도중 textDidChange 가 불려도 조합을 끊지 않기 위한 표시
    private var isApplyingEdit = false
    /// 우리 마지막 편집 시각. 호스트 앱은 문맥(documentContext)을 한발 늦게 갱신하므로 이 직후의 불일치는 믿지 않는다.
    private var lastEditTime: CFTimeInterval = 0
    private var contextRecheck: DispatchWorkItem?
    private static let contextGrace: CFTimeInterval = 0.3

    private enum Metric {
        static let rowHeight: CGFloat = 42
        static let rowSpacing: CGFloat = 10
        static let keySpacing: CGFloat = 6
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.background

        // 키보드 전체가 터치 영역이다. 키 사이 간격과 가장자리 터치도 가장 가까운 키로 보낸다
        touchView.translatesAutoresizingMaskIntoConstraints = false
        touchView.onKeyDown = { [weak self] key in self?.keyDown(key) }
        touchView.onKeyUp = { [weak self] key in self?.keyUp(key) }
        view.addSubview(touchView)
        NSLayoutConstraint.activate([
            touchView.topAnchor.constraint(equalTo: view.topAnchor),
            touchView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            touchView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            touchView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        rowsStack.axis = .vertical
        // 시스템이 정한 키보드 높이가 콘텐츠와 달라도 모든 줄이 같은 높이로 늘거나 준다
        rowsStack.distribution = .fillEqually
        rowsStack.spacing = Metric.rowSpacing
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        touchView.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: touchView.topAnchor, constant: 8),
            rowsStack.leadingAnchor.constraint(equalTo: touchView.leadingAnchor, constant: 3),
            rowsStack.trailingAnchor.constraint(equalTo: touchView.trailingAnchor, constant: -3),
            rowsStack.bottomAnchor.constraint(equalTo: touchView.bottomAnchor, constant: -4),
        ])
        rebuildKeys()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 앱에서 바꾼 타건음을 키보드가 다시 열릴 때 반영한다
        player.load(AppGroup.selectedSound)
        automaton.commit()
        if shiftOn {
            shiftOn = false
            refreshLabels()
        }
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
    /// 빠르게 치는 중에는 우리가 방금 한 편집의 알림이 늦게 도착해 문맥이 아직 옛 값일 수 있다.
    /// 그 불일치로 조합을 끊으면 다음 입력이 엉뚱한 글자를 지우므로, 마지막 편집 직후엔 판정을 미루고 안정된 뒤 다시 본다.
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        validateComposition()
    }

    private func validateComposition() {
        guard !isApplyingEdit, automaton.isComposing else { return }
        let elapsed = CACurrentMediaTime() - lastEditTime
        if elapsed < Self.contextGrace {
            contextRecheck?.cancel()
            let work = DispatchWorkItem { [weak self] in self?.validateComposition() }
            contextRecheck = work
            DispatchQueue.main.asyncAfter(deadline: .now() + (Self.contextGrace - elapsed + 0.02), execute: work)
            return
        }
        // 문맥을 못 읽는 앱(nil)에선 조합을 유지한다
        if let before = textDocumentProxy.documentContextBeforeInput, !before.hasSuffix(automaton.composing) {
            automaton.commit()
        }
    }

    // MARK: - Layout

    private func rebuildKeys() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyButtons = []
        defer { touchView.keys = keyButtons }

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
            // 다른 줄의 기준 키와 폭 제약을 걸려면 먼저 같은 뷰 계층에 붙어 있어야 한다
            rowsStack.addArrangedSubview(row)

            // kbsim 녹음은 줄(R0~R4)마다 음높이가 다르다. 숫자 줄 R0 은 비우고 글자 줄을 R1~R3, 맨 아랫줄을 R4 로 쓴다.
            let soundRow = index == rows.count - 1 ? 4 : index + 1
            var flexibles: [UIView] = []
            for spec in specs {
                let keyView = spec.action == .spacer ? UIView() : makeKey(spec, soundRow: soundRow)
                row.addArrangedSubview(keyView)
                switch spec.width {
                case .units(let units):
                    if let unitKey {
                        // 폭이 0인 초기 레이아웃에서 충돌하지 않도록 required 보다 한 단계 낮춘다
                        let width = keyView.widthAnchor.constraint(equalTo: unitKey.widthAnchor, multiplier: units)
                        width.priority = .required - 1
                        width.isActive = true
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
        if spec.action == .nextKeyboard {
            // 🌐 만 버튼이 직접 터치를 받는다(시스템 핸들러가 이벤트를 필요로 함). 소리만 여기서 낸다
            key.addTarget(self, action: #selector(globeDown(_:)), for: .touchDown)
            key.addTarget(self, action: #selector(globeUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            key.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        } else {
            // 나머지는 KeyboardTouchView 가 터치를 받아 가장 가까운 키로 보낸다
            key.isUserInteractionEnabled = false
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

    private func keyDown(_ key: KeyButton) {
        player.play(.press, key.soundKind)
        if key.spec.action == .backspace {
            deleteBackward()
            startDeleteRepeat()
        } else {
            handle(key.spec.action)
        }
    }

    private func keyUp(_ key: KeyButton) {
        player.play(.release, key.soundKind)
        // 롤오버 중 다른 키를 뗄 때 백스페이스 반복을 끊지 않는다
        if key.spec.action == .backspace {
            stopDeleteRepeat()
        }
    }

    @objc private func globeDown(_ key: KeyButton) {
        player.play(.press, key.soundKind)
    }

    @objc private func globeUp(_ key: KeyButton) {
        player.play(.release, key.soundKind)
    }

    private func handle(_ action: KeyAction) {
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
            lastEditTime = CACurrentMediaTime()
        case .enter:
            automaton.commit()
            textDocumentProxy.insertText("\n")
            lastEditTime = CACurrentMediaTime()
        case .layer(let layer):
            automaton.commit()
            currentLayer = layer
            shiftOn = false
            rebuildKeys()
        case .backspace, .nextKeyboard, .spacer:
            // 백스페이스는 keyDown 에서 따로 처리하고, 🌐 는 시스템 핸들러가 처리한다
            break
        }
    }

    // MARK: - Editing

    private func apply(_ edit: TextEdit) {
        isApplyingEdit = true
        defer {
            isApplyingEdit = false
            lastEditTime = CACurrentMediaTime()
        }
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
            lastEditTime = CACurrentMediaTime()
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
