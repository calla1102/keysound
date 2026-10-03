import SwiftUI

struct ContentView: View {
    /// 키보드 익스텐션이 App Group 에서 읽는 값. 키보드를 다시 열 때 반영된다.
    @AppStorage(AppGroup.Key.selectedSound, store: AppGroup.defaults)
    private var selectedSound: SwitchSound = .default

    @AppStorage(KeyboardTheme.storageKey, store: AppGroup.defaults)
    private var selectedThemeID: String = KeyboardTheme.default.rawValue
    private var selectedTheme: KeyboardTheme { KeyboardTheme(storedValue: selectedThemeID) }

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
                themeSection

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
            // 소리·디자인을 고른 뒤 바로 써 볼 수 있게 입력칸을 목록 위에 고정한다
            .safeAreaInset(edge: .top) { testField }
            .navigationTitle("Keysound")
        }
    }
}

extension ContentView {
    var testField: some View {
        TextField("여기를 눌러 Keysound 키보드로 입력해 보세요", text: $testText, axis: .vertical)
            .lineLimit(1...3)
            .focused($isTestFieldFocused)
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)
            .accessibilityLabel("써 보기 입력칸")
    }

    var themeSection: some View {
        Section {
            KeyboardThemePreview(theme: selectedTheme)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            ForEach(KeyboardTheme.allCases) { theme in
                Button {
                    // 키보드는 다시 열릴 때 선택을 읽으므로 내려 둔다
                    isTestFieldFocused = false
                    selectedThemeID = theme.rawValue
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(theme.displayName)
                                .foregroundStyle(.primary)
                            Text(theme.summary)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if theme == selectedTheme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .accessibilityLabel("\(theme.displayName), \(theme.summary)")
                .accessibilityAddTraits(theme == selectedTheme ? .isSelected : [])
            }
        } header: {
            Text("자판 디자인")
        } footer: {
            Text("고르면 키보드가 내려가고, 다시 열면 바뀐 디자인이 적용됩니다.")
        }
    }
}

#Preview {
    ContentView()
}
