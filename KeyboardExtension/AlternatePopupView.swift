import KeyboardCore
import UIKit

/// 길게 누르기 대체 문자 팝업. 칸마다 글자 하나를 그리고 선택 칸만 강조한다. 터치는 받지 않는다(선택은 컨트롤러가 좌표로 계산).
/// 배경·글자색은 선택된 자판 디자인(`KeyboardTheme`)을 따르고, 선택 강조는 시스템 강조색이다.
final class AlternatePopupView: UIView {
    private let labels: [UILabel]
    private let geometry: AlternatePopupGeometry
    private let selectionColor = UIColor.systemBlue
    private let textColor: UIColor

    /// - Parameter candidates: 원래 문자를 앞에 둔 후보 목록(화면 순서는 geometry 가 뒤집을 수 있다)
    init(candidates: [Character], geometry: AlternatePopupGeometry, theme: KeyboardTheme) {
        self.geometry = geometry
        textColor = theme.dynamicColor(\.text)
        labels = candidates.map { c in
            let label = UILabel()
            label.text = String(c)
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 24)
            label.textColor = theme.dynamicColor(\.text)
            label.layer.cornerRadius = 6
            label.layer.masksToBounds = true
            return label
        }
        super.init(frame: geometry.frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        backgroundColor = theme.dynamicColor(\.characterKey)
        layer.cornerRadius = CGFloat(theme.cornerRadius) + 3
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 3
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
        for (index, label) in labels.enumerated() {
            let slot = geometry.slot(forCandidate: index)
            label.frame = CGRect(x: CGFloat(slot) * geometry.cellWidth, y: 0, width: geometry.cellWidth, height: bounds.height)
                .insetBy(dx: 2, dy: 3)
            addSubview(label)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 선택 후보 번호. nil 이면 아무 칸도 강조하지 않는다(취소 영역).
    func select(_ index: Int?) {
        for (i, label) in labels.enumerated() {
            let on = i == index
            label.backgroundColor = on ? selectionColor : .clear
            label.textColor = on ? .white : textColor
        }
    }
}
