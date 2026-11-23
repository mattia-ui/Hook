import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Risultato dello scontorno. Il ritaglio ha la stessa dimensione dell'originale normalizzato,
/// così il ritocco a mano può ripristinare pixel dall'originale nella stessa posizione.
struct RisultatoScontorno: Sendable {
    /// Il capo su sfondo trasparente, non ancora ritagliato ai bordi.
    let ritaglio: UIImage
    /// La foto originale, raddrizzata e alla stessa dimensione del ritaglio.
    let originale: UIImage
}

/// Rimozione dello sfondo con Vision, lo stesso motore di "Solleva soggetto" di Foto.
/// Rispetto all'uso diretto di Vision:
/// 1. tiene solo il capo principale (scarta grucce, mobili, mani ai margini);
/// 2. elimina i frammenti di sfondo staccati dal capo;
/// 3. stringe di un pixel e sfuma il bordo, per togliere l'alone dello sfondo.
/// Gira sul dispositivo; sul simulatore Vision di solito non è disponibile e la funzione lancia un errore.
enum Scontorno {
    enum Errore: Error {
        case immagineNonValida
        case nessunSoggetto
    }

    static func scontorna(_ immagine: UIImage, latoMassimo: CGFloat = 1600) throws -> RisultatoScontorno {
        let normalizzata = ImageProcessing.ridimensiona(immagine, latoMassimo: latoMassimo)
        guard let cgImage = normalizzata.cgImage else { throw Errore.immagineNonValida }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        let richiesta = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([richiesta])
        guard let risultato = richiesta.results?.first, !risultato.allInstances.isEmpty else {
            throw Errore.nessunSoggetto
        }

        // 1. Solo il capo principale.
        let etichette = Maschera.leggiEtichette(risultato.instanceMask)
        let istanze = Maschera.istanzePrincipali(
            etichette: etichette.valori,
            larghezza: etichette.larghezza,
            altezza: etichette.altezza,
            candidate: risultato.allInstances
        )

        // 2. Maschera alla risoluzione della foto, senza isole di sfondo.
        let bufferMaschera = try risultato.generateScaledMaskForImage(forInstances: istanze, from: handler)
        var maschera = Maschera.leggiMaschera(bufferMaschera)
        Maschera.rimuoviIsole(&maschera.valori, larghezza: maschera.larghezza, altezza: maschera.altezza)
        guard let grigia = Maschera.immagineGrigia(maschera.valori, larghezza: maschera.larghezza, altezza: maschera.altezza)
        else { throw Errore.immagineNonValida }

        // 3. Bordo più pulito: erosione leggera e sfumatura.
        let sorgente = CIImage(cgImage: cgImage)
        var mascheraCI = CIImage(cgImage: grigia)
        if mascheraCI.extent.size != sorgente.extent.size {
            mascheraCI = mascheraCI.transformed(by: CGAffineTransform(
                scaleX: sorgente.extent.width / mascheraCI.extent.width,
                y: sorgente.extent.height / mascheraCI.extent.height
            ))
        }
        let erosione = CIFilter.morphologyMinimum()
        erosione.inputImage = mascheraCI.clampedToExtent()
        erosione.radius = 1.5
        let sfumatura = CIFilter.gaussianBlur()
        sfumatura.inputImage = erosione.outputImage
        sfumatura.radius = 1.2
        guard let mascheraRifinita = sfumatura.outputImage?.cropped(to: sorgente.extent) else {
            throw Errore.immagineNonValida
        }

        let fusione = CIFilter.blendWithMask()
        fusione.inputImage = sorgente
        fusione.backgroundImage = CIImage.empty()
        fusione.maskImage = mascheraRifinita
        guard let uscita = fusione.outputImage?.cropped(to: sorgente.extent),
              let spazio = CGColorSpace(name: CGColorSpace.sRGB),
              let finale = CIContext().createCGImage(uscita, from: sorgente.extent, format: .RGBA8, colorSpace: spazio)
        else { throw Errore.immagineNonValida }

        return RisultatoScontorno(ritaglio: UIImage(cgImage: finale), originale: normalizzata)
    }

    /// Scontorna e ritaglia attorno al capo, in un passaggio.
    static func ritaglia(_ immagine: UIImage, latoMassimo: CGFloat = 1600) throws -> UIImage {
        let risultato = try scontorna(immagine, latoMassimo: latoMassimo)
        guard let ritagliata = ImageProcessing.ritagliaAiBordi(risultato.ritaglio) else {
            throw Errore.nessunSoggetto
        }
        return ritagliata
    }
}
