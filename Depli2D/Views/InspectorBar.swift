import SwiftUI

struct InspectorBar: View {
    @ObservedObject var vm: EditorViewModel
    @State private var xText = ""
    @State private var yText = ""

    private var selected: DelineElement? {
        guard let id = vm.selectedID else { return nil }
        return vm.document.elements.first { $0.id == id }
    }

    var body: some View {
        Group {
            if let el = selected {
                HStack(spacing: 14) {
                    Image(systemName: "selection.pin.in.out")
                        .foregroundStyle(el.kind.color)

                    Picker("Type", selection: Binding<ElementKind>(
                        get: { el.kind },
                        set: { vm.setKindOfSelected($0) }
                    )) {
                        ForEach(ElementKind.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.menu)

                    Text("\(el.points.count) pt")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text("X").foregroundStyle(.secondary)
                        TextField("mm", text: $xText)
                            .frame(width: 56)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit { applyPosition() }
                        Text("Y").foregroundStyle(.secondary)
                        TextField("mm", text: $yText)
                            .frame(width: 56)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onSubmit { applyPosition() }
                    }

                    Button { vm.duplicateSelected() } label: { Image(systemName: "plus.square.on.square") }
                    Button(role: .destructive) { vm.deleteSelected() } label: { Image(systemName: "trash") }
                }
                .font(.subheadline)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onAppear { fill(el) }
                .onChange(of: vm.selectedID) { _, _ in if let el = selected { fill(el) } }
            }
        }
    }

    private func fill(_ el: DelineElement) {
        xText = String(format: "%.1f", el.centroid.x)
        yText = String(format: "%.1f", el.centroid.y)
    }

    private func applyPosition() {
        guard let dx = Double(xText), let dy = Double(yText) else { return }
        vm.moveSelectedTo(x: CGFloat(dx), y: CGFloat(dy))
    }
}
