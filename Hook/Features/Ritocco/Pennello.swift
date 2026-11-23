import UIKit

/// Disegno dei tratti di ritocco sullo scontorno. Separato dalla vista per poterlo testare.
enum Pennello {
    enum Modalita: String, CaseIterable, Identifiable, Sendable {
        case gomma
        case ripristina

        var id: String { rawValue }

        var nome: String {
            switch self {
            case .gomma: "Gomma"
            case .ripristina: "Ripristina"
            }
        }

        var simbolo: String {
            switch self {
            case .gomma: "eraser"
            case .ripristina: "paintbrush.pointed"
            }
        }
    }

    /// Applica un tratto al ritaglio. La gomma rende trasparente, il ripristino riporta i pixel
    /// della foto originale. Punti e spessore sono in pixel dell'immagine.
    static func applica(
        tratto: [CGPoint],
        spessore: CGFloat,
        modalita: Modalita,
        a ritaglio: UIImage,
        originale: UIImage
    ) -> UIImage {
        guard let primo = tratto.first else { return ritaglio }
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        let dimensione = ritaglio.size
        return UIGraphicsImageRenderer(size: dimensione, format: formato).image { contesto in
            ritaglio.draw(in: CGRect(origin: .zero, size: dimensione))

            let percorso = CGMutablePath()
            percorso.move(to: primo)
            if tratto.count == 1 {
                // Un tocco singolo: un puntino.
                percorso.addLine(to: CGPoint(x: primo.x + 0.01, y: primo.y))
            } else {
                for punto in tratto.dropFirst() {
                    percorso.addLine(to: punto)
                }
            }

            let cg = contesto.cgContext
            switch modalita {
            case .gomma:
                cg.setBlendMode(.clear)
                cg.setLineCap(.round)
                cg.setLineJoin(.round)
                cg.setLineWidth(spessore)
                cg.addPath(percorso)
                cg.strokePath()
            case .ripristina:
                let area = percorso.copy(strokingWithWidth: spessore, lineCap: .round, lineJoin: .round, miterLimit: 10)
                cg.addPath(area)
                cg.clip()
                originale.draw(in: CGRect(origin: .zero, size: dimensione))
            }
        }
    }

    /// Converte un punto toccato sullo schermo nelle coordinate dell'immagine mostrata in `riquadro`.
    static func puntoImmagine(_ punto: CGPoint, riquadro: CGRect, dimensioneImmagine: CGSize) -> CGPoint {
        guard riquadro.width > 0, riquadro.height > 0 else { return .zero }
        return CGPoint(
            x: (punto.x - riquadro.minX) / riquadro.width * dimensioneImmagine.width,
            y: (punto.y - riquadro.minY) / riquadro.height * dimensioneImmagine.height
        )
    }

    /// Il riquadro occupato da un'immagine adattata (aspect fit) in uno spazio.
    static func riquadroAdattato(dimensioneImmagine: CGSize, in spazio: CGSize) -> CGRect {
        guard dimensioneImmagine.width > 0, dimensioneImmagine.height > 0 else { return .zero }
        let scala = min(spazio.width / dimensioneImmagine.width, spazio.height / dimensioneImmagine.height)
        let larghezza = dimensioneImmagine.width * scala
        let altezza = dimensioneImmagine.height * scala
        return CGRect(
            x: (spazio.width - larghezza) / 2,
            y: (spazio.height - altezza) / 2,
            width: larghezza,
            height: altezza
        )
    }
}
