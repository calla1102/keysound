import CoreText
import UIKit

extension ThemeColor {
    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension KeyboardTheme {
    /// 라이트·다크에 따라 바뀌는 UIColor. 뷰의 backgroundColor 에 넣으면 trait 변화 때 자동으로 다시 해석된다.
    func dynamicColor(_ pick: @escaping (ThemeAppearance) -> ThemeColor) -> UIColor {
        UIColor { trait in
            pick(self.appearance(dark: trait.userInterfaceStyle == .dark)).uiColor
        }
    }

    /// 키 면 색. `tile` 이 있으면 키 색 위에 옅은 무늬를 얹은 작은 타일 이미지로 칠한다.
    func surfaceColor(_ color: ThemeColor, look: ThemeAppearance, tile: KeyPattern.Tile?, scale: CGFloat) -> UIColor {
        guard let tile else { return color.uiColor }
        let image = KeyPatternTiles.image(tile, base: color, ink: look.text, inkAlpha: patternInkAlpha, scale: scale)
        return UIColor(patternImage: image)
    }

    /// 키보드 뷰 배경. 테마와 상관없이 시스템 키보드 배경이 비치게 둔다 — 익스텐션 뷰 밖(위 둥근 모서리·🌐 줄)은
    /// 시스템이 그려 칠할 수 없으므로, 불투명 배경을 깔면 그 경계가 상자처럼 드러난다(2026-10-04 실기기 확인).
    /// 완전 투명 영역의 터치가 호스팅 쪽에서 빠진다는 경험칙(미검증)에 대비해 alpha 를 0.001 로 올린다.
    static let backgroundUIColor = UIColor(white: 0, alpha: 0.001)

    /// 글자 키 22pt·특수 키 16pt 체계의 글꼴. 픽셀은 12pt 격자의 정수 배(24·12pt)로 맞춘다. 로드 실패 시 시스템 글꼴.
    func keyFont(characterKey: Bool) -> UIFont {
        uiFont(systemSize: characterKey ? 22 : 16)
    }

    func uiFont(systemSize: Double) -> UIFont {
        let size = CGFloat(font.size(forSystemSize: systemSize))
        if font == .pixel, let pixel = ThemeFontLoader.pixelFont(size: size) { return pixel }
        return .systemFont(ofSize: size)
    }
}

/// 번들 글꼴 로더. Info.plist `UIAppFonts` 로 등록돼 있으면 바로 찾고, 아니면 번들 파일을 직접 등록해 본다. 둘 다 안 되면 nil.
enum ThemeFontLoader {
    private static var triedRegister = false
    /// 크기별 캐시 — 키마다 UIFont 를 다시 만들지 않는다(5.4MB 글꼴이라 첫 로드가 무겁다). 시스템 글꼴 프리셋은 여기를 아예 부르지 않는다.
    private static var cache: [CGFloat: UIFont] = [:]
    private static var failed = false

    static func pixelFont(size: CGFloat) -> UIFont? {
        if let cached = cache[size] { return cached }
        if failed { return nil }
        if let font = loadPixelFont(size: size) {
            cache[size] = font
            return font
        }
        failed = true
        return nil
    }

    private static func loadPixelFont(size: CGFloat) -> UIFont? {
        if let font = UIFont(name: ThemeFont.pixelFontName, size: size) { return font }
        guard !triedRegister else { return nil }
        triedRegister = true
        let bundles = [Bundle(for: KeyPatternTiles.self), Bundle.main]
        for bundle in bundles {
            if let url = bundle.url(forResource: "Galmuri11", withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                break
            }
        }
        return UIFont(name: ThemeFont.pixelFontName, size: size)
    }
}

/// 무늬 타일. 8pt 한 장만 만들어 `UIColor(patternImage:)` 로 쓰고, (무늬·색·배율) 조합마다 한 번만 만들어 캐시한다. 메인 스레드 전용.
final class KeyPatternTiles {
    private static var cache: [String: UIImage] = [:]
    private static let side: CGFloat = 8

    static func image(_ tile: KeyPattern.Tile, base: ThemeColor, ink: ThemeColor, inkAlpha: Double?, scale: CGFloat) -> UIImage {
        let scale = scale > 0 ? scale : 3
        let key = "\(tile)-\(base.red),\(base.green),\(base.blue),\(base.alpha)-\(ink.red),\(ink.green),\(ink.blue)-\(inkAlpha ?? -1)-\(scale)"
        if let cached = cache[key] { return cached }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let size = CGSize(width: side, height: side)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            base.uiColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            switch tile {
            case .gingham:
                // 가로·세로 띠가 겹친 칸이 가장 진하다(옅은 농담 0.08)
                ink.withAlpha(inkAlpha ?? 0.08).uiColor.setFill()
                context.fill(CGRect(x: 0, y: 0, width: side, height: side / 2))
                context.fill(CGRect(x: 0, y: 0, width: side / 2, height: side))
            case .dots:
                ink.withAlpha(inkAlpha ?? 0.10).uiColor.setFill()
                context.cgContext.fillEllipse(in: CGRect(x: 3, y: 3, width: 2, height: 2))
            }
        }
        cache[key] = image
        return image
    }
}
