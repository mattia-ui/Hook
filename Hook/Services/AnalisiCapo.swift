import UIKit

/// Risultato dell'analisi automatica di una foto appena scelta.
struct AnalisiCapo: Sendable {
    /// Scontorno a piena dimensione (per il ritocco), se è riuscito.
    let scontorno: RisultatoScontorno?
    /// Lo scontorno ritagliato attorno al capo, pronto da mostrare.
    let ritaglio: UIImage?
    let categoriaSuggerita: Categoria?
    let colore: ColoreCapo?
}

enum AnalisiService {
    /// Scontorno, categoria e colore in un passaggio. Da chiamare fuori dal main thread.
    static func analizza(_ immagine: UIImage) -> AnalisiCapo {
        let scontorno = try? Scontorno.scontorna(immagine)
        let ritaglio = scontorno.flatMap { ImageProcessing.ritagliaAiBordi($0.ritaglio) }
        let base = ritaglio ?? immagine
        return AnalisiCapo(
            scontorno: ritaglio == nil ? nil : scontorno,
            ritaglio: ritaglio,
            categoriaSuggerita: RiconoscimentoCategoria.suggerisci(per: base),
            colore: ColoreDominante.calcola(base)
        )
    }
}
