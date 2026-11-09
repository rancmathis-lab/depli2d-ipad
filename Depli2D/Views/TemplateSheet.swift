import SwiftUI

struct TemplateSheet: View {
    @ObservedObject var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var params = PackagingTemplates.Carton0201()

    var body: some View {
        NavigationStack {
            Form {
                Section("Dimensions du carton (mm)") {
                    sliderRow("Longueur L", $params.longueur, 20...600)
                    sliderRow("Largeur W", $params.largeur, 20...600)
                    sliderRow("Hauteur H", $params.hauteur, 10...400)
                    sliderRow("Onglet de collage", $params.onglet, 10...60)
                    sliderRow("Jeu des rabats", $params.jeu, 0...10)
                }
                Section("Aperçu") {
                    preview
                        .frame(height: 170)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Section {
                    Button("Insérer le gabarit") {
                        vm.insertElements(PackagingTemplates.cartonFendu0201(params))
                        vm.tool = .select
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Carton ECMA 0201")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func sliderRow(_ title: String, _ value: Binding<CGFloat>, _ range: ClosedRange<CGFloat>) -> some View {
        HStack {
            Text(title).frame(width: 150, alignment: .leading)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue))")
                .frame(width: 36, alignment: .trailing)
                .monospacedDigit()
        }
    }

    private var preview: some View {
        let elements = PackagingTemplates.cartonFendu0201(params)
        let bounds = polylineBounds(elements)
        let w = Swift.max(bounds.width, 1)
        let h = Swift.max(bounds.height, 1)
        return GeometryReader { geo in
            let s = Swift.min(geo.size.width / w, geo.size.height / h) * 0.96
            let origin = CGPoint(
                x: (geo.size.width - w * s) / 2 - bounds.minX * s,
                y: (geo.size.height - h * s) / 2 - bounds.minY * s
            )
            ForEach(elements) { el in
                DielineShape(points: el.points, closed: el.closed, scale: s, origin: origin)
                    .stroke(el.kind.color,
                            style: StrokeStyle(lineWidth: Swift.max(el.kind.lineWidth / s, 0.4),
                                               dash: el.kind.dash))
            }
        }
    }
}
