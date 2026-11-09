import SwiftUI

struct DocumentPreview: View {
    let document: DielineDocument
    let size: CGSize

    var body: some View {
        let bounds = polylineBounds(document.elements)
        let w = Swift.max(bounds.width, 1)
        let h = Swift.max(bounds.height, 1)
        let s = Swift.min(size.width / w, size.height / h) * 0.98
        let origin = CGPoint(
            x: (size.width - w * s) / 2 - bounds.minX * s,
            y: (size.height - h * s) / 2 - bounds.minY * s
        )
        ZStack {
            Color.white
            ForEach(document.elements) { element in
                DielineShape(points: element.points, closed: element.closed, scale: s, origin: origin)
                    .stroke(element.kind.color,
                            style: StrokeStyle(lineWidth: Swift.max(element.kind.lineWidth / s, 0.5),
                                               dash: element.kind.dash))
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
