import SwiftUI

struct ContentView: View {
    @State private var sharedValue: String = AppGroup.defaults?.string(forKey: AppGroup.Key.selectedSwitch) ?? "(없음)"

    var body: some View {
        NavigationStack {
            List {
                Section("시작하기") {
                    Label("설정 > 일반 > 키보드 > 키보드에서 Keysound를 추가하세요.", systemImage: "keyboard")
                    Label("「전체 접근 허용」을 켜면 선택한 축 소리가 키보드에서 재생됩니다.", systemImage: "speaker.wave.2")
                }

                Section("App Group 검증") {
                    LabeledContent("저장된 값", value: sharedValue)
                    Button("값 쓰기: blue") { write("blue") }
                    Button("값 쓰기: red") { write("red") }
                    Text("키보드 상단 'AppGroup:' 표시가 이 값과 같아지는지 확인하세요.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Keysound")
        }
    }

    private func write(_ value: String) {
        AppGroup.defaults?.set(value, forKey: AppGroup.Key.selectedSwitch)
        sharedValue = AppGroup.defaults?.string(forKey: AppGroup.Key.selectedSwitch) ?? "(없음)"
    }
}

#Preview {
    ContentView()
}
