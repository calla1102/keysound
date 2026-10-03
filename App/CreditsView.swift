import SwiftUI

/// 「출처 및 라이선스」 화면. 데이터는 `SwitchSound.credit`(SoundCredits.swift) 한 곳에서 온다.
/// 고정 높이·lineLimit 없이 Dynamic Type 에서 줄이 늘어나도록 둔다.
struct CreditsView: View {
    private var sounds: [SwitchSound] {
        SwitchSound.allCases.filter { $0.credit != nil }
    }

    var body: some View {
        List {
            Section {
                Text("Keysound 의 타건음은 아래 녹음을 바탕으로 만들었습니다. 각 녹음은 저작자가 밝힌 라이선스에 따라 사용했으며, 라이선스를 바꾸거나 저작자가 이 앱을 보증한다는 뜻이 아닙니다. 원본은 저작자가 어떠한 보증 없이 있는 그대로 제공합니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(sounds) { sound in
                if let credit = sound.credit {
                    Section(sound.displayName) {
                        CreditRow(credit: credit)
                    }
                }
            }
        }
        .navigationTitle("출처 및 라이선스")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CreditRow: View {
    let credit: SoundCredit

    var body: some View {
        switch credit.origin {
        case .synthesized:
            Text("합성음(외부 녹음 없음)")
        case let .recording(recorder, workTitle, links, license, modification):
            VStack(alignment: .leading, spacing: 4) {
                Text(recorder).font(.headline)
                if let workTitle {
                    Text("「\(workTitle)」")
                }
                Text("라이선스: \(license.name)")
                Link(license.uri.absoluteString, destination: license.uri)
                    .font(.footnote)
                Text("변경: \(modification)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            ForEach(links, id: \.url) { item in
                Link(destination: item.url) {
                    Label(item.title, systemImage: "arrow.up.right.square")
                }
            }
        }
    }
}

#Preview {
    NavigationStack { CreditsView() }
}
