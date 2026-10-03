import SwiftUI

struct ContentView: View {
    /// 키보드 익스텐션이 App Group 에서 읽는 값. 키보드를 다시 열 때 반영된다.
    @AppStorage(AppGroup.Key.selectedSound, store: AppGroup.defaults)
    private var selectedSound: SwitchSound = .default

    @State private var testText = ""
    @FocusState private var isTestFieldFocused: Bool
    @State private var previewer = SoundPreviewer()

    var body: some View {
        NavigationStack {
            List {
                ForEach(SwitchSound.Group.allCases) { group in
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
                        if group == SwitchSound.Group.allCases.last {
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

                Section("출처") {
                    // 자세한 파일별 출처는 ThirdParty/CREDITS.md. CC BY 는 표기가 의무라 무접점·멤브레인은 반드시 남긴다.
                    Text("무접점 소리: MakotoHiramatsu 「Press and Click FREE」(makotohiramatsu.itch.io), CC BY 4.0 (creativecommons.org/licenses/by/4.0). 원본을 키 단위로 잘라 음량을 조정함")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("멤브레인 소리: Geoff-Bremner-Audio 「HP Office Keyboard」(freesound.org/s/705787), CC BY 4.0 (creativecommons.org/licenses/by/4.0). 원본을 키 단위로 잘라 음량을 조정함")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("적축·갈축·청축·흑축·버클링 스프링·노트북·윤활 리니어 소리: Freesound 의 Sadiquecat · Foxfire- · UberBosser · el_boss · SamsterBirdies · justamudkip · Techrul 녹음, CC0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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
