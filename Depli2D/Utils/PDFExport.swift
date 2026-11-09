import SwiftUI
import UIKit

enum PDFExport {
    static let mmToPoints = 72.0 / 25.4

    static func makePDF(_ document: DielineDocument) -> Data {
        let pageRect = CGRect(
            x: 0,
            y: 0,
            width: document.pageWidth * mmToPoints,
            height: document.pageHeight * mmToPoints
        )
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            context.beginPage()
            guard let cg = UIGraphicsGetCurrentContext() else { return }
            cg.setFillColor(UIColor.white.cgColor)
            cg.fill(pageRect)
            cg.saveGState()
            cg.translateBy(x: 0, y: pageRect.height)
            cg.scaleBy(x: mmToPoints, y: -mmToPoints)
            for element in document.elements {
                guard let first = element.points.first else { continue }
                let path = CGMutablePath()
                path.move(to: first)
                for p in element.points.dropFirst() {
                    path.addLine(to: p)
                }
                if element.closed { path.closeSubpath() }
                cg.addPath(path)
                cg.setStrokeColor(element.kind.uiColor.cgColor)
                cg.setLineWidth(element.kind.lineWidth / mmToPoints)
                cg.setLineDash(phase: 0, lengths: element.kind.dash.map { $0 / mmToPoints })
                cg.strokePath()
            }
            cg.restoreGState()
        }
    }

    static func makePNG(_ document: DielineDocument, scale: CGFloat = 3) -> Data? {
        let size = CGSize(width: document.pageWidth * mmToPoints, height: document.pageHeight * mmToPoints)
        let renderer = ImageRenderer(content: DocumentPreview(document: document, size: size))
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        renderer.scale = scale
        return renderer.uiImage?.pngData()
    }
}
