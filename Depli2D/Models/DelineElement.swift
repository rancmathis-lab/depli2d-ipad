import CoreGraphics
import Foundation

struct DelineElement: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: ElementKind
    var points: [CGPoint]
    var closed: Bool
    var label: String?

    init(id: UUID = UUID(), kind: ElementKind, points: [CGPoint], closed: Bool = false, label: String? = nil) {
        self.id = id
        self.kind = kind
        self.points = points
        self.closed = closed
        self.label = label
    }

    var centroid: CGPoint {
        guard !points.isEmpty else { return .zero }
        var sx: CGFloat = 0
        var sy: CGFloat = 0
        for p in points {
            sx += p.x
            sy += p.y
        }
        return CGPoint(x: sx / CGFloat(points.count), y: sy / CGFloat(points.count))
    }
}
