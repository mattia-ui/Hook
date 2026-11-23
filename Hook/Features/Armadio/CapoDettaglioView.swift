import SwiftUI
import SwiftData

/// Dettaglio di un capo: foto grande, modifica di nome e categoria, condivisione ed eliminazione.
struct CapoDettaglioView: View {
    @Bindable var capo: Capo
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var confermaEliminazione = false
    @State private var inElaborazione = false
    @State private var errore: String?

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
                if let nomeColore = capo.nomeColore, let hex = capo.coloreHex {
                    HStack {
                        Text("Colore")
                        Spacer()
                        Circle()
                            .fill(Color(uiColor: UIColor(hex: hex) ?? .gray))
                            .frame(width: 18, height: 18)
                            .overlay(Circle().strokeBorder(.quaternary))
                        Text(nomeColore)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                if capo.fotoOriginale != nil {
                    Button {
                        ripristinaOriginale()
                    } label: {
                        Label("Ripristina la foto originale", systemImage: "arrow.uturn.backward")
                    }
                } else {
                    Button {
                        Task { await rimuoviSfondo() }
                    } label: {
                        HStack {
                            Label("Rimuovi sfondo", systemImage: "scissors")
                            if inElaborazione {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(inElaborazione || capo.foto == nil)
                }
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
        .alert("Qualcosa è andato storto",
               isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errore ?? "")
        }
    }

    private func rimuoviSfondo() async {
        guard let dati = capo.foto, let foto = UIImage(data: dati) else { return }
        inElaborazione = true
        defer { inElaborazione = false }
        do {
            let risultato = try await Task.detached(priority: .userInitiated) {
                let ritaglio = try Scontorno.ritaglia(foto)
                return (try ImageProcessing.prepara(ritaglio, trasparente: true), ColoreDominante.calcola(ritaglio))
            }.value
            withAnimation {
                capo.fotoOriginale = dati
                capo.foto = risultato.0.foto
                capo.miniatura = risultato.0.miniatura
                capo.coloreHex = risultato.1?.hex ?? capo.coloreHex
            }
        } catch {
            errore = "Non sono riuscito a isolare il capo in questa foto. Prova con una foto su uno sfondo più uniforme."
        }
    }

    private func ripristinaOriginale() {
        guard let dati = capo.fotoOriginale, let foto = UIImage(data: dati),
              let risultato = try? ImageProcessing.prepara(foto) else { return }
        withAnimation {
            capo.foto = risultato.foto
            capo.miniatura = risultato.miniatura
            capo.fotoOriginale = nil
        }
    }
}
