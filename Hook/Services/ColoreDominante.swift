import UIKit

/// Colore principale di un capo, con un nome in italiano.
struct ColoreCapo: Equatable, Sendable {
    let hex: String
    let nome: String
}

enum ColoreDominante {
    /// Trova il colore più frequente dell'immagine, ignorando i pixel trasparenti (lo sfondo del ritaglio).
    static func calcola(_ immagine: UIImage) -> ColoreCapo? {
        let lato = 48
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        let piccola = UIGraphicsImageRenderer(size: CGSize(width: lato, height: lato), format: formato).image { _ in
            immagine.draw(in: CGRect(x: 0, y: 0, width: lato, height: lato))
        }
        guard let cgImage = piccola.cgImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: lato * lato * 4)
        let disegnato: Bool = pixel.withUnsafeMutableBytes { buffer in
            guard let contesto = CGContext(
                data: buffer.baseAddress,
                width: lato,
                height: lato,
                bitsPerComponent: 8,
                bytesPerRow: lato * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            contesto.draw(cgImage, in: CGRect(x: 0, y: 0, width: lato, height: lato))
            return true
        }
        guard disegnato else { return nil }

        // Istogramma con 8 livelli per canale: il secchio più pieno è il colore dominante.
        var conteggi: [Int: (n: Int, r: Int, g: Int, b: Int)] = [:]
        for indice in stride(from: 0, to: pixel.count, by: 4) {
            let alpha = Int(pixel[indice + 3])
            guard alpha >= 200 else { continue }
            // I valori sono premoltiplicati per alpha: li riportiamo al colore pieno.
            let r = min(255, Int(pixel[indice]) * 255 / alpha)
            let g = min(255, Int(pixel[indice + 1]) * 255 / alpha)
            let b = min(255, Int(pixel[indice + 2]) * 255 / alpha)
            let chiave = (r >> 5) << 6 | (g >> 5) << 3 | (b >> 5)
            let attuale = conteggi[chiave] ?? (0, 0, 0, 0)
            conteggi[chiave] = (attuale.n + 1, attuale.r + r, attuale.g + g, attuale.b + b)
        }
        guard let migliore = conteggi.values.max(by: { $0.n < $1.n }) else { return nil }

        let r = migliore.r / migliore.n
        let g = migliore.g / migliore.n
        let b = migliore.b / migliore.n
        return ColoreCapo(
            hex: String(format: "#%02X%02X%02X", r, g, b),
            nome: nome(r: r, g: g, b: b)
        )
    }

    /// Nome italiano approssimativo di un colore RGB (0...255).
    static func nome(r: Int, g: Int, b: Int) -> String {
        var tonalita: CGFloat = 0
        var saturazione: CGFloat = 0
        var luminosita: CGFloat = 0
        UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
            .getHue(&tonalita, saturation: &saturazione, brightness: &luminosita, alpha: nil)
        let gradi = tonalita * 360

        if luminosita < 0.18 { return "Nero" }
        if saturazione < 0.12 { return luminosita > 0.85 ? "Bianco" : "Grigio" }
        if (20..<55).contains(gradi), saturazione < 0.45, luminosita > 0.6 { return "Beige" }
        if (10..<45).contains(gradi), luminosita < 0.6 { return "Marrone" }
        switch gradi {
        case ..<15, 345...: return "Rosso"
        case ..<40: return "Arancione"
        case ..<65: return "Giallo"
        case ..<170: return "Verde"
        case ..<200: return "Azzurro"
        case ..<255: return "Blu"
        case ..<290: return "Viola"
        default: return "Rosa"
        }
    }
}

extension UIColor {
    /// Crea un colore da una stringa "#RRGGBB".
    convenience init?(hex: String) {
        let pulita = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard pulita.count == 6, let valore = UInt32(pulita, radix: 16) else { return nil }
        self.init(
            red: CGFloat((valore >> 16) & 0xFF) / 255,
            green: CGFloat((valore >> 8) & 0xFF) / 255,
            blue: CGFloat(valore & 0xFF) / 255,
            alpha: 1
        )
    }
}
