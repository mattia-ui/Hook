import SwiftUI
import SwiftData

/// Dettaglio di un capo: foto grande, modifica di nome e categoria, condivisione ed eliminazione.
struct CapoDettaglioView: View {
    @Bindable var capo: Capo
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confermaEliminazione = false

    private var immagine: UIImage? {
        capo.foto.flatMap(UIImage.init(data:))
    }

    var body: some View {
        Form {
            Section {
                Group {
                    if let immagine {
                        Image(uiImage: immagine)
                            .resizable()
                            .scaledToFit()
                    } else {
                        CapoThumbnail(capo: capo)
                            .aspectRatio(3 / 4, contentMode: .fit)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: 420)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Dettagli") {
                TextField("Nome (facoltativo)", text: $capo.nome)
                Picker("Categoria", selection: $capo.categoria) {
                    ForEach(Categoria.allCases) { categoria in
                        Label(categoria.nome, systemImage: categoria.simbolo).tag(categoria)
                    }
                }
                Toggle("Preferito", isOn: $capo.preferito)
            }

            if let numero = capo.outfit?.count, numero > 0 {
                Section {
                    Text(numero == 1 ? "Presente in 1 outfit" : "Presente in \(numero) outfit")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Elimina capo", role: .destructive) {
                    confermaEliminazione = true
                }
            }
        }
        .navigationTitle(capo.titolo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let immagine {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: Image(uiImage: immagine),
                        preview: SharePreview(capo.titolo, image: Image(uiImage: immagine))
                    )
                }
            }
        }
        .confirmationDialog("Eliminare questo capo?", isPresented: $confermaEliminazione, titleVisibility: .visible) {
            Button("Elimina", role: .destructive) {
                context.delete(capo)
                dismiss()
            }
        } message: {
            Text("Verrà tolto anche dagli outfit che lo contengono.")
        }
    }
}
