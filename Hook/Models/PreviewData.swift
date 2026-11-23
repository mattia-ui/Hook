import SwiftData
import UIKit

/// Dati finti per le anteprime di Xcode.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: Capo.self, Outfit.self, configurations: config)
        let colori: [(Categoria, UIColor)] = [
            (.top, .systemTeal), (.top, .systemPink), (.pantaloni, .systemIndigo),
            (.scarpe, .brown), (.capispalla, .darkGray), (.accessori, .systemYellow),
        ]
        var capi: [Capo] = []
        for (categoria, colore) in colori {
            let immagine = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 360)).image { ctx in
                colore.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 360))
            }
            let dati = immagine.jpegData(compressionQuality: 0.8)
            let capo = Capo(categoria: categoria, foto: dati, miniatura: dati)
            container.mainContext.insert(capo)
            capi.append(capo)
        }
        container.mainContext.insert(Outfit(nome: "Ufficio", capi: [capi[0], capi[2], capi[3]]))
        return container
    }()
}
