import CoreImage
import UIKit
import Vision

/// Rimozione dello sfondo con Vision, lo stesso motore di "Solleva soggetto" di Foto.
/// Gira sul dispositivo; sul simulatore Vision di solito non è disponibile e la funzione lancia un errore.
enum Scontorno {
    enum Errore: Error {
        case immagineNonValida
        case nessunSoggetto
    }

    /// Restituisce il soggetto principale su sfondo trasparente, ritagliato attorno al soggetto.
    static func ritaglia(_ immagine: UIImage, latoMassimo: CGFloat = 1600) throws -> UIImage {
        // Normalizza orientamento e dimensione: Vision lavora su un'immagine "dritta".
        let normalizzata = ImageProcessing.ridimensiona(immagine, latoMassimo: latoMassimo)
        guard let cgImage = normalizzata.cgImage else { throw Errore.immagineNonValida }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        let richiesta = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([richiesta])

        guard let risultato = richiesta.results?.first, !risultato.allInstances.isEmpty else {
            throw Errore.nessunSoggetto
        }
        let buffer = try risultato.generateMaskedImage(
            ofInstances: risultato.allInstances,
            from: handler,
            croppedToInstancesExtent: true
        )
        let ciImage = CIImage(cvPixelBuffer: buffer)
        guard let ritaglio = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
            throw Errore.immagineNonValida
        }
        return UIImage(cgImage: ritaglio)
    }
}
