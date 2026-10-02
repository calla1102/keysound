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

    // MARK: 백스페이스 길게 누르기 가속
    //
    // 누르는 즉시 1회 삭제 → initialDelay 뒤 문자 단위 반복(charInterval) → 누른 지 wordPhaseAfter 가 지나면 단어 단위 삭제(wordInterval).
    // 한글 조합 중 문자 단계: 처음 jamoTicksBeforeSyllable 번은 엔진의 자모 단위 백스페이스를 따르고,
    // 그래도 같은 음절 조합이 남아 있으면 조합을 확정하고 음절 단위로 지운다. 단어 단계는 먼저 조합을 확정한다.
    // 단어 단계 문맥은 시작 시 한 번 읽어 우리가 지운 만큼 직접 줄여 쓴다(호스트 문맥은 한발 늦게 갱신돼 매 틱 읽으면 과삭제한다).
    private enum DeleteRepeat {
        static let initialDelay: TimeInterval = 0.45
        static let charInterval: TimeInterval = 0.1
        static let wordPhaseAfter: TimeInterval = 1.8
        static let wordInterval: TimeInterval = 0.15
        static let jamoTicksBeforeSyllable = 1
    }
    private var deleteTimer: Timer?
    private var deletePressTime: CFTimeInterval = 0
    /// 이번 누름에서 조합 중 자모 단위로 지운 틱 수. 누름이 끝나면(stopDeleteRepeat) 0 으로 돌아간다.
    private var jamoTicksThisPress = 0
    /// 단어 단계에서 우리가 지운 만큼 줄여 가는 커서 앞 문맥. nil 이면 다시 읽어야 한다.
    private var wordContext: String?
    /// 우리 편집 도중 textDidChange 가 불려도 조합을 끊지 않기 위한 표시
    private var isApplyingEdit = false
    /// 우리 마지막 편집 시각. 호스트 앱은 문맥(documentContext)을 한발 늦게 갱신하므로 이 직후의 불일치는 믿지 않는다.
    private var lastEditTime: CFTimeInterval = 0
    private var contextRecheck: DispatchWorkItem?
    private static let contextGrace: CFTimeInterval = CompositionGuard.grace
    /// 한글 조합 확정 판정(최근 조합 기록 보유). 판정 규칙·경계는 KeyboardCore 의 CompositionGuard 참고.
    private var compositionGuard = CompositionGuard()

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
    private var cursorTracker = CursorPanTracker()
    private var lastSpacePoint: CGPoint = .zero
    /// 마지막 커서 이동 시각과, 반영이 확인되지 않은 첫 이동 직전의 호스트 문맥.
    /// adjustTextPosition 직후 문맥은 한발 늦게 갱신되므로, 줄 이동은 문맥이 이 스냅샷과 달라진 뒤 한 번 더 같은 값으로
    /// 읽힐 때까지(최대 `contextSettleTimeout`) 기다린다. 연달아 옮긴 경우 중간 이동만 반영된 문맥을 믿지 않기 위해서다.
    private var lastCursorMoveTime: CFTimeInterval = 0
    private var unsettledBaseline: CursorSnapshot?
    /// 아직 처리하지 않은 줄 이동(아래 +). 한 줄은 「경계 넘기 → 문맥 갱신 대기 → 목표 열」 두 단계라 한 번에 하나씩 처리한다.
    private var pendingLines = 0
    /// 줄 이동 처리 중에 들어온 가로 칸 수. 줄 이동이 끝나면 적용한다.
    private var pendingColumns = 0
    private var lineMoveRunning = false
    /// 키보드가 사라지면 올려 둔 줄 이동 작업을 버린다.
    private var lineMoveGeneration = 0
    /// 위아래 연속 이동 중 유지할 목표 열. 가로 이동이 일어나면 리셋한다.
    private var goalColumn: Int?
    private static let contextSettleTimeout: CFTimeInterval = 0.3
    private static let contextPollInterval: TimeInterval = 0.016

    private struct CursorSnapshot: Equatable {
        let before: String?
        let after: String?
    }
    private var ignoredTouches: Set<ObjectIdentifier> = []

    private enum Metric {
        static let rowHeight: CGFloat = 42
        static let rowSpacing: CGFloat = 10
        static let keySpacing: CGFloat = 6
    }

    // MARK: - Lifecycle

    deinit {
        deleteTimer?.invalidate()
        longPressTimer?.invalidate()
        contextRecheck?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 시스템 키보드 배경이 비쳐 보이도록 거의 투명하게 둔다. 완전 투명(.clear)이면 hit-test 에서
        // 터치가 누락될 수 있어 alpha 0.001 로 터치 영역만 유지한다(육안으로는 투명).
        view.backgroundColor = UIColor(white: 0, alpha: 0.001)
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
        // flush 의 조합 확정이 남긴 기록까지 비운다
        compositionGuard.reset()
        endCursorMode()
        cancelLineMoves()
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
        compositionGuard.note(composing: automaton.composing, at: CACurrentMediaTime())
    }

    /// 조합 중인 글자가 문맥과 어긋났는지. 판정 규칙은 `CompositionGuard.isStale` 참고
    /// (문맥 nil 이면 유지, 마지막 편집 직후 유예 중엔 불일치를 믿지 않아 stale 아님으로 본다).
    private func compositionIsStale() -> Bool {
        guard automaton.isComposing else { return false }
        return compositionGuard.isStale(
            composing: automaton.composing,
            before: textDocumentProxy.documentContextBeforeInput,
            lastEditTime: lastEditTime,
            now: CACurrentMediaTime()
        )
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
        // 손을 뗀 뒤 남은 줄 이동이 이 입력 뒤에 커서를 옮기면 엉뚱한 곳을 지우거나 쓴다. 입력이 우선이다
        cancelLineMoves()
        player.play(.press, key.soundKind)
        // 보류 중인 공백이 있으면 이 키보다 먼저 넣어 입력 순서를 지킨다
        flushPendingSpace()
        if key.spec.action == .space {
            stopDeleteRepeat()
            pendingSpaceTouch = touch.id
            lastSpacePoint = CGPoint(x: touch.x, y: touch.y)
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
        if pendingSpaceTouch == touch.id { lastSpacePoint = CGPoint(x: touch.x, y: touch.y) }
        guard cursorTouch == touch.id else { return }
        let delta = cursorTracker.move(to: CGPoint(x: touch.x, y: touch.y))
        if delta.columns != 0 {
            // 줄 이동이 진행 중이면 그 계산이 끝날 때까지 가로 이동을 미룬다(2단계가 읽을 문맥이 틀어진다)
            guard !lineMoveRunning && pendingLines == 0 else {
                pendingColumns += delta.columns
                return
            }
            goalColumn = nil
            moveCursor(by: delta.columns)
        } else if delta.lines != 0 {
            pendingLines += delta.lines
            runPendingLineMove()
        }
    }

    private var cursorSnapshot: CursorSnapshot {
        CursorSnapshot(before: textDocumentProxy.documentContextBeforeInput, after: textDocumentProxy.documentContextAfterInput)
    }

    private func moveCursor(by offset: Int) {
        guard offset != 0 else { return }
        if unsettledBaseline == nil { unsettledBaseline = cursorSnapshot }
        textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
        lastCursorMoveTime = CACurrentMediaTime()
    }

    /// 마지막 이동이 호스트 문맥에 반영됐다고 볼 수 있을 때 `then` 을 부른다.
    /// 문맥이 이동 직전과 달라지면 반영된 것으로 보고, 같은 내용의 줄 사이처럼 달라지지 않으면 시간 제한 뒤 진행한다.
    /// 즉시 반영되는 호스트에서는 then → finishLineMove → runPendingLineMove 가 동기로 이어진다(깊이는 남은 줄 수만큼).
    private func whenContextSettled(_ generation: Int, previous: CursorSnapshot? = nil, then: @escaping () -> Void) {
        guard generation == lineMoveGeneration else { return }
        let now = cursorSnapshot
        let waited = CACurrentMediaTime() - lastCursorMoveTime
        let changedAndStable = now != unsettledBaseline && now == previous
        if unsettledBaseline == nil || waited >= Self.contextSettleTimeout || changedAndStable {
            unsettledBaseline = nil
            then()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.contextPollInterval) { [weak self] in
            self?.whenContextSettled(generation, previous: now, then: then)
        }
    }

    /// 남은 줄 이동과 미룬 가로 이동을 버린다. 예약된 대기는 generation 이 바뀌어 아무것도 하지 않는다.
    private func cancelLineMoves() {
        guard lineMoveRunning || pendingLines != 0 || pendingColumns != 0 else { return }
        lineMoveGeneration += 1
        pendingLines = 0
        pendingColumns = 0
        lineMoveRunning = false
    }

    /// 쌓인 줄 이동을 한 줄씩 처리한다. 손을 뗀 뒤에도 이미 받은 줄 이동은 끝까지 한다(줄 경계에 멈춰 있지 않게).
    private func runPendingLineMove() {
        guard !lineMoveRunning, pendingLines != 0 else { return }
        lineMoveRunning = true
        let direction: LineStep.Direction = pendingLines < 0 ? .up : .down
        pendingLines += direction == .up ? 1 : -1
        let generation = lineMoveGeneration
        whenContextSettled(generation) { [weak self] in
            guard let self else { return }
            let first = self.cursorSnapshot
            guard first.before != nil || first.after != nil else {
                // 문맥을 못 읽는 앱이면 줄 이동을 하지 않는다
                self.finishLineMove()
                return
            }
            let before = first.before ?? "", after = first.after ?? ""
            if direction == .up && before.isEmpty {
                // 문서 처음이다. 더 올라갈 줄이 없으니 남은 위쪽 이동을 버린다
                self.pendingLines = 0
                self.finishLineMove()
                return
            }
            let goal = self.goalColumn ?? LineStep.column(before: before)
            self.goalColumn = goal
            let cross = LineStep.cross(direction, before: before, after: after)
            self.moveCursor(by: cross)
            self.whenContextSettled(generation) { [weak self] in
                guard let self else { return }
                let second = self.cursorSnapshot
                // 경계를 넘었는데 문맥이 그대로면 문서 끝/처음에 막힌 것으로 보고 같은 방향 남은 이동을 버린다
                // (메시지 앱에서 연속 빈 줄 사이도 문맥이 같아 여기서 멈출 수 있다 — 다시 끌면 이어진다)
                if second == first { self.pendingLines = 0 }
                let settle = LineStep.settle(direction, before: second.before ?? "", after: second.after ?? "", goalColumn: goal)
                self.moveCursor(by: settle)
                self.finishLineMove()
            }
        }
    }

    private func finishLineMove() {
        lineMoveRunning = false
        if pendingLines != 0 {
            runPendingLineMove()
        } else if pendingColumns != 0 {
            goalColumn = nil
            moveCursor(by: pendingColumns)
            pendingColumns = 0
        }
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
        cursorTracker.begin(at: lastSpacePoint)
        // 이전 손가락이 남긴 줄 이동은 버린다(새 이동의 목표 열이 섞이지 않게)
        cancelLineMoves()
        goalColumn = nil
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
        deletePressTime = CACurrentMediaTime()
        deleteTimer = Timer.scheduledTimer(withTimeInterval: DeleteRepeat.initialDelay, repeats: false) { [weak self] _ in
            self?.startCharRepeat()
        }
    }

    private func startCharRepeat() {
        deleteTimer = Timer.scheduledTimer(withTimeInterval: DeleteRepeat.charInterval, repeats: true) { [weak self] _ in
            self?.charRepeatTick()
        }
        charRepeatTick()
    }

    private func charRepeatTick() {
        if CACurrentMediaTime() - deletePressTime >= DeleteRepeat.wordPhaseAfter {
            startWordRepeat()
            return
        }
        player.play(.press, .backspace)
        if compositionIsStale() { commitComposition() }
        if automaton.isComposing {
            if jamoTicksThisPress >= DeleteRepeat.jamoTicksBeforeSyllable {
                // 같은 음절이 계속 남아 있다 — 조합을 확정하고 음절째로 지운다
                commitComposition()
                deleteBackward()
                return
            }
            jamoTicksThisPress += 1
        }
        deleteBackward()
    }

    private func startWordRepeat() {
        deleteTimer?.invalidate()
        commitComposition()
        wordContext = nil
        deleteTimer = Timer.scheduledTimer(withTimeInterval: DeleteRepeat.wordInterval, repeats: true) { [weak self] _ in
            self?.wordRepeatTick()
        }
        wordRepeatTick()
    }

    private func wordRepeatTick() {
        let now = CACurrentMediaTime()
        if let cached = wordContext, now - lastEditTime >= Self.contextGrace {
            // 유예가 지났으면 호스트 문맥이 최신이다 — 누르는 도중 외부에서 커서·텍스트가 바뀌어 캐시가 틀어졌는지 대조한다.
            // 한계: 캐시가 있다는 건 직전 틱이 지웠다는 뜻이고 단어 틱 간격(wordInterval)이 유예보다 짧아,
            // 이 분기는 메인 스레드가 유예 이상 멈췄을 때만 도는 방어 코드다. 연속 삭제 중 외부 변경은 잡지 못한다.
            // 유예 안에서 읽으면 호스트가 갱신 전인 옛 문맥이라 과삭제하므로 감수한다.
            guard let actual = textDocumentProxy.documentContextBeforeInput else {
                startPlainRepeat()
                return
            }
            if !actual.hasSuffix(cached) { wordContext = nil }
        }
        if wordContext == nil {
            // 방금 한 편집이 호스트 문맥에 반영되기 전이면 이번 틱은 건너뛴다(옛 문맥으로 과삭제 방지).
            // 단계 전환 직후나 문맥을 다 지운 직후에 약 0.3초 비는 것은 이 유예 때문에 의도된 동작이다(호스트 갱신 지연이 있는 한 못 줄인다).
            if now - lastEditTime < Self.contextGrace { return }
            guard let read = textDocumentProxy.documentContextBeforeInput else {
                // nil 은 문맥을 못 읽는 앱(빈 문맥 "" 과 다르다) — 단어 단위를 포기하고 문자 반복 속도로 지운다
                startPlainRepeat()
                return
            }
            wordContext = read
        }
        player.play(.press, .backspace)
        var context = wordContext ?? ""
        let count = WordDeletion.count(before: context)
        if count == 0 {
            // WordDeletion.count 가 0 인 건 빈 문자열뿐이므로 문맥이 "" 다 — 줄 맨 앞 등이라 한 글자(줄바꿈일 수 있다)만 지우고 다음 틱에 다시 읽는다
            textDocumentProxy.deleteBackward()
            lastEditTime = CACurrentMediaTime()
            wordContext = nil
            return
        }
        for _ in 0..<count { textDocumentProxy.deleteBackward() }
        context.removeLast(count)
        wordContext = context.isEmpty ? nil : context
        lastEditTime = CACurrentMediaTime()
    }

    /// 문맥을 읽을 수 없는 앱용 — 조합은 이미 확정했으므로 문자 간격으로 한 글자씩 지운다.
    private func startPlainRepeat() {
        deleteTimer?.invalidate()
        wordContext = nil
        deleteTimer = Timer.scheduledTimer(withTimeInterval: DeleteRepeat.charInterval, repeats: true) { [weak self] _ in
            self?.plainRepeatTick()
        }
        plainRepeatTick()
    }

    private func plainRepeatTick() {
        player.play(.press, .backspace)
        textDocumentProxy.deleteBackward()
        lastEditTime = CACurrentMediaTime()
    }

    private func stopDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = nil
        jamoTicksThisPress = 0
        wordContext = nil
    }
}
