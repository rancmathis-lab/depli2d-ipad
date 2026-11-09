import CoreGraphics
import Foundation

struct DielineDocument: Codable, Equatable {
    var name: String
    var pageWidth: CGFloat
    var pageHeight: CGFloat
    var elements: [DelineElement]

    static let `default` = DielineDocument(
        name: "Déplié sans titre",
        pageWidth: 420,
        pageHeight: 594,
        elements: []
    )
}
