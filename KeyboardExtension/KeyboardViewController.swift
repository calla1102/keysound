import HangulEngine
import KeyboardCore
import UIKit

/// 두벌식 한글 키보드. 키를 누를 때(touchDown) 입력하고 press 음, 뗄 때 release 음을 낸다.
/// 입력을 touchDown 에 하는 이유: 롤오버로 앞 키를 떼기 전에 다음 키를 눌러도 누른 순서대로 들어가고,
/// 손가락이 키 밖에서 떨어져도 입력이 사라지지 않으며, 소리와 글자가 같은 순간에 나온다(iOS 기본 키보드와 같다).
/// 조합 중 글자는 marked text 없이 「지우고 다시 쓰기」로 갱신한다.
final class KeyboardViewController: UIInputViewController {
    private let player = KeySoundPlayer()
    private var automaton = HangulAutomaton()

    private var currentLayer: KeyboardLayer = .hangul
    /// 기호 레이어에서 돌아갈 글자 레이어. 마지막으로 쓴 언어.
    private var lettersLayer: KeyboardLayer = .hangul
    private var showsGlobe = true
    private var shift = ShiftState()
    /// 익스텐션 자체 UserDefaults 에 마지막 언어를 기억한다(Full Access 없이 동작)
    private static let lastLayerKey = "lastLettersLayer"

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
    /// 최근 우리가 만든 조합 글자와 시각(오래된 순). 유예 중 호스트 문맥은 이 중 하나로 끝나는 옛 값일 수 있다.
    /// 빈 문자열은 「조합이 없던 상태」라 그 앞 문맥을 알 수 없다는 뜻이다.
    private var recentComposings: [(text: String, at: CFTimeInterval)] = []

    // MARK: 스페이스 길게 누르기(커서 이동)
    //
    // 공백 입력 시점: 길게 눌러 커서 이동 모드로 갈 수 있으므로 스페이스는 keyDown 에서 바로 넣지 않고
    // 「보류(pendingSpace)」했다가 (1) 판정 시간 안에 떼면 keyUp 에서, (2) 그 전에 다른 키가 눌리면 그 키보다 먼저 넣는다.
    // (2) 덕분에 스페이스를 누른 채 다음 글자를 치는 롤오버에서도 「공백 → 글자」 순서가 유지된다.
    // 보류 중 눌린 키의 소리·입력은 평소와 같다. 보류 때문에 늦어지는 건 스페이스 자신뿐(뗄 때까지).
    // 이동 모드 중 다른 손가락의 키 터치는 소리·입력 모두 무시한다(ignoredTouches 로 뗄 때 소리도 막는다).
    // 이동 칸마다 소리·진동은 내지 않는다(기본 키보드와 같다. 진동은 Full Access 없이는 불확실). 진입 때 press 음은 이미 났고 뗄 때 release 음이 난다.
    private static let spaceLongPressDelay: TimeInterval = 0.4
    private var pendingSpaceTouch: ObjectIdentifier?
    private var longPressTimer: Timer?
    private var cursorTouch: ObjectIdentifier?
    private var cursorTracker = CursorDragTracker()
    private var lastSpaceX: CGFloat = 0
    private var ignoredTouches: Set<ObjectIdentifier> = []

    private enum Metric {
        static let rowHeight: CGFloat = 42
        static let rowSpacing: CGFloat = 10
        static let keySpacing: CGFloat = 6
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.background
        if let raw = UserDefaults.standard.string(forKey: Self.lastLayerKey),
           let saved = KeyboardLayer(rawValue: raw), saved.isLetters {
            currentLayer = saved
            lettersLayer = saved
        }

        // 키보드 전체가 터치 영역이다. 키 사이 간격과 가장자리 터치도 가장 가까운 키로 보낸다
        touchView.translatesAutoresizingMaskIntoConstraints = false
        touchView.onKeyDown = { [weak self] key, touch in self?.keyDown(key, touch) ?? false }
        touchView.onKeyUp = { [weak self] key, touch in self?.keyUp(key, touch) }
        touchView.onKeyMove = { [weak self] key, touch in self?.keyMove(key, touch) }
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
        commitComposition()
        if shift.mode == .once {
            shift.clearOnce()
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
        contextRecheck?.cancel()
        // 누른 스페이스는 떼기 전에 사라져도 입력으로 친다(터치 cancel 도 같다). 보류 전 keyDown 즉시 입력과 같은 결과다
        flushPendingSpace()
        endCursorMode()
        ignoredTouches = []
        touchView.resetTouches()
    }

    /// 사용자가 커서를 옮기거나 앱이 글을 바꾸면 조합을 확정한다. 커서 이동은 selectionDidChange 로도 들어온다.
    /// 우리 자신의 편집도 같은 알림을 부르므로, 문맥이 「우리가 만든 조합으로 끝나는지」로 구분한다.
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        validateComposition()
    }

    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        validateComposition()
    }

    private func commitComposition() {
        automaton.commit()
        noteComposingState()
        contextRecheck?.cancel()
    }

    private func noteComposingState() {
        let now = CACurrentMediaTime()
        recentComposings.append((automaton.composing, now))
        recentComposings.removeAll { now - $0.at > Self.contextGrace * 2 }
    }

    /// 조합 중인 글자가 문맥과 어긋났는지(커서가 옮겨졌거나 앱이 글을 바꿨는지).
    /// 빠르게 치는 중엔 호스트 문맥이 한발 늦어 옛 조합 글자로 끝날 수 있으므로,
    /// 마지막 편집 직후(유예 중)엔 최근 조합 글자 중 하나로 끝나기만 해도 정상으로 본다.
    /// 오탐(정상 타이핑 중 조합이 끊김)이 미탐(드문 오삭제)보다 나쁘므로 유예 중엔 관대하게 판정한다.
    private func compositionIsStale() -> Bool {
        guard automaton.isComposing else { return false }
        // 문맥을 못 읽는 앱(nil)에선 조합을 유지한다
        guard let before = textDocumentProxy.documentContextBeforeInput else { return false }
        if before.hasSuffix(automaton.composing) { return false }
        let now = CACurrentMediaTime()
        if now - lastEditTime < Self.contextGrace {
            // 조합이 방금 시작됐으면(빈 상태가 기록에 있으면) 옛 문맥을 알 수 없으므로 믿지 않는다
            return !recentComposings.contains { now - $0.at <= Self.contextGrace * 2 && ($0.text.isEmpty || before.hasSuffix($0.text)) }
        }
        return true
    }

    private func validateComposition() {
        guard !isApplyingEdit, automaton.isComposing else { return }
        if compositionIsStale() {
            commitComposition()
            return
        }
        // 유예 중이라 문맥이 옛 값일 수 있다. 안정된 뒤 한 번 더 본다.
        let elapsed = CACurrentMediaTime() - lastEditTime
        if elapsed < Self.contextGrace {
            contextRecheck?.cancel()
            let work = DispatchWorkItem { [weak self] in self?.validateComposition() }
            contextRecheck = work
            DispatchQueue.main.asyncAfter(deadline: .now() + (Self.contextGrace - elapsed + 0.02), execute: work)
        }
    }

    // MARK: - Layout

    private func rebuildKeys() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyButtons = []
        defer { touchView.keys = keyButtons }

        let rows = KeyboardLayout.rows(for: currentLayer, showsGlobe: showsGlobe, lettersLayer: lettersLayer)
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
            // 이동 모드 중 레이어 전환으로 키를 다시 만들어도 라벨은 숨긴 채로
            key.setLabelHidden(cursorTouch != nil)
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
                key.setLabel(title: String(displayed(c)))
            case .shift:
                // 꺼짐 / 1회(채운 화살표) / 캡스락(캡스락 기호 + 밝은 배경)
                switch shift.mode {
                case .off: key.setLabel(symbol: "shift")
                case .once: key.setLabel(symbol: "shift.fill")
                case .caps: key.setLabel(symbol: "capslock.fill")
                }
                key.setEmphasized(shift.mode != .off)
            case .backspace:
                key.setLabel(symbol: "delete.left")
            case .space:
                key.setLabel(title: "스페이스")
            case .enter:
                key.setLabel(symbol: "return")
            case .layer(.symbols):
                key.setLabel(title: "123")
            case .layer(.moreSymbols):
                key.setLabel(title: "#+=")
            case .layer(.hangul):
                key.setLabel(title: "한")
            case .layer(.english):
                key.setLabel(title: "EN")
            case .nextKeyboard:
                key.setLabel(symbol: "globe")
            case .spacer:
                break
            }
        }
    }

    // MARK: - Touch

    /// 이 터치를 받아들였는지 돌려준다. 이동 모드 중 다른 키는 무시(false)해 눌림 표시도 켜지 않는다.
    private func keyDown(_ key: KeyButton, _ touch: KeyboardTouchView.TouchInfo) -> Bool {
        if cursorTouch != nil {
            ignoredTouches.insert(touch.id)
            return false
        }
        player.play(.press, key.soundKind)
        // 보류 중인 공백이 있으면 이 키보다 먼저 넣어 입력 순서를 지킨다
        flushPendingSpace()
        if key.spec.action == .space {
            stopDeleteRepeat()
            pendingSpaceTouch = touch.id
            lastSpaceX = touch.x
            longPressTimer = Timer.scheduledTimer(withTimeInterval: Self.spaceLongPressDelay, repeats: false) { [weak self] _ in
                self?.beginCursorMode()
            }
            return true
        }
        // 유예 중이라도 커서가 옮겨졌으면 조합을 끊어, 새 커서 앞 글자를 지우지 않게 한다
        if compositionIsStale() { commitComposition() }
        switch key.spec.action {
        case .backspace:
            deleteBackward()
            startDeleteRepeat()
        case .layer:
            // 레이어 전환은 뗄 때 한다. 누르는 순간 키를 다시 만들면 눌림 표시가 옛 키에 남고,
            // 같은 이벤트에 함께 들어온 글자가 어느 레이어로 찍힐지 정해지지 않는다
            stopDeleteRepeat()
        default:
            // 다른 키를 누르면 백스페이스 반복을 끊는다. 안 끊으면 방금 친 글자를 반복 삭제가 지운다
            stopDeleteRepeat()
            handle(key.spec.action)
        }
        return true
    }

    private func keyUp(_ key: KeyButton, _ touch: KeyboardTouchView.TouchInfo) {
        if ignoredTouches.remove(touch.id) != nil { return }
        player.play(.release, key.soundKind)
        switch key.spec.action {
        case .space:
            if cursorTouch == touch.id {
                endCursorMode()
            } else if pendingSpaceTouch == touch.id {
                flushPendingSpace()
            }
        case .backspace:
            // 다른 손가락이 아직 백스페이스를 누르고 있으면 반복을 이어 간다
            // 이동 모드 중 눌러 무시된 백스페이스는 세지 않는다
            let stillHeld = touchView.hasActiveTouch { key, id in key.spec.action == .backspace && !ignoredTouches.contains(id) }
            if !stillHeld { stopDeleteRepeat() }
        case .layer:
            handle(key.spec.action)
        default:
            break
        }
    }

    private func keyMove(_ key: KeyButton, _ touch: KeyboardTouchView.TouchInfo) {
        if pendingSpaceTouch == touch.id { lastSpaceX = touch.x }
        guard cursorTouch == touch.id else { return }
        let cells = cursorTracker.move(to: touch.x)
        if cells != 0 { textDocumentProxy.adjustTextPosition(byCharacterOffset: cells) }
    }

    private func flushPendingSpace() {
        guard pendingSpaceTouch != nil else { return }
        longPressTimer?.invalidate()
        longPressTimer = nil
        pendingSpaceTouch = nil
        handle(.space)
    }

    /// 판정 시간 동안 스페이스가 눌려 있었다. 공백은 넣지 않고 조합만 확정한 뒤 이동 모드로 간다.
    private func beginCursorMode() {
        guard let touch = pendingSpaceTouch else { return }
        longPressTimer = nil
        pendingSpaceTouch = nil
        cursorTouch = touch
        commitComposition()
        cursorTracker.begin(at: lastSpaceX)
        keyButtons.forEach { $0.setLabelHidden(true) }
    }

    private func endCursorMode() {
        guard cursorTouch != nil else { return }
        cursorTouch = nil
        keyButtons.forEach { $0.setLabelHidden(false) }
    }

    // 🌐 는 시스템 핸들러가 직접 받아 이동 모드 중에도 키보드 전환을 막을 수 없다(의도된 예외). 소리만 다른 키처럼 막는다.
    @objc private func globeDown(_ key: KeyButton) {
        guard cursorTouch == nil else { return }
        player.play(.press, key.soundKind)
    }

    @objc private func globeUp(_ key: KeyButton) {
        guard cursorTouch == nil else { return }
        player.play(.release, key.soundKind)
    }

    private func handle(_ action: KeyAction) {
        switch action {
        case .character(let c):
            let key = displayed(c)
            if currentLayer == .english {
                commitComposition()
                textDocumentProxy.insertText(String(key))
                lastEditTime = CACurrentMediaTime()
            } else {
                apply(automaton.input(key))
            }
            if shift.mode == .once {
                shift.didInputCharacter()
                refreshLabels()
            }
        case .shift:
            shift.tap(at: CACurrentMediaTime(), allowsCaps: currentLayer == .english)
            refreshLabels()
        case .space:
            commitComposition()
            textDocumentProxy.insertText(" ")
            lastEditTime = CACurrentMediaTime()
        case .enter:
            commitComposition()
            textDocumentProxy.insertText("\n")
            lastEditTime = CACurrentMediaTime()
        case .layer(let layer):
            // 한/영 전환 때 조합 중인 글자는 확정한다
            commitComposition()
            currentLayer = layer
            if layer.isLetters {
                lettersLayer = layer
                UserDefaults.standard.set(layer.rawValue, forKey: Self.lastLayerKey)
            }
            shift.reset()
            rebuildKeys()
        case .backspace, .nextKeyboard, .spacer:
            // 백스페이스는 keyDown 에서 따로 처리하고, 🌐 는 시스템 핸들러가 처리한다
            break
        }
    }

    // MARK: - Editing

    /// 현재 레이어와 Shift 상태가 반영된 글자.
    private func displayed(_ c: Character) -> Character {
        guard shift.isActive else { return c }
        if currentLayer == .english {
            return Character(String(c).uppercased())
        }
        return KeyboardLayout.shifted[c] ?? c
    }

    private func apply(_ edit: TextEdit) {
        isApplyingEdit = true
        defer {
            isApplyingEdit = false
            lastEditTime = CACurrentMediaTime()
            noteComposingState()
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
                guard let self else { return }
                self.player.play(.press, .backspace)
                if self.compositionIsStale() { self.commitComposition() }
                self.deleteBackward()
            }
        }
    }

    private func stopDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
}
