import UIKit
import Vision

/// Suggerisce la categoria di un capo usando il classificatore di immagini integrato in iOS.
/// È un primo passo: più avanti si può sostituire con un modello Core ML addestrato sui vestiti.
enum RiconoscimentoCategoria {
    /// Parole chiave (in inglese, come le etichette di Vision) e categoria corrispondente.
    static let paroleChiave: [String: Categoria] = [
        "sneaker": .scarpe, "shoe": .scarpe, "boot": .scarpe, "sandal": .scarpe, "footwear": .scarpe,
        "heel": .scarpe, "loafer": .scarpe, "slipper": .scarpe,
        "handbag": .borse, "bag": .borse, "backpack": .borse, "purse": .borse, "tote": .borse,
        "jeans": .pantaloni, "trousers": .pantaloni, "pants": .pantaloni, "shorts": .pantaloni,
        "denim": .pantaloni, "leggings": .pantaloni,
        "skirt": .gonne,
        "dress": .vestiti, "gown": .vestiti, "jumpsuit": .vestiti,
        "jacket": .capispalla, "coat": .capispalla, "blazer": .capispalla, "parka": .capispalla,
        "raincoat": .capispalla, "vest": .capispalla, "cardigan": .capispalla,
        "shirt": .top, "tshirt": .top, "sweater": .top, "sweatshirt": .top, "hoodie": .top,
        "blouse": .top, "jersey": .top, "polo": .top, "tank": .top,
        "hat": .accessori, "cap": .accessori, "sunglasses": .accessori, "glasses": .accessori,
        "scarf": .accessori, "tie": .accessori, "belt": .accessori, "watch": .accessori,
        "jewelry": .accessori, "necklace": .accessori, "bracelet": .accessori, "glove": .accessori,
        "wallet": .accessori,
    ]

    static let sogliaMinima: Float = 0.15

    /// Classifica l'immagine con Vision e restituisce la categoria più probabile, se abbastanza sicura.
    static func suggerisci(per immagine: UIImage) -> Categoria? {
        guard let cgImage = ImageProcessing.ridimensiona(immagine, latoMassimo: 800).cgImage else { return nil }
        let richiesta = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
        do {
            try handler.perform([richiesta])
        } catch {
            return nil
        }
        let etichette = (richiesta.results ?? []).map { ($0.identifier, $0.confidence) }
        return categoria(da: etichette)
    }

    /// Somma le confidenze delle etichette per categoria e sceglie la migliore.
    /// Separata da Vision così si può testare con etichette finte.
    static func categoria(da etichette: [(String, Float)]) -> Categoria? {
        var punteggi: [Categoria: Float] = [:]
        for (identificatore, confidenza) in etichette {
            if let categoria = categoria(per: identificatore) {
                punteggi[categoria, default: 0] += confidenza
            }
        }
        guard let migliore = punteggi.max(by: { $0.value < $1.value }), migliore.value >= sogliaMinima else {
            return nil
        }
        return migliore.key
    }

    /// Cerca la categoria di un'etichetta, parola per parola partendo dall'ultima
    /// (in inglese il sostantivo principale è in fondo: "dress_shirt" è una camicia).
    static func categoria(per identificatore: String) -> Categoria? {
        let parole = identificatore
            .lowercased()
            .replacingOccurrences(of: "t_shirt", with: "tshirt")
            .replacingOccurrences(of: "t-shirt", with: "tshirt")
            .split(whereSeparator: { $0 == "_" || $0 == " " || $0 == "-" })
            .map(String.init)
        for parola in parole.reversed() {
            if let categoria = paroleChiave[parola] { return categoria }
            if parola.hasSuffix("s"), let categoria = paroleChiave[String(parola.dropLast())] { return categoria }
        }
        return nil
    }
}
