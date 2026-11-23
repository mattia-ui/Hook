import UIKit

/// Risultato dell'analisi automatica di una foto appena scelta.
struct AnalisiCapo: Sendable {
    /// Il capo su sfondo trasparente, se lo scontorno è riuscito.
    let ritaglio: UIImage?
    let categoriaSuggerita: Categoria?
    let colore: ColoreCapo?
}

enum AnalisiService {
    /// Scontorno, categoria e colore in un passaggio. Da chiamare fuori dal main thread.
    static func analizza(_ immagine: UIImage) -> AnalisiCapo {
        let ritaglio = try? Scontorno.ritaglia(immagine)
        let base = ritaglio ?? immagine
        return AnalisiCapo(
            ritaglio: ritaglio,
            categoriaSuggerita: RiconoscimentoCategoria.suggerisci(per: base),
            colore: ColoreDominante.calcola(base)
        )
    }
}
