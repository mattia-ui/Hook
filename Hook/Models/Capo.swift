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

    init(nome: String = "", categoria: Categoria, foto: Data?, miniatura: Data?) {
        self.nome = nome
        self.categoriaRaw = categoria.rawValue
        self.foto = foto
        self.miniatura = miniatura
    }

    /// Nome da mostrare: quello scelto dall'utente o, se vuoto, la categoria.
    var titolo: String {
        nome.isEmpty ? categoria.nome : nome
    }
}
