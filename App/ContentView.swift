import SwiftUI

struct ContentView: View {
    /// 키보드 익스텐션이 App Group 에서 읽는 값. 키보드를 다시 열 때 반영된다.
    @AppStorage(AppGroup.Key.selectedSound, store: AppGroup.defaults)
    private var selectedSound: SwitchSound = .default

    @State private var testText = ""
    @FocusState private var isTestFieldFocused: Bool
    @State private var previewer = SoundPreviewer()

    /// 소리가 하나도 없는 묶음은 헤더만 남지 않게 뺀다
    private var groups: [SwitchSound.Group] {
        SwitchSound.Group.allCases.filter { !$0.sounds.isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.sounds) { sound in
                            Button {
                                // 키보드는 다시 열릴 때 선택을 읽으므로 내려 둔다
                                isTestFieldFocused = false
                                selectedSound = sound
                                previewer.preview(sound)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(sound.displayName)
                                            .foregroundStyle(.primary)
                                        Text(sound.summary)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if sound == selectedSound {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            .accessibilityAddTraits(sound == selectedSound ? .isSelected : [])
                        }
                    } header: {
                        Text(group.displayName)
                    } footer: {
                        // 안내문은 마지막 묶음 아래에만 둔다
                        if group == groups.last {
                            Text("탭하면 소리를 미리 들을 수 있습니다. 고르면 키보드가 내려가고, 다시 열면 바뀐 소리가 적용됩니다. 무음 모드에서는 소리가 나지 않습니다.")
                        }
                    }
                }

                Section("써 보기") {
                    TextField("여기를 눌러 Keysound 키보드로 입력해 보세요", text: $testText, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isTestFieldFocused)
                }

                Section("시작하기") {
                    Label("설정 > 일반 > 키보드 > 키보드 > 새로운 키보드 추가에서 Keysound를 추가하세요.", systemImage: "keyboard")
                    Label("「전체 접근 허용」은 필요 없습니다. 입력한 내용은 어디로도 전송되지 않습니다.", systemImage: "lock")
                }

                Section {
                    // 파일별 출처는 ThirdParty/CREDITS.md, 화면 데이터는 SoundCredits.swift
                    NavigationLink("출처 및 라이선스") { CreditsView() }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .background(KeyboardDismissTap())
            .navigationTitle("Keysound")
        }
    }
}

#Preview {
    ContentView()
}
