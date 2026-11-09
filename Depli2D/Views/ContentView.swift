import SwiftUI

struct ContentView: View {
    @StateObject private var vm = EditorViewModel()
    @State private var showTemplateSheet = false
    @State private var shareItems: [Any] = []
    @State private var showShare = false
    @State private var exportError: String?
    @State private var showExportError = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                CanvasView(vm: vm)

                VStack(spacing: 10) {
                    if vm.selectedID != nil {
                        InspectorBar(vm: vm)
                            .padding(.horizontal)
                    }
                    bottomBar
                }
                .padding(.bottom, 10)
            }
            .navigationTitle(vm.document.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Menu {
                        Button("Nouveau déplié", systemImage: "doc.badge.plus") { vm.newDocument() }
                        Button("Gabarit carton ECMA 0201…", systemImage: "square.split.3x3") { showTemplateSheet = true }
                        Divider()
                        Button("Exporter en PDF", systemImage: "doc.richtext") { exportPDF() }
                        Button("Exporter en PNG", systemImage: "photo") { exportPNG() }
                    } label: {
                        Label("Fichier", systemImage: "doc")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { vm.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                        .disabled(!vm.canUndo)
                    Button { vm.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                        .disabled(!vm.canRedo)
                    Button { vm.fitToPage() } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                    Text("\(Int(vm.zoom * 100)) %")
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }
            }
            .sheet(isPresented: $showTemplateSheet) { TemplateSheet(vm: vm) }
            .sheet(isPresented: $showShare) { ActivityView(items: shareItems) }
            .alert("Export impossible", isPresented: $showExportError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "Une erreur est survenue.")
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 14) {
            Picker("Outil", selection: $vm.tool) {
                ForEach(EditorTool.allCases) { tool in
                    Image(systemName: tool.symbol).tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 250)

            Picker("Type de ligne", selection: $vm.activeKind) {
                ForEach(ElementKind.allCases) { kind in
                    Text(kind.label).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Divider().frame(height: 22)

            Toggle(isOn: $vm.showGrid) { Image(systemName: "grid") }
                .toggleStyle(.button)
            Toggle(isOn: $vm.snapEnabled) { Image(systemName: "magnet") }
                .toggleStyle(.button)
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private func exportPDF() {
        write(PDFExport.makePDF(vm.document), extension: "pdf")
    }

    private func exportPNG() {
        guard let data = PDFExport.makePNG(vm.document) else {
            exportError = "Impossible de rendre l'image PNG."
            showExportError = true
            return
        }
        write(data, extension: "png")
    }

    private func write(_ data: Data, extension ext: String) {
        let name = vm.document.name.replacingOccurrences(of: " ", with: "_")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name).\(ext)")
        do {
            try data.write(to: url, options: .atomic)
            shareItems = [url]
            showShare = true
        } catch {
            exportError = error.localizedDescription
            showExportError = true
        }
    }
}
