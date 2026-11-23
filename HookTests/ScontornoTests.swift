import Testing
import UIKit
@testable import Hook

struct MascheraTests {
    @Test func tieneIlCapoAlCentroEScartaGliOggettiAiMargini() {
        // 10x10: oggetto 1 grande al centro, oggetto 2 piccolo nell'angolo.
        var etichette = [UInt8](repeating: 0, count: 100)
        for y in 3..<8 { for x in 3..<8 { etichette[y * 10 + x] = 1 } }
        etichette[0] = 2
        etichette[1] = 2
        let tenute = Maschera.istanzePrincipali(
            etichette: etichette, larghezza: 10, altezza: 10, candidate: IndexSet([1, 2])
        )
        #expect(tenute == IndexSet(integer: 1))
    }

    @Test func tieneEntrambeLeScarpeDiUnPaio() {
        // Due oggetti di dimensione simile: si tengono entrambi.
        var etichette = [UInt8](repeating: 0, count: 100)
        for y in 4..<7 {
            for x in 1..<4 { etichette[y * 10 + x] = 1 }
            for x in 6..<9 { etichette[y * 10 + x] = 2 }
        }
        let tenute = Maschera.istanzePrincipali(
            etichette: etichette, larghezza: 10, altezza: 10, candidate: IndexSet([1, 2])
        )
        #expect(tenute == IndexSet([1, 2]))
    }

    @Test func preferisceIlCentroAUnOggettoUnPoPiuGrandeAiMargini() {
        // Oggetto 1: 16 pixel al centro. Oggetto 2: 20 pixel lungo il bordo sinistro.
        var etichette = [UInt8](repeating: 0, count: 400)
        for y in 8..<12 { for x in 8..<12 { etichette[y * 20 + x] = 1 } }
        for y in 0..<20 { etichette[y * 20] = 2 }
        let tenute = Maschera.istanzePrincipali(
            etichette: etichette, larghezza: 20, altezza: 20, candidate: IndexSet([1, 2]), sogliaRelativa: 1.5
        )
        #expect(tenute == IndexSet(integer: 1))
    }

    @Test func rimuoveLeIsoleDiSfondo() {
        // Isola grande 5x5 e un frammento di 2 pixel lontano.
        var valori = [Float](repeating: 0, count: 100)
        for y in 2..<7 { for x in 2..<7 { valori[y * 10 + x] = 1 } }
        valori[9 * 10 + 9] = 1
        valori[9 * 10 + 8] = 0.9
        let tenute = Maschera.rimuoviIsole(&valori, larghezza: 10, altezza: 10)
        #expect(tenute == 1)
        #expect(valori[9 * 10 + 9] == 0)
        #expect(valori[9 * 10 + 8] == 0)
        #expect(valori[4 * 10 + 4] == 1)
    }

    @Test func leIsoleDiagonaliNonSonoCollegate() {
        // Collegamento solo in diagonale: sono due isole distinte (vicinato a 4).
        var valori: [Float] = [
            1, 0, 0,
            0, 1, 0,
            0, 0, 0,
        ]
        let tenute = Maschera.rimuoviIsole(&valori, larghezza: 3, altezza: 3, sogliaRelativa: 1)
        #expect(tenute == 2)
    }

    @Test func rettangoloDeiPixelVisibili() throws {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        let immagine = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 80), format: formato).image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 10, y: 20, width: 30, height: 40))
        }
        let cg = try #require(immagine.cgImage)
        let rettangolo = try #require(Maschera.rettangoloOpaco(cg))
        #expect(rettangolo == CGRect(x: 10, y: 20, width: 30, height: 40))
    }

    @Test func ritagliaAiBordiConMargine() throws {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        let immagine = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400), format: formato).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 100, y: 100, width: 100, height: 200))
        }
        let ritagliata = try #require(ImageProcessing.ritagliaAiBordi(immagine))
        // 200 px di lato lungo, margine del 3% = 6 px per lato.
        #expect(ritagliata.size == CGSize(width: 112, height: 212))
    }

    @Test func immagineVuotaNonSiRitaglia() {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        let vuota = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50), format: formato).image { _ in }
        #expect(ImageProcessing.ritagliaAiBordi(vuota) == nil)
    }
}

struct PennelloTests {
    private func pieno(_ colore: UIColor, lato: CGFloat = 100) -> UIImage {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: lato, height: lato), format: formato).image { ctx in
            colore.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: lato, height: lato))
        }
    }

    private func vuoto(lato: CGFloat = 100) -> UIImage {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: lato, height: lato), format: formato).image { _ in }
    }

    private func alpha(_ immagine: UIImage, x: Int, y: Int) -> UInt8 {
        guard let cg = immagine.cgImage else { return 0 }
        var pixel = [UInt8](repeating: 0, count: 4)
        pixel.withUnsafeMutableBytes { buffer in
            let contesto = CGContext(
                data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
            // Sposta l'immagine così che il pixel (x, y) dall'alto finisca nell'unico pixel del contesto.
            contesto?.draw(cg, in: CGRect(x: -x, y: -(cg.height - 1 - y), width: cg.width, height: cg.height))
        }
        return pixel[3]
    }

    @Test func laGommaRendeTrasparente() {
        let risultato = Pennello.applica(
            tratto: [CGPoint(x: 10, y: 50), CGPoint(x: 90, y: 50)],
            spessore: 20, modalita: .gomma, a: pieno(.green), originale: pieno(.green)
        )
        #expect(alpha(risultato, x: 50, y: 50) == 0)
        #expect(alpha(risultato, x: 50, y: 10) == 255)
    }

    @Test func ilRipristinoRiportaLOriginale() {
        let risultato = Pennello.applica(
            tratto: [CGPoint(x: 50, y: 50)],
            spessore: 20, modalita: .ripristina, a: vuoto(), originale: pieno(.green)
        )
        #expect(alpha(risultato, x: 50, y: 50) == 255)
        #expect(alpha(risultato, x: 5, y: 5) == 0)
    }

    @Test func conversioneDelPuntoToccato() {
        let riquadro = Pennello.riquadroAdattato(
            dimensioneImmagine: CGSize(width: 1000, height: 2000), in: CGSize(width: 300, height: 300)
        )
        #expect(riquadro == CGRect(x: 75, y: 0, width: 150, height: 300))
        let punto = Pennello.puntoImmagine(
            CGPoint(x: 150, y: 150), riquadro: riquadro, dimensioneImmagine: CGSize(width: 1000, height: 2000)
        )
        #expect(punto == CGPoint(x: 500, y: 1000))
    }
}
