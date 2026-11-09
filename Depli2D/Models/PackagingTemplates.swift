import CoreGraphics

enum PackagingTemplates {

    struct Carton0201 {
        var longueur: CGFloat = 200
        var largeur: CGFloat = 120
        var hauteur: CGFloat = 80
        var onglet: CGFloat = 30
        var jeu: CGFloat = 2
    }

    static func cartonFendu0201(_ p: Carton0201) -> [DelineElement] {
        let g = p.onglet
        let W = p.largeur
        let L = p.longueur
        let H = p.hauteur
        let rabatMajeur = W / 2
        let rabatMineur = Swift.max(L / 2 - p.jeu, 10)
        let biseau = Swift.min(12, H / 3)

        let xs: [CGFloat] = [g, g + W, g + W + L, g + W + L + W, g + W + L + W + L]
        let hs: [CGFloat] = [rabatMineur, rabatMajeur, rabatMineur, rabatMajeur]

        var contour: [CGPoint] = [
            CGPoint(x: 0, y: biseau),
            CGPoint(x: g, y: 0)
        ]
        contour.append(CGPoint(x: xs[0], y: -hs[0]))
        for i in 0..<4 {
            contour.append(CGPoint(x: xs[i + 1], y: -hs[i]))
            if i < 3 {
                contour.append(CGPoint(x: xs[i + 1], y: -hs[i + 1]))
            }
        }
        contour.append(CGPoint(x: xs[4], y: H))
        contour.append(CGPoint(x: xs[4], y: H + hs[3]))
        for i in stride(from: 3, through: 0, by: -1) {
            contour.append(CGPoint(x: xs[i], y: H + hs[i]))
            if i > 0 {
                contour.append(CGPoint(x: xs[i], y: H + hs[i - 1]))
            }
        }
        contour.append(CGPoint(x: xs[0], y: H))
        contour.append(CGPoint(x: 0, y: H - biseau))

        var elements: [DelineElement] = [
            DelineElement(kind: .cut, points: contour, closed: true, label: "Contour 0201")
        ]
        for x in xs.dropLast() {
            elements.append(DelineElement(kind: .crease, points: [CGPoint(x: x, y: 0), CGPoint(x: x, y: H)]))
        }
        elements.append(DelineElement(kind: .crease, points: [CGPoint(x: xs[0], y: 0), CGPoint(x: xs[4], y: 0)]))
        elements.append(DelineElement(kind: .crease, points: [CGPoint(x: xs[0], y: H), CGPoint(x: xs[4], y: H)]))
        return elements
    }

    static func rectangle(longueur: CGFloat, largeur: CGFloat) -> [DelineElement] {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: longueur, y: 0),
            CGPoint(x: longueur, y: largeur),
            CGPoint(x: 0, y: largeur)
        ]
        return [DelineElement(kind: .cut, points: points, closed: true)]
    }
}
