import Foundation
import SwiftData

/// Una combinazione di capi. Gli outfit si riferiscono ai capi, non ne copiano le foto:
/// eliminando un capo, sparisce anche dagli outfit che lo contengono.
@Model
final class Outfit {
    var id: UUID = UUID()
    var nome: String = ""
    var capi: [Capo]? = []
    var preferito: Bool = false
    var creatoIl: Date = Date()

    init(nome: String = "", capi: [Capo]) {
        self.nome = nome
        self.capi = capi
    }

    /// Capi ordinati per categoria (top, capispalla, ... accessori), per una visualizzazione coerente.
    var capiOrdinati: [Capo] {
        let ordine = Categoria.allCases
        return (capi ?? []).sorted {
            (ordine.firstIndex(of: $0.categoria) ?? 0) < (ordine.firstIndex(of: $1.categoria) ?? 0)
        }
    }

    var titolo: String {
        nome.isEmpty ? "Outfit" : nome
    }
}
