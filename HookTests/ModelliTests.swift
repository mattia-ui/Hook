import Testing
import SwiftData
import UIKit
@testable import Hook

@MainActor
struct ModelliTests {
    private func contenitore() throws -> ModelContainer {
        try ModelContainer(
            for: Capo.self, Outfit.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func categoriaSalvataComeStringa() {
        let capo = Capo(categoria: .scarpe, foto: nil, miniatura: nil)
        #expect(capo.categoriaRaw == "scarpe")
        capo.categoria = .borse
        #expect(capo.categoriaRaw == "borse")
    }

    @Test func categoriaSconosciutaDiventaTop() {
        let capo = Capo(categoria: .top, foto: nil, miniatura: nil)
        capo.categoriaRaw = "valore-vecchio"
        #expect(capo.categoria == .top)
    }

    @Test func titoloUsaLaCategoriaSeIlNomeEVuoto() {
        #expect(Capo(categoria: .gonne, foto: nil, miniatura: nil).titolo == "Gonne")
        #expect(Capo(nome: "Jeans", categoria: .pantaloni, foto: nil, miniatura: nil).titolo == "Jeans")
    }

    @Test func eliminareUnCapoLoTogliDagliOutfit() throws {
        let container = try contenitore()
        let context = container.mainContext
        let maglia = Capo(categoria: .top, foto: nil, miniatura: nil)
        let jeans = Capo(categoria: .pantaloni, foto: nil, miniatura: nil)
        context.insert(maglia)
        context.insert(jeans)
        let outfit = Outfit(capi: [maglia, jeans])
        context.insert(outfit)
        try context.save()

        context.delete(maglia)
        try context.save()

        let rimasti = try context.fetch(FetchDescriptor<Outfit>())
        #expect(rimasti.count == 1)
        #expect(rimasti.first?.capi?.count == 1)
        #expect(rimasti.first?.capi?.first?.categoria == .pantaloni)
    }

    @Test func capiOrdinatiSeguonoLeCategorie() {
        let scarpe = Capo(categoria: .scarpe, foto: nil, miniatura: nil)
        let top = Capo(categoria: .top, foto: nil, miniatura: nil)
        let pantaloni = Capo(categoria: .pantaloni, foto: nil, miniatura: nil)
        let outfit = Outfit(capi: [scarpe, top, pantaloni])
        #expect(outfit.capiOrdinati.map(\.categoria) == [.top, .pantaloni, .scarpe])
    }
}

struct ImageProcessingTests {
    private func immagine(larghezza: CGFloat, altezza: CGFloat) -> UIImage {
        let formato = UIGraphicsImageRendererFormat.default()
        formato.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: larghezza, height: altezza), format: formato).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: larghezza, height: altezza))
        }
    }

    @Test func ridimensionaMantenendoLeProporzioni() {
        let risultato = ImageProcessing.ridimensiona(immagine(larghezza: 4000, altezza: 3000), latoMassimo: 400)
        #expect(risultato.size.width == 400)
        #expect(risultato.size.height == 300)
    }

    @Test func nonIngrandisceLeImmaginiPiccole() {
        let risultato = ImageProcessing.ridimensiona(immagine(larghezza: 200, altezza: 100), latoMassimo: 400)
        #expect(risultato.size == CGSize(width: 200, height: 100))
    }

    @Test func preparaCreaFotoEMiniatura() throws {
        let risultato = try ImageProcessing.prepara(immagine(larghezza: 3000, altezza: 4000))
        let foto = try #require(UIImage(data: risultato.foto))
        let miniatura = try #require(UIImage(data: risultato.miniatura))
        #expect(max(foto.size.width, foto.size.height) == ImageProcessing.latoMassimoFoto)
        #expect(max(miniatura.size.width, miniatura.size.height) == ImageProcessing.latoMassimoMiniatura)
    }

    @Test func datiNonValidiLancianoErrore() {
        #expect(throws: ImageProcessing.Errore.self) {
            try ImageProcessing.prepara(Data("non è un'immagine".utf8))
        }
    }
}
