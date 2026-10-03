import SwiftUI

/// 「출처 및 라이선스」 화면. 데이터는 `SwitchSound.credit`(SoundCredits.swift) 한 곳에서 온다.
/// 고정 높이·lineLimit 없이 Dynamic Type 에서 줄이 늘어나도록 둔다.
struct CreditsView: View {
    private var sounds: [SwitchSound] {
        // 메인 화면과 같은 묶음 순서
        SwitchSound.Group.allCases.flatMap(\.sounds).filter { $0.credit != nil }
    }

    var body: some View {
        List {
            Section {
                Text("「기본 클릭」을 뺀 Keysound의 타건음은 아래 녹음을 가공해 만들었습니다. 원본 녹음은 각각 표시된 라이선스를 그대로 따르며, 저작자가 이 앱을 후원하거나 보증한다는 뜻은 아닙니다. 원본은 각 라이선스의 보증 부인 조항에 따라 어떠한 보증 없이 있는 그대로 제공됩니다.")
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
