import SwiftUI

/// Riga di chip per filtrare per categoria. `nil` significa "Tutti".
struct FiltroCategorie: View {
    @Binding var selezione: Categoria?
    var categorie: [Categoria] = Categoria.allCases

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(titolo: "Tutti", attivo: selezione == nil) { selezione = nil }
                ForEach(categorie) { categoria in
                    chip(titolo: categoria.nome, attivo: selezione == categoria) {
                        selezione = selezione == categoria ? nil : categoria
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func chip(titolo: String, attivo: Bool, azione: @escaping () -> Void) -> some View {
        Button(action: azione) {
            Text(titolo)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(attivo ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                .foregroundStyle(attivo ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(attivo ? .isSelected : [])
    }
}
