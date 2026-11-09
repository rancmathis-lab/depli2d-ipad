import CoreGraphics

func clamp<T: Comparable>(_ value: T, _ min: T, _ max: T) -> T {
    Swift.min(Swift.max(value, min), max)
}

func snap(_ point: CGPoint, step: CGFloat) -> CGPoint {
    guard step > 0 else { return point }
    return CGPoint(x: (point.x / step).rounded() * step,
                   y: (point.y / step).rounded() * step)
}

func distanceToSegment(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let vx = b.x - a.x
    let vy = b.y - a.y
    let wx = p.x - a.x
    let wy = p.y - a.y
    let c1 = vx * wx + vy * wy
    if c1 <= 0 { return hypot(p.x - a.x, p.y - a.y) }
    let c2 = vx * vx + vy * vy
    if c2 <= c1 { return hypot(p.x - b.x, p.y - b.y) }
    let t = c1 / c2
    return hypot(p.x - (a.x + t * vx), p.y - (a.y + t * vy))
}

func distanceToPolyline(_ p: CGPoint, _ points: [CGPoint], closed: Bool) -> CGFloat {
    guard let first = points.first else { return .infinity }
    if points.count == 1 { return hypot(p.x - first.x, p.y - first.y) }
    var best = CGFloat.infinity
    for i in 0..<points.count - 1 {
        best = Swift.min(best, distanceToSegment(p, points[i], points[i + 1]))
    }
    if closed {
        best = Swift.min(best, distanceToSegment(p, points[points.count - 1], first))
    }
    return best
}

func polylineBounds(_ elements: [DelineElement]) -> CGRect {
    var minX = CGFloat.infinity
    var minY = CGFloat.infinity
    var maxX = -CGFloat.infinity
    var maxY = -CGFloat.infinity
    for element in elements where !element.points.isEmpty {
        for p in element.points {
            minX = Swift.min(minX, p.x)
            minY = Swift.min(minY, p.y)
            maxX = Swift.max(maxX, p.x)
            maxY = Swift.max(maxY, p.y)
        }
    }
    if minX == .infinity { return .zero }
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}
