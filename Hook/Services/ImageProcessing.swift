import UIKit

/// Preparazione delle foto prima del salvataggio: ridimensionamento e miniatura.
/// Le funzioni non dipendono dal main thread, quindi si possono chiamare in background.
enum ImageProcessing {
    struct Risultato: Sendable {
        let foto: Data
        let miniatura: Data
    }

    static let latoMassimoFoto: CGFloat = 1600
    static let latoMassimoMiniatura: CGFloat = 400

    enum Errore: Error {
        case immagineNonValida
    }

    /// Ridimensiona la foto e crea la miniatura. Restituisce JPEG.
    static func prepara(_ dati: Data) throws -> Risultato {
        guard let originale = UIImage(data: dati) else { throw Errore.immagineNonValida }
        return try prepara(originale)
    }

    static func prepara(_ immagine: UIImage) throws -> Risultato {
        let foto = ridimensiona(immagine, latoMassimo: latoMassimoFoto)
        let miniatura = ridimensiona(immagine, latoMassimo: latoMassimoMiniatura)
        guard let datiFoto = foto.jpegData(compressionQuality: 0.85),
              let datiMiniatura = miniatura.jpegData(compressionQuality: 0.8)
        else { throw Errore.immagineNonValida }
        return Risultato(foto: datiFoto, miniatura: datiMiniatura)
    }

    /// Ridimensiona mantenendo le proporzioni, senza mai ingrandire.
    /// Applica anche l'orientamento EXIF, così la foto salvata è sempre dritta.
    static func ridimensiona(_ immagine: UIImage, latoMassimo: CGFloat) -> UIImage {
        let dimensione = immagine.size
        let lato = max(dimensione.width, dimensione.height)
        let scala = lato > latoMassimo ? latoMassimo / lato : 1
        let nuova = CGSize(width: (dimensione.width * scala).rounded(),
                           height: (dimensione.height * scala).rounded())
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: nuova, format: formato).image { _ in
            immagine.draw(in: CGRect(origin: .zero, size: nuova))
        }
    }
}
