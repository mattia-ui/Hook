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
    /// I ritagli sono PNG, più pesanti: li teniamo un po' più piccoli.
    static let latoMassimoRitaglio: CGFloat = 1200

    enum Errore: Error {
        case immagineNonValida
    }

    /// Ridimensiona la foto e crea la miniatura. Restituisce JPEG.
    static func prepara(_ dati: Data) throws -> Risultato {
        guard let originale = UIImage(data: dati) else { throw Errore.immagineNonValida }
        return try prepara(originale)
    }

    /// Con `trasparente` le immagini sono salvate in PNG per conservare lo sfondo trasparente
    /// del ritaglio; altrimenti in JPEG, più leggero.
    static func prepara(_ immagine: UIImage, trasparente: Bool = false) throws -> Risultato {
        let foto = ridimensiona(immagine, latoMassimo: trasparente ? latoMassimoRitaglio : latoMassimoFoto)
        let miniatura = ridimensiona(immagine, latoMassimo: latoMassimoMiniatura)
        let datiFoto = trasparente ? foto.pngData() : foto.jpegData(compressionQuality: 0.85)
        let datiMiniatura = trasparente ? miniatura.pngData() : miniatura.jpegData(compressionQuality: 0.8)
        guard let datiFoto, let datiMiniatura else { throw Errore.immagineNonValida }
        return Risultato(foto: datiFoto, miniatura: datiMiniatura)
    }

    /// Foto originale compressa, conservata per poter tornare indietro dallo scontorno.
    static func originale(_ immagine: UIImage) -> Data? {
        ridimensiona(immagine, latoMassimo: latoMassimoFoto).jpegData(compressionQuality: 0.8)
    }

    /// Ritaglia un'immagine trasparente attorno alla parte visibile, con un piccolo margine.
    /// Restituisce nil se l'immagine è tutta trasparente.
    static func ritagliaAiBordi(_ immagine: UIImage, margine: CGFloat = 0.03) -> UIImage? {
        guard let cgImage = immagine.cgImage, let rettangolo = Maschera.rettangoloOpaco(cgImage) else { return nil }
        let bordo = max(rettangolo.width, rettangolo.height) * margine
        let conMargine = rettangolo
            .insetBy(dx: -bordo, dy: -bordo)
            .intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            .integral
        guard let ritagliata = cgImage.cropping(to: conMargine) else { return nil }
        return UIImage(cgImage: ritagliata)
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
