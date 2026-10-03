import SwiftUI

/// 자판 디자인 미리보기. 현재 라이트·다크 설정을 반영해 키 몇 줄만 그린다. 이미지 없이 색만 쓴다.
struct KeyboardThemePreview: View {
    let theme: KeyboardTheme
    @Environment(\.colorScheme) private var colorScheme

    private var look: ThemeAppearance { theme.appearance(dark: colorScheme == .dark) }

    private let rows: [[String]] = [
        ["ㅂ", "ㅈ", "ㄷ", "ㄱ", "ㅅ"],
        ["ㅁ", "ㄴ", "ㅇ", "ㄹ", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 5) {
                    ForEach(row, id: \.self) { label in
                        key(label, isFunction: label == "⌫")
                    }
                }
            }
            HStack(spacing: 5) {
                key("⇧", isFunction: true).frame(width: 44)
                key("스페이스", isFunction: false)
                key("⏎", isFunction: true).frame(width: 44)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background {
            // 투명 배경(기본)은 실제 키보드에서 시스템 배경이 비치므로 회색으로 흉내 낸다
            RoundedRectangle(cornerRadius: 10)
                .fill(look.background.alpha == 0 ? Color(.systemGray5) : look.background.color)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(theme.displayName) 자판 미리보기")
    }

    private func key(_ label: String, isFunction: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: theme.cornerRadius * 0.8)
        return Text(label)
            .font(.callout)
            .foregroundStyle(look.text.color)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background {
                shape
                    .fill((isFunction ? look.functionKey : look.characterKey).color)
                    .shadow(color: look.shadow?.color ?? .clear, radius: 0, x: 0, y: 1)
            }
    }
}
