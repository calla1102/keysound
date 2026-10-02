import UIKit

/// 입력란이 요구하는 키보드 종류(keyboardType)와 리턴 키(returnKeyType)를 키보드 쪽 결정으로 옮긴 값.
/// 입력란이 바뀌면 컨트롤러가 새로 만들어 비교한다. 레이어를 다시 고를지는 `keyboardType` 이 바뀔 때만 정한다.
struct InputProfile: Equatable {
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType
    /// 문서가 비어 있으면 리턴 키를 비활성으로 보이는 입력란인가
    let enablesReturnKeyAutomatically: Bool

    init(keyboardType: UIKeyboardType = .default,
         returnKeyType: UIReturnKeyType = .default,
         enablesReturnKeyAutomatically: Bool = false) {
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
    }

    init(proxy: UITextDocumentProxy) {
        self.init(keyboardType: proxy.keyboardType ?? .default,
                  returnKeyType: proxy.returnKeyType ?? .default,
                  enablesReturnKeyAutomatically: proxy.enablesReturnKeyAutomatically ?? false)
    }

    /// 입력란이 바뀔 때 먼저 보여 줄 레이어. nil 이면 사용자가 마지막으로 쓴 글자 레이어를 따른다.
    var startLayer: KeyboardLayer? {
        switch keyboardType {
        case .emailAddress, .URL, .webSearch, .twitter, .asciiCapable: .english
        case .numbersAndPunctuation: .symbols
        case .numberPad: .numberPad
        case .asciiCapableNumberPad: .asciiNumberPad
        case .decimalPad: .decimalPad
        case .phonePad: .phonePad
        default: nil
        }
    }

    /// 글자 레이어 맨 아랫줄(스페이스 옆)에 더할 보조 키.
    var accessoryKeys: [Character] {
        switch keyboardType {
        case .emailAddress: ["@", "."]
        case .URL, .webSearch: [".", "/"]
        case .twitter: ["@", "#"]
        default: []
        }
    }

    /// 리턴 키 한국어 라벨. nil 이면 기본 아이콘(return 화살표)을 쓴다.
    var returnTitle: String? {
        switch returnKeyType {
        case .default: nil
        case .go: "이동"
        case .google, .yahoo, .search: "검색"
        case .send: "보내기"
        case .next: "다음"
        case .done: "완료"
        case .join: "가입"
        case .route: "경로"
        case .continue: "계속"
        case .emergencyCall: "긴급 통화"
        @unknown default: nil
        }
    }
}
