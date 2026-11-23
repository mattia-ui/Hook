import CoreGraphics
import CoreVideo
import Foundation

/// Algoritmi sulle maschere di scontorno. Lavorano su array semplici così si possono testare
/// senza Vision (che sul simulatore non è disponibile).
enum Maschera {
    /// Sceglie quali oggetti trovati da Vision tenere: quello principale (grande e vicino al centro)
    /// più gli altri di dimensione paragonabile, come la seconda scarpa di un paio.
    /// Gli oggetti piccoli o ai margini (grucce, mobili, mani) vengono scartati.
    ///
    /// - Parameters:
    ///   - etichette: per ogni pixel, l'indice dell'oggetto (0 = sfondo), riga per riga.
    ///   - candidate: gli indici degli oggetti trovati.
    static func istanzePrincipali(
        etichette: [UInt8],
        larghezza: Int,
        altezza: Int,
        candidate: IndexSet,
        sogliaRelativa: Double = 0.3
    ) -> IndexSet {
        guard larghezza > 0, altezza > 0 else { return candidate }
        var area: [Int: Int] = [:]
        var sommaX: [Int: Int] = [:]
        var sommaY: [Int: Int] = [:]
        for y in 0..<altezza {
            let riga = y * larghezza
            for x in 0..<larghezza {
                let etichetta = Int(etichette[riga + x])
                guard etichetta != 0, candidate.contains(etichetta) else { continue }
                area[etichetta, default: 0] += 1
                sommaX[etichetta, default: 0] += x
                sommaY[etichetta, default: 0] += y
            }
        }
        guard !area.isEmpty else { return candidate }

        let centroX = Double(larghezza) / 2
        let centroY = Double(altezza) / 2
        let diagonale = (centroX * centroX + centroY * centroY).squareRoot()
        func punteggio(_ etichetta: Int) -> Double {
            let n = Double(area[etichetta] ?? 0)
            guard n > 0 else { return 0 }
            let dx = Double(sommaX[etichetta] ?? 0) / n - centroX
            let dy = Double(sommaY[etichetta] ?? 0) / n - centroY
            let distanza = (dx * dx + dy * dy).squareRoot() / diagonale // 0 al centro, 1 nell'angolo
            return n * (1 - 0.6 * distanza)
        }
        guard let principale = area.keys.max(by: { punteggio($0) < punteggio($1) }) else { return candidate }
        let areaPrincipale = Double(area[principale] ?? 0)

        var tenute = IndexSet(integer: principale)
        for (etichetta, n) in area where etichetta != principale && Double(n) >= areaPrincipale * sogliaRelativa {
            tenute.insert(etichetta)
        }
        return tenute
    }

    /// Azzera le "isole" della maschera più piccole di una frazione della più grande:
    /// sono i pezzetti di sfondo rimasti attaccati per errore. Valori 0...1, riga per riga.
    /// - Returns: il numero di isole tenute.
    @discardableResult
    static func rimuoviIsole(
        _ valori: inout [Float],
        larghezza: Int,
        altezza: Int,
        soglia: Float = 0.5,
        sogliaRelativa: Double = 0.1
    ) -> Int {
        let totale = larghezza * altezza
        guard totale > 0, valori.count == totale else { return 0 }

        var etichette = [Int32](repeating: 0, count: totale)
        var aree: [Int] = [0] // aree[i] = pixel dell'isola i (indice 0 non usato)
        var pila: [Int] = []
        pila.reserveCapacity(4096)

        for inizio in 0..<totale where valori[inizio] > soglia && etichette[inizio] == 0 {
            let etichetta = Int32(aree.count)
            var area = 0
            etichette[inizio] = etichetta
            pila.append(inizio)
            while let indice = pila.popLast() {
                area += 1
                let x = indice % larghezza
                // I quattro vicini, senza allocare nulla nel ciclo (qui passano milioni di pixel).
                if x > 0 {
                    visita(indice - 1, etichetta, &etichette, &pila, valori, soglia)
                }
                if x < larghezza - 1 {
                    visita(indice + 1, etichetta, &etichette, &pila, valori, soglia)
                }
                if indice >= larghezza {
                    visita(indice - larghezza, etichetta, &etichette, &pila, valori, soglia)
                }
                if indice + larghezza < totale {
                    visita(indice + larghezza, etichetta, &etichette, &pila, valori, soglia)
                }
            }
            aree.append(area)
        }

        guard let massima = aree.max(), massima > 0 else { return 0 }
        let minima = Int((Double(massima) * sogliaRelativa).rounded(.up))
        let tenere = aree.map { $0 >= minima }

        for indice in 0..<totale {
            let etichetta = Int(etichette[indice])
            // I pixel sotto soglia (bordi sfumati) restano: la sfumatura finale li sistema.
            if etichetta != 0 && !tenere[etichetta] { valori[indice] = 0 }
        }
        return tenere.dropFirst().filter { $0 }.count
    }

    @inline(__always)
    private static func visita(
        _ vicino: Int,
        _ etichetta: Int32,
        _ etichette: inout [Int32],
        _ pila: inout [Int],
        _ valori: [Float],
        _ soglia: Float
    ) {
        if etichette[vicino] == 0 && valori[vicino] > soglia {
            etichette[vicino] = etichetta
            pila.append(vicino)
        }
    }

    /// Rettangolo che contiene tutti i pixel con alpha sopra la soglia, o nil se l'immagine è vuota.
    static func rettangoloOpaco(_ immagine: CGImage, sogliaAlpha: UInt8 = 8) -> CGRect? {
        let larghezza = immagine.width
        let altezza = immagine.height
        guard larghezza > 0, altezza > 0 else { return nil }
        var alpha = [UInt8](repeating: 0, count: larghezza * altezza)
        let disegnato: Bool = alpha.withUnsafeMutableBytes { buffer in
            guard let contesto = CGContext(
                data: buffer.baseAddress,
                width: larghezza,
                height: altezza,
                bitsPerComponent: 8,
                bytesPerRow: larghezza,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue
            ) else { return false }
            contesto.draw(immagine, in: CGRect(x: 0, y: 0, width: larghezza, height: altezza))
            return true
        }
        guard disegnato else { return nil }

        var minX = larghezza, minY = altezza, maxX = -1, maxY = -1
        for y in 0..<altezza {
            let riga = y * larghezza
            for x in 0..<larghezza where alpha[riga + x] > sogliaAlpha {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
        guard maxX >= 0 else { return nil }
        // Il buffer ha la riga 0 in alto, come le coordinate di CGImage.cropping(to:).
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    // MARK: - Lettura dei buffer di Vision

    /// Legge un CVPixelBuffer a un canale da 8 bit (le etichette degli oggetti di Vision).
    static func leggiEtichette(_ buffer: CVPixelBuffer) -> (valori: [UInt8], larghezza: Int, altezza: Int) {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let larghezza = CVPixelBufferGetWidth(buffer)
        let altezza = CVPixelBufferGetHeight(buffer)
        let perRiga = CVPixelBufferGetBytesPerRow(buffer)
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return ([], 0, 0) }
        var valori = [UInt8](repeating: 0, count: larghezza * altezza)
        for y in 0..<altezza {
            let riga = base.advanced(by: y * perRiga).assumingMemoryBound(to: UInt8.self)
            for x in 0..<larghezza {
                valori[y * larghezza + x] = riga[x]
            }
        }
        return (valori, larghezza, altezza)
    }

    /// Legge un CVPixelBuffer a un canale in Float32 (la maschera scalata di Vision).
    static func leggiMaschera(_ buffer: CVPixelBuffer) -> (valori: [Float], larghezza: Int, altezza: Int) {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let larghezza = CVPixelBufferGetWidth(buffer)
        let altezza = CVPixelBufferGetHeight(buffer)
        let perRiga = CVPixelBufferGetBytesPerRow(buffer)
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return ([], 0, 0) }
        var valori = [Float](repeating: 0, count: larghezza * altezza)
        for y in 0..<altezza {
            let riga = base.advanced(by: y * perRiga).assumingMemoryBound(to: Float.self)
            for x in 0..<larghezza {
                valori[y * larghezza + x] = riga[x]
            }
        }
        return (valori, larghezza, altezza)
    }

    /// Converte una maschera 0...1 in un'immagine in scala di grigi.
    static func immagineGrigia(_ valori: [Float], larghezza: Int, altezza: Int) -> CGImage? {
        let byte = valori.map { UInt8(max(0, min(255, ($0 * 255).rounded()))) }
        guard let provider = CGDataProvider(data: Data(byte) as CFData) else { return nil }
        return CGImage(
            width: larghezza,
            height: altezza,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: larghezza,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    }
}
