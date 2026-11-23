import Testing
import UIKit
@testable import Hook

struct ColoreDominanteTests {
    private func tinta(_ colore: UIColor, larghezza: CGFloat = 60, altezza: CGFloat = 60) -> UIImage {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: larghezza, height: altezza), format: formato).image { ctx in
            colore.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: larghezza, height: altezza))
        }
    }

    @Test(arguments: [
        (255, 0, 0, "Rosso"),
        (255, 255, 255, "Bianco"),
        (10, 10, 10, "Nero"),
        (128, 128, 128, "Grigio"),
        (20, 30, 140, "Blu"),
        (30, 140, 60, "Verde"),
        (240, 220, 40, "Giallo"),
        (110, 60, 30, "Marrone"),
        (225, 205, 170, "Beige"),
        (240, 130, 180, "Rosa"),
    ])
    func nomiDeiColori(r: Int, g: Int, b: Int, atteso: String) {
        #expect(ColoreDominante.nome(r: r, g: g, b: b) == atteso)
    }

    @Test func coloreDiUnImmagineTinta() throws {
        let colore = try #require(ColoreDominante.calcola(tinta(.red)))
        #expect(colore.nome == "Rosso")
        #expect(colore.hex.hasPrefix("#") && colore.hex.count == 7)
    }

    @Test func ignoraIPixelTrasparenti() throws {
        // Metà blu e metà trasparente: lo sfondo del ritaglio non deve contare.
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        let immagine = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 60), format: formato).image { ctx in
            UIColor(red: 0.1, green: 0.15, blue: 0.6, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 20, height: 60))
        }
        let colore = try #require(ColoreDominante.calcola(immagine))
        #expect(colore.nome == "Blu")
    }

    @Test func immagineTuttaTrasparenteNonHaColore() {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        let vuota = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20), format: formato).image { _ in }
        #expect(ColoreDominante.calcola(vuota) == nil)
    }

    @Test func esadecimaleInUIColor() throws {
        let colore = try #require(UIColor(hex: "#336699"))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        colore.getRed(&r, green: &g, blue: &b, alpha: nil)
        #expect(Int((r * 255).rounded()) == 0x33)
        #expect(Int((g * 255).rounded()) == 0x66)
        #expect(Int((b * 255).rounded()) == 0x99)
        #expect(UIColor(hex: "blu") == nil)
    }

    @Test func nomeColoreDelCapo() {
        let capo = Capo(categoria: .top, foto: nil, miniatura: nil, coloreHex: "#FF0000")
        #expect(capo.nomeColore == "Rosso")
        #expect(Capo(categoria: .top, foto: nil, miniatura: nil).nomeColore == nil)
    }
}

struct RiconoscimentoCategoriaTests {
    @Test(arguments: [
        ("sneaker", Categoria.scarpe),
        ("shoes", .scarpe),
        ("jeans", .pantaloni),
        ("t_shirt", .top),
        ("dress_shirt", .top),
        ("dress", .vestiti),
        ("handbag", .borse),
        ("jacket", .capispalla),
        ("sunglasses", .accessori),
        ("skirt", .gonne),
    ])
    func etichetteNote(identificatore: String, attesa: Categoria) {
        #expect(RiconoscimentoCategoria.categoria(per: identificatore) == attesa)
    }

    @Test func paroleSimiliMaDiverseNonVengonoConfuse() {
        // "cap" dentro "landscape" o "tie" dentro "patient" non devono contare.
        #expect(RiconoscimentoCategoria.categoria(per: "landscape") == nil)
        #expect(RiconoscimentoCategoria.categoria(per: "laptop") == nil)
        #expect(RiconoscimentoCategoria.categoria(per: "patient") == nil)
    }

    @Test func sommaLeConfidenzePerCategoria() {
        let etichette: [(String, Float)] = [("dress", 0.3), ("jeans", 0.2), ("denim", 0.2), ("clothing", 0.9)]
        #expect(RiconoscimentoCategoria.categoria(da: etichette) == .pantaloni)
    }

    @Test func confidenzaTroppoBassaNonSuggerisceNulla() {
        let etichette: [(String, Float)] = [("sneaker", 0.05), ("outdoor", 0.8)]
        #expect(RiconoscimentoCategoria.categoria(da: etichette) == nil)
    }
}

struct PreparazioneTrasparenteTests {
    @Test func ilRitaglioConservaLaTrasparenza() throws {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        formato.opaque = false
        let ritaglio = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 1000), format: formato).image { ctx in
            UIColor.green.setFill()
            ctx.fill(CGRect(x: 500, y: 0, width: 1000, height: 1000))
        }
        let risultato = try ImageProcessing.prepara(ritaglio, trasparente: true)
        let foto = try #require(UIImage(data: risultato.foto)?.cgImage)
        #expect(max(foto.width, foto.height) == Int(ImageProcessing.latoMassimoRitaglio))
        let alpha = foto.alphaInfo
        #expect(alpha != .none && alpha != .noneSkipLast && alpha != .noneSkipFirst)
    }
}
