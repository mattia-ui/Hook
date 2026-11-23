import Foundation
import SwiftData

/// Un capo dell'armadio.
///
/// Tutte le proprietà hanno un valore di default e le relazioni sono opzionali
/// così il modello resta compatibile con una futura sincronizzazione iCloud (CloudKit).
@Model
final class Capo {
    var id: UUID = UUID()
    var nome: String = ""
    var categoriaRaw: String = Categoria.top.rawValue
    /// Foto a risoluzione ridotta (lato lungo max 1600 px).
    @Attribute(.externalStorage) var foto: Data?
    /// Foto originale prima dello scontorno, per poterla ripristinare. Vuota se non è stato fatto lo scontorno.
    @Attribute(.externalStorage) var fotoOriginale: Data?
    /// Miniatura per griglie e caroselli (lato lungo max 400 px).
    @Attribute(.externalStorage) var miniatura: Data?
    var coloreHex: String?
    var tag: [String] = []
    var preferito: Bool = false
    var creatoIl: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Outfit.capi)
    var outfit: [Outfit]? = []

    var categoria: Categoria {
        get { Categoria(rawValue: categoriaRaw) ?? .top }
        set { categoriaRaw = newValue.rawValue }
    }

    init(
        nome: String = "",
        categoria: Categoria,
        foto: Data?,
        miniatura: Data?,
        fotoOriginale: Data? = nil,
        coloreHex: String? = nil
    ) {
        self.nome = nome
        self.categoriaRaw = categoria.rawValue
        self.foto = foto
        self.miniatura = miniatura
        self.fotoOriginale = fotoOriginale
        self.coloreHex = coloreHex
    }

    /// Nome del colore principale, calcolato dal codice esadecimale salvato.
    var nomeColore: String? {
        guard let coloreHex, coloreHex.count == 7,
              let valore = Int(coloreHex.dropFirst(), radix: 16) else { return nil }
        return ColoreDominante.nome(r: (valore >> 16) & 0xFF, g: (valore >> 8) & 0xFF, b: valore & 0xFF)
    }

    /// Nome da mostrare: quello scelto dall'utente o, se vuoto, la categoria.
    var titolo: String {
        nome.isEmpty ? categoria.nome : nome
    }
}
