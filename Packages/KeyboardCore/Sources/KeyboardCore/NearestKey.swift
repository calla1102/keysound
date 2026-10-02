import CoreGraphics

/// 터치 지점에 가장 알맞은 키를 고른다.
/// 키 안이면 그 키, 키 사이 간격·가장자리면 키 사각형까지 거리가 가장 가까운 키.
/// 거리가 같으면 앞 인덱스(왼쪽·위쪽 줄)를 고른다.
public enum NearestKey {
    public static func index(at point: CGPoint, in frames: [CGRect]) -> Int? {
        var best: (index: Int, distance: CGFloat)?
        for (index, frame) in frames.enumerated() where !frame.isEmpty {
            let d = squaredDistance(from: point, to: frame)
            if d == 0 { return index }
            if best == nil || d < best!.distance {
                best = (index, d)
            }
        }
        return best?.index
    }

    static func squaredDistance(from p: CGPoint, to r: CGRect) -> CGFloat {
        let dx = max(r.minX - p.x, 0, p.x - r.maxX)
        let dy = max(r.minY - p.y, 0, p.y - r.maxY)
        return dx * dx + dy * dy
    }
}
