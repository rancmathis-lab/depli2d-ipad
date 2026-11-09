import SwiftUI

struct CanvasView: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            let drag = DragGesture(minimumDistance: 3)
                .onChanged { vm.dragChanged($0) }
                .onEnded { vm.dragEnded($0) }
            let pinch = MagnificationGesture()
                .onChanged { vm.pinchChanged($0, center: center) }
                .onEnded { vm.pinchEnded() }

            Canvas { context, _ in
                draw(context: context, size: size)
            }
            .onAppear { vm.setViewport(size) }
            .onChange(of: size) { _, newSize in vm.setViewport(newSize) }
            .gesture(drag.simultaneously(with: pinch))
        }
        .background(Color(.systemBackground))
    }

    private func draw(context: GraphicsContext, size: CGSize) {
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(.systemBackground)))

        let visibleDoc = CGRect(
            x: -vm.offset.width / vm.scale,
            y: -vm.offset.height / vm.scale,
            width: size.width / vm.scale,
            height: size.height / vm.scale
        )

        if vm.showGrid {
            drawGrid(context, size: size, visible: visibleDoc)
        }

        let pageOrigin = vm.toScreen(.zero)
        let pageRect = CGRect(
            x: pageOrigin.x,
            y: pageOrigin.y,
            width: vm.document.pageWidth * vm.scale,
            height: vm.document.pageHeight * vm.scale
        )
        context.fill(Path(pageRect), with: .color(.white))
        context.stroke(Path(pageRect), with: .color(Color(.separator)), lineWidth: 1.5)

        for element in vm.document.elements {
            let path = screenPath(element)
            if element.id == vm.selectedID {
                context.stroke(path, with: .color(element.kind.color.opacity(0.25)), lineWidth: 10)
            }
            context.stroke(path, with: .color(element.kind.color),
                           style: StrokeStyle(lineWidth: element.kind.lineWidth, dash: element.kind.dash))
            if element.id == vm.selectedID {
                for p in element.points {
                    let s = vm.toScreen(p)
                    let handle = CGRect(x: s.x - 5, y: s.y - 5, width: 10, height: 10)
                    context.fill(Path(ellipseIn: handle), with: .color(.white))
                    context.stroke(Path(ellipseIn: handle), with: .color(element.kind.color), lineWidth: 1.5)
                }
            }
        }

        if let draft = vm.draftElement {
            context.stroke(screenPath(draft), with: .color(draft.kind.color.opacity(0.9)),
                           style: StrokeStyle(lineWidth: draft.kind.lineWidth, dash: draft.kind.dash))
        }

        drawRulers(context, size: size, visible: visibleDoc)
    }

    private func screenPath(_ element: DelineElement) -> Path {
        var path = Path()
        guard let first = element.points.first else { return path }
        path.move(to: vm.toScreen(first))
        for p in element.points.dropFirst() {
            path.addLine(to: vm.toScreen(p))
        }
        if element.closed { path.closeSubpath() }
        return path
    }

    private func drawGrid(_ context: GraphicsContext, size: CGSize, visible: CGRect) {
        let step = vm.gridStep
        guard step > 0 else { return }
        let majorStep = step * 5

        var x = floor(visible.minX / step) * step
        while x <= visible.maxX {
            let sx = vm.toScreen(CGPoint(x: x, y: 0)).x
            var path = Path()
            path.move(to: CGPoint(x: sx, y: 0))
            path.addLine(to: CGPoint(x: sx, y: size.height))
            let r = x.truncatingRemainder(dividingBy: majorStep)
            let major = r < 0.001 || majorStep - r < 0.001
            context.stroke(path, with: .color(Color.gray.opacity(major ? 0.4 : 0.15)), lineWidth: 1)
            x += step
        }

        var y = floor(visible.minY / step) * step
        while y <= visible.maxY {
            let sy = vm.toScreen(CGPoint(x: 0, y: y)).y
            var path = Path()
            path.move(to: CGPoint(x: 0, y: sy))
            path.addLine(to: CGPoint(x: size.width, y: sy))
            let r = y.truncatingRemainder(dividingBy: majorStep)
            let major = r < 0.001 || majorStep - r < 0.001
            context.stroke(path, with: .color(Color.gray.opacity(major ? 0.4 : 0.15)), lineWidth: 1)
            y += step
        }
    }

    private func drawRulers(_ context: GraphicsContext, size: CGSize, visible: CGRect) {
        let step = vm.gridStep
        guard step > 0 else { return }
        let majorStep = step * 5

        var x = floor(visible.minX / step) * step
        while x <= visible.maxX {
            let sx = vm.toScreen(CGPoint(x: x, y: 0)).x
            var path = Path()
            path.move(to: CGPoint(x: sx, y: 0))
            path.addLine(to: CGPoint(x: sx, y: 7))
            context.stroke(path, with: .color(Color.secondary), lineWidth: 1)
            let r = x.truncatingRemainder(dividingBy: majorStep)
            if r < 0.001 || majorStep - r < 0.001 {
                context.draw(
                    Text("\(Int(x)) mm").font(.system(size: 9)).foregroundStyle(.secondary),
                    at: CGPoint(x: sx + 2, y: 8),
                    anchor: .topLeading
                )
            }
            x += step
        }

        var y = floor(visible.minY / step) * step
        while y <= visible.maxY {
            let sy = vm.toScreen(CGPoint(x: 0, y: y)).y
            var path = Path()
            path.move(to: CGPoint(x: 0, y: sy))
            path.addLine(to: CGPoint(x: 7, y: sy))
            context.stroke(path, with: .color(Color.secondary), lineWidth: 1)
            let r = y.truncatingRemainder(dividingBy: majorStep)
            if r < 0.001 || majorStep - r < 0.001 {
                context.draw(
                    Text("\(Int(y)) mm").font(.system(size: 9)).foregroundStyle(.secondary),
                    at: CGPoint(x: 8, y: sy - 4),
                    anchor: .topLeading
                )
            }
            y += step
        }
    }
}
