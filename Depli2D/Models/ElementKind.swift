import SwiftUI

enum ElementKind: String, Codable, CaseIterable, Identifiable {
    case cut
    case crease
    case bleed
    case annotation

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cut: return "Coupe"
        case .crease: return "Pli"
        case .bleed: return "Fond perdu"
        case .annotation: return "Annotation"
        }
    }

    var color: Color {
        switch self {
        case .cut: return .red
        case .crease: return .blue
        case .bleed: return .gray
        case .annotation: return .orange
        }
    }

    var uiColor: UIColor {
        switch self {
        case .cut: return .systemRed
        case .crease: return .systemBlue
        case .bleed: return .systemGray
        case .annotation: return .systemOrange
        }
    }

    var lineWidth: CGFloat {
        self == .annotation ? 1 : 2
    }

    var dash: [CGFloat] {
        self == .crease ? [7, 5] : []
    }
}
