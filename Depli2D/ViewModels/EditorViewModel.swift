import SwiftUI

enum EditorTool: String, CaseIterable, Identifiable {
    case select
    case line
    case rect
    case freehand
    case pan

    var id: String { rawValue }

    var label: String {
        switch self {
        case .select: return "Sélection"
        case .line: return "Ligne"
        case .rect: return "Rectangle"
        case .freehand: return "Tracé libre"
        case .pan: return "Main"
        }
    }

    var symbol: String {
        switch self {
        case .select: return "arrow.up.left"
        case .line: return "line.diagonal"
        case .rect: return "rectangle"
        case .freehand: return "pencil.line"
        case .pan: return "hand.drag"
        }
    }
}

final class EditorViewModel: ObservableObject {
    @Published var document: DielineDocument
    @Published var tool: EditorTool = .select
    @Published var activeKind: ElementKind = .cut
    @Published var zoom: CGFloat = 1
    @Published var offset: CGSize = .zero
    @Published var selectedID: UUID?
    @Published var gridStep: CGFloat = 10
    @Published var snapEnabled = true
    @Published var snapStep: CGFloat = 1
    @Published var showGrid = true
    @Published var draftElement: DelineElement?
    @Published var canUndo = false
    @Published var canRedo = false

    private(set) var baseScale: CGFloat = 2.8
    private var viewport: CGSize = .zero
    private var firstLayout = true

    private var undoStack: [DielineDocument] = []
    private var redoStack: [DielineDocument] = []

    private enum DragMode { case none, drawing, moving, panning }
    private var dragMode: DragMode = .none
    private var dragStartDoc: CGPoint = .zero
    private var panStartOffset: CGSize = .zero
    private var moveLastDoc: CGPoint = .zero
    private var dragHistoryPushed = false

    private var pinching = false
    private var pinchStartZoom: CGFloat = 1
    private var pinchAnchorDoc: CGPoint = .zero

    init(document: DielineDocument = .default) {
        self.document = document
    }

    var scale: CGFloat { baseScale * zoom }

    // MARK: - Viewport

    func setViewport(_ size: CGSize) {
        guard size.width > 0, size.height > 0, size != viewport else { return }
        viewport = size
        baseScale = Swift.min(size.width / document.pageWidth, size.height / document.pageHeight) * 0.9
        if firstLayout {
            firstLayout = false
            fitToPage()
        }
    }

    func fitToPage() {
        guard viewport.width > 0 else { return }
        zoom = 1
        let s = scale
        offset = CGSize(width: (viewport.width - document.pageWidth * s) / 2,
                        height: (viewport.height - document.pageHeight * s) / 2)
    }

    // MARK: - Transformations

    func toDoc(_ screen: CGPoint) -> CGPoint {
        CGPoint(x: (screen.x - offset.width) / scale,
                y: (screen.y - offset.height) / scale)
    }

    func toScreen(_ doc: CGPoint) -> CGPoint {
        CGPoint(x: doc.x * scale + offset.width,
                y: doc.y * scale + offset.height)
    }

    func snapPoint(_ p: CGPoint) -> CGPoint {
        snapEnabled ? snap(p, step: snapStep) : p
    }

    private func toleranceDoc() -> CGFloat { 8 / scale }

    // MARK: - Historique

    private func pushHistory() {
        undoStack.append(document)
        if undoStack.count > 100 { undoStack.removeFirst() }
        redoStack.removeAll()
        canUndo = true
        canRedo = false
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(document)
        document = previous
        canUndo = !undoStack.isEmpty
        canRedo = true
        if let id = selectedID, !document.elements.contains(where: { $0.id == id }) {
            selectedID = nil
        }
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(document)
        document = next
        canRedo = !redoStack.isEmpty
        canUndo = true
        if let id = selectedID, !document.elements.contains(where: { $0.id == id }) {
            selectedID = nil
        }
    }

    private func mutate(_ block: (inout DielineDocument) -> Void) {
        pushHistory()
        block(&document)
    }

    // MARK: - Mutations

    func newDocument() {
        mutate { $0 = .default }
        selectedID = nil
        fitToPage()
    }

    func addElement(_ element: DelineElement) {
        mutate { $0.elements.append(element) }
        selectedID = element.id
    }

    func insertElements(_ elements: [DelineElement]) {
        guard !elements.isEmpty else { return }
        mutate { $0.elements.append(contentsOf: elements) }
    }

    func deleteSelected() {
        guard let id = selectedID else { return }
        mutate { $0.elements.removeAll { $0.id == id } }
        selectedID = nil
    }

    func duplicateSelected() {
        guard let id = selectedID,
              let element = document.elements.first(where: { $0.id == id }) else { return }
        var copy = element
        copy.id = UUID()
        copy.points = element.points.map { CGPoint(x: $0.x + 5, y: $0.y + 5) }
        mutate { $0.elements.append(copy) }
        selectedID = copy.id
    }

    func setKindOfSelected(_ kind: ElementKind) {
        guard let id = selectedID else { return }
        mutate { doc in
            if let i = doc.elements.firstIndex(where: { $0.id == id }) {
                doc.elements[i].kind = kind
            }
        }
    }

    func moveSelectedTo(x: CGFloat, y: CGFloat) {
        guard let id = selectedID,
              let element = document.elements.first(where: { $0.id == id }) else { return }
        let dx = x - element.centroid.x
        let dy = y - element.centroid.y
        mutate { doc in
            if let i = doc.elements.firstIndex(where: { $0.id == id }) {
                doc.elements[i].points = element.points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
            }
        }
    }

    func hitTest(_ p: CGPoint) -> UUID? {
        let tolerance = toleranceDoc()
        for element in document.elements.reversed()
        where distanceToPolyline(p, element.points, closed: element.closed) <= tolerance {
            return element.id
        }
        return nil
    }

    // MARK: - Gestes

    func dragChanged(_ value: DragGesture.Value) {
        let doc = toDoc(value.location)
        switch tool {
        case .pan:
            if dragMode == .none {
                dragMode = .panning
                panStartOffset = offset
            }
            offset = CGSize(width: panStartOffset.width + value.translation.width,
                            height: panStartOffset.height + value.translation.height)

        case .select:
            if dragMode == .none {
                let tolerance = toleranceDoc()
                if let id = selectedID,
                   let element = document.elements.first(where: { $0.id == id }),
                   distanceToPolyline(doc, element.points, closed: element.closed) <= tolerance {
                    dragMode = .moving
                    moveLastDoc = doc
                } else if let hit = hitTest(doc) {
                    selectedID = hit
                    dragMode = .moving
                    moveLastDoc = doc
                } else {
                    dragMode = .panning
                    panStartOffset = offset
                }
            }
            switch dragMode {
            case .moving:
                if !dragHistoryPushed {
                    pushHistory()
                    dragHistoryPushed = true
                }
                let dx = doc.x - moveLastDoc.x
                let dy = doc.y - moveLastDoc.y
                moveLastDoc = doc
                if let id = selectedID, let i = document.elements.firstIndex(where: { $0.id == id }) {
                    document.elements[i].points = document.elements[i].points.map {
                        CGPoint(x: $0.x + dx, y: $0.y + dy)
                    }
                }
            case .panning:
                offset = CGSize(width: panStartOffset.width + value.translation.width,
                                height: panStartOffset.height + value.translation.height)
            case .none, .drawing:
                break
            }

        case .line, .rect, .freehand:
            if dragMode == .none {
                dragMode = .drawing
                dragStartDoc = snapPoint(doc)
                draftElement = DelineElement(kind: activeKind, points: [dragStartDoc])
            }
            guard var draft = draftElement else { return }
            switch tool {
            case .line:
                draft.points = [dragStartDoc, snapPoint(doc)]
            case .rect:
                let a = dragStartDoc
                let b = snapPoint(doc)
                draft.points = [a, CGPoint(x: b.x, y: a.y), b, CGPoint(x: a.x, y: b.y)]
                draft.closed = true
            case .freehand:
                let p = snapPoint(doc)
                if let last = draft.points.last, hypot(p.x - last.x, p.y - last.y) > 0.5 {
                    draft.points.append(p)
                }
            default:
                break
            }
            draftElement = draft
        }
    }

    func dragEnded(_ value: DragGesture.Value) {
        switch tool {
        case .line, .rect, .freehand:
            if var draft = draftElement {
                if tool == .freehand {
                    let p = snapPoint(toDoc(value.location))
                    if let last = draft.points.last, hypot(p.x - last.x, p.y - last.y) > 0.5 {
                        draft.points.append(p)
                    }
                }
                let valid: Bool
                switch tool {
                case .line:
                    let a = draft.points[0]
                    let b = draft.points[draft.points.count - 1]
                    valid = draft.points.count >= 2 && hypot(a.x - b.x, a.y - b.y) > 0.1
                case .rect:
                    valid = draft.points.count == 4
                default:
                    valid = draft.points.count >= 2
                }
                if valid { addElement(draft) }
            }
        case .select:
            if dragMode == .panning,
               abs(value.translation.width) < 4,
               abs(value.translation.height) < 4 {
                selectedID = hitTest(toDoc(value.location))
            }
        case .pan:
            break
        }
        draftElement = nil
        dragMode = .none
        dragHistoryPushed = false
    }

    func pinchChanged(_ value: CGFloat, center: CGPoint) {
        if !pinching {
            pinching = true
            pinchStartZoom = zoom
            pinchAnchorDoc = toDoc(center)
        }
        let newZoom = clamp(pinchStartZoom * value, 0.2, 20)
        let newScale = baseScale * newZoom
        zoom = newZoom
        offset = CGSize(width: center.x - pinchAnchorDoc.x * newScale,
                        height: center.y - pinchAnchorDoc.y * newScale)
    }

    func pinchEnded() {
        pinching = false
    }
}
