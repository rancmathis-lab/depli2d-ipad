import SwiftUI

struct DielineShape: Shape {
    var points: [CGPoint]
    var closed: Bool
    var scale: CGFloat = 1
    var origin: CGPoint = .zero

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: origin.x + first.x * scale, y: origin.y + first.y * scale))
        for p in points.dropFirst() {
            path.addLine(to: CGPoint(x: origin.x + p.x * scale, y: origin.y + p.y * scale))
        }
        if closed { path.closeSubpath() }
        return path
    }
}
