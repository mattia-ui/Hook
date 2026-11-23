import SwiftUI

/// Miniatura di un capo su sfondo neutro, usata in griglie e outfit.
struct CapoThumbnail: View {
    let capo: Capo
    var cornerRadius: CGFloat = 16

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
            if let dati = capo.miniatura, let immagine = UIImage(data: dati) {
                if capo.fotoOriginale != nil {
                    // Capo scontornato: intero e centrato, con un'ombra morbida.
                    Image(uiImage: immagine)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                } else {
                    Image(uiImage: immagine)
                        .resizable()
                        .scaledToFill()
                }
            } else {
                Image(systemName: capo.categoria.simbolo)
                    .font(.title)
                    .foregroundStyle(.secondary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .accessibilityLabel(capo.titolo)
    }
}
