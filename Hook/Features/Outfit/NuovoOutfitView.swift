import SwiftUI
import SwiftData

/// Creazione di un outfit scegliendo i capi, divisi per categoria.
/// L'editor a tela libera arriverà nella fase dedicata al design.
struct NuovoOutfitView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Capo.creatoIl, order: .reverse) private var capi: [Capo]

    @State private var selezionati: Set<PersistentIdentifier> = []
    @State private var nome = ""

    private var categoriePresenti: [Categoria] {
        Categoria.allCases.filter { categoria in capi.contains { $0.categoria == categoria } }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TextField("Nome dell'outfit (facoltativo)", text: $nome)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    ForEach(categoriePresenti) { categoria in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(categoria.nome)
                                .font(.headline)
                                .padding(.horizontal)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 10) {
                                    ForEach(capi.filter { $0.categoria == categoria }) { capo in
                                        cella(capo)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Nuovo outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { salva() }
                        .disabled(selezionati.count < 2)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(selezionati.count < 2
                     ? "Scegli almeno due capi"
                     : "\(selezionati.count) capi selezionati")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.bar)
            }
        }
    }

    private func cella(_ capo: Capo) -> some View {
        let attivo = selezionati.contains(capo.persistentModelID)
        return Button {
            if attivo {
                selezionati.remove(capo.persistentModelID)
            } else {
                selezionati.insert(capo.persistentModelID)
            }
        } label: {
            CapoThumbnail(capo: capo, cornerRadius: 14)
                .frame(width: 104, height: 138)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(attivo ? Color.accentColor : .clear, lineWidth: 3)
                }
                .overlay(alignment: .topTrailing) {
                    if attivo {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.accentColor)
                            .font(.title3)
                            .padding(6)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(attivo ? .isSelected : [])
    }

    private func salva() {
        let scelti = capi.filter { selezionati.contains($0.persistentModelID) }
        let outfit = Outfit(nome: nome.trimmingCharacters(in: .whitespacesAndNewlines), capi: scelti)
        context.insert(outfit)
        dismiss()
    }
}

#Preview {
    NuovoOutfitView()
        .modelContainer(PreviewData.container)
}
