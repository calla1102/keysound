import SwiftUI

/// 자판 디자인 미리보기. 현재 라이트·다크 설정을 반영해 키 몇 줄만 그린다. 이미지 에셋 없이 코드로 글꼴·무늬·외곽선·입체감을 흉내 낸다.
struct KeyboardThemePreview: View {
    let theme: KeyboardTheme
    /// 선택 목록용 작은 미리보기 — 키 한 줄만 그린다
    var compact = false
    @Environment(\.colorScheme) private var colorScheme

    private var dark: Bool { colorScheme == .dark }
    private var look: ThemeAppearance { theme.appearance(dark: dark) }

    private enum Role { case character, space, function, enter }

    private struct Key: Identifiable {
        let id: Int
        let label: String
        let role: Role
        /// 글자 키 순서(팔레트·무늬용)
        var characterIndex = 0
        var width: CGFloat?
        /// 키 중심의 가로 위치 비율(0...1) — 가로 그라데이션 팔레트용
        var position = 0.5
        /// 세로 위치 비율(0=맨 위 줄) — 세로 그라데이션 팔레트용
        var verticalPosition = 0.5
    }

    private var rows: [[Key]] {
        var index = 0
        func chars(_ labels: [String]) -> [Key] {
            // 5칸 기준으로 위치를 잡는다(두 번째 줄은 마지막 칸이 ⌫)
            labels.enumerated().map { offset, label in
                defer { index += 1 }
                return Key(id: index, label: label, role: .character, characterIndex: index, position: (Double(offset) + 0.5) / (compact ? 4 : 5))
            }
        }
        let first = chars(compact ? ["ㅂ", "ㅈ", "ㄷ", "ㄱ"] : ["ㅂ", "ㅈ", "ㄷ", "ㄱ", "ㅅ"])
        let second = chars(["ㅁ", "ㄴ", "ㅇ", "ㄹ"]) + [Key(id: 100, label: "⌫", role: .function, position: 0.9)]
        let third = [
            Key(id: 101, label: "⇧", role: .function, width: 44, position: 0.08),
            Key(id: 102, label: "스페이스", role: .space, position: 0.5),
            Key(id: 103, label: "⏎", role: .enter, width: 44, position: 0.92),
        ]
        // 세로 위치는 줄 가운데 기준
        return (compact ? [first] : [first, second, third]).enumerated().map { r, row in
            row.map { key in
                var key = key
                key.verticalPosition = (Double(r) + 0.5) / Double(compact ? 4 : 4)
                return key
            }
        }
    }

    var body: some View {
        VStack(spacing: 9) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 5) {
                    ForEach(row) { key in
                        keyView(key)
                    }
                }
            }
        }
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.top, compact ? 6 : 8)
        .padding(.bottom, compact ? 8 : 10)
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .background {
            // 실제 키보드는 시스템 배경이 비치므로 회색으로 흉내 낸다
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(theme.displayName) 자판 미리보기")
    }

    private func color(for key: Key) -> ThemeColor {
        let role: KeyColorRole
        switch key.role {
        case .character: role = .character(index: key.characterIndex)
        case .space: role = .space
        case .function: role = .function
        case .enter: role = .enter
        }
        return theme.keyColor(role: role, pressed: false, look: look, position: theme.paletteMode.usesVerticalPosition ? key.verticalPosition : key.position)
    }

    private func textColor(for key: Key) -> ThemeColor {
        let role: KeyColorRole
        switch key.role {
        case .character: role = .character(index: key.characterIndex)
        case .space: role = .space
        case .function: role = .function
        case .enter: role = .enter
        }
        return KeyboardTheme.textColor(role: role, in: look, keyColor: color(for: key))
    }

    /// 실제 키보드와 같은 크기 체계(글자 24·특수 12 / 시스템 22·16)
    private func font(for key: Key) -> Font {
        let isCharacter = key.role == .character
        let size = theme.font.size(forSystemSize: isCharacter ? 22 : 16)
        switch theme.font {
        case .system: return .system(size: size * 0.8)
        case .pixel: return .custom(ThemeFont.pixelFontName, fixedSize: size)
        }
    }

    private func keyView(_ key: Key) -> some View {
        let capsule = theme.keyShape == .capsule
        let shape = RoundedRectangle(cornerRadius: capsule ? 17 : theme.cornerRadius * 0.8)
        let minHeight: CGFloat = compact ? 28 : 34
        let base = color(for: key)
        let relief = theme.relief
        let thickness = relief == .raised ? theme.sideThickness * 0.7 : 0
        // 글로우(번짐) 그림자는 blur 로 그린다
        let blur = look.shadowBlur
        let tile = key.role == .character ? theme.keyPattern?.tile(forCharacterIndex: key.characterIndex, scope: theme.patternScope) : nil
        let border = look.border ?? (relief == .dished ? ThemeBorder(color: ThemeColor(white: 1, alpha: dark ? 0.22 : 0.55), width: 1) : nil)

        return Text(key.label)
            .font(font(for: key))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .foregroundStyle(textColor(for: key).color)
            .frame(maxWidth: key.width == nil ? .infinity : nil, minHeight: minHeight)
            .frame(width: key.width)
            .background {
                ZStack {
                    shape.fill(base.color)
                    if let tile { PatternView(tile: tile, ink: look.text.color, alpha: theme.patternInkAlpha).clipShape(shape) }
                    reliefOverlay(relief, base: base, shape: shape, capsule: capsule)
                    if let border {
                        shape.strokeBorder(border.color.color, lineWidth: border.width)
                    }
                }
                .background {
                    // 볼록은 불투명 측면 띠, 그 외에는 얇은 그림자
                    if relief == .raised {
                        shape.fill(base.darkened(by: 0.28).withAlpha(1).color).offset(y: thickness)
                    }
                    if let shadow = look.shadow {
                        shape.fill(shadow.color).blur(radius: blur).offset(y: blur > 0 ? 0 : 1)
                    }
                }
            }
    }

    @ViewBuilder
    private func reliefOverlay(_ relief: KeyRelief, base: ThemeColor, shape: RoundedRectangle, capsule: Bool) -> some View {
        switch relief {
        case .flat:
            EmptyView()
        case .raised:
            LinearGradient(colors: [.white.opacity(0.12), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.25))
                .clipShape(shape)
        case .glass:
            LinearGradient(colors: [.white.opacity(dark ? 0.35 : 0.6), .clear], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.35))
                .clipShape(shape)
        case .dished:
            RadialGradient(
                colors: [base.darkened(by: 0.06).color, base.lightened(by: 0.06).color],
                center: .center, startRadius: 0, endRadius: 34)
                .clipShape(shape)
        }
    }
}

/// 체크·점 무늬를 8pt 타일 간격으로 그린다(키보드의 타일 이미지와 같은 모양, 이미지 없이 Canvas).
private struct PatternView: View {
    let tile: KeyPattern.Tile
    let ink: Color
    let alpha: Double?

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 8
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    switch tile {
                    case .gingham:
                        context.fill(Path(CGRect(x: x, y: y, width: step, height: step / 2)), with: .color(ink.opacity(alpha ?? 0.08)))
                        context.fill(Path(CGRect(x: x, y: y, width: step / 2, height: step)), with: .color(ink.opacity(alpha ?? 0.08)))
                    case .dots:
                        context.fill(Path(ellipseIn: CGRect(x: x + 3, y: y + 3, width: 2, height: 2)), with: .color(ink.opacity(alpha ?? 0.10)))
                    }
                    x += step
                }
                y += step
            }
        }
    }
}
