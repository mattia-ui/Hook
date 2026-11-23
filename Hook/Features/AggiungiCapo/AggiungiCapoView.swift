import SwiftUI
import SwiftData
import PhotosUI

/// Foglio per aggiungere un capo: foto da libreria o fotocamera, poi scontorno,
/// categoria e colore proposti in automatico. L'utente conferma o corregge.
struct AggiungiCapoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selezioneFoto: PhotosPickerItem?
    @State private var originale: UIImage?
    @State private var analisi: AnalisiCapo?
    @State private var usaRitaglio = true
    /// Ritocco a mano: lo scontorno a piena dimensione e la sua versione ritagliata.
    @State private var scontornoRitoccato: UIImage?
    @State private var ritaglioRitoccato: UIImage?
    @State private var mostraRitocco = false
    @State private var categoria: Categoria = .top
    @State private var nome = ""
    @State private var mostraFotocamera = false
    @State private var inAnalisi = false
    @State private var inSalvataggio = false
    @State private var errore: String?

    private let fotocameraDisponibile = UIImagePickerController.isSourceTypeAvailable(.camera)

    /// L'immagine che verrà salvata: il ritaglio se disponibile e scelto, altrimenti l'originale.
    private var immagineFinale: UIImage? {
        if usaRitaglio, let ritaglio = ritaglioRitoccato ?? analisi?.ritaglio { return ritaglio }
        return originale
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    anteprima
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    sorgenti
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                if let analisi, originale != nil {
                    Section {
                        if analisi.ritaglio != nil {
                            Toggle(isOn: $usaRitaglio.animation()) {
                                Label("Rimuovi sfondo", systemImage: "scissors")
                            }
                            if usaRitaglio, analisi.scontorno != nil {
                                Button {
                                    mostraRitocco = true
                                } label: {
                                    Label("Ritocca a mano", systemImage: "eraser")
                                }
                            }
                        } else {
                            Label("Sfondo non rimosso: il capo non è stato isolato in questa foto.",
                                  systemImage: "exclamationmark.triangle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        if let colore = analisi.colore {
                            HStack {
                                Label("Colore", systemImage: "paintpalette")
                                Spacer()
                                Circle()
                                    .fill(Color(uiColor: UIColor(hex: colore.hex) ?? .gray))
                                    .frame(width: 18, height: 18)
                                    .overlay(Circle().strokeBorder(.quaternary))
                                Text(colore.nome)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section {
                    grigliaCategorie
                } header: {
                    Text("Categoria")
                } footer: {
                    if let suggerita = analisi?.categoriaSuggerita {
                        Label("Suggerita in automatico: \(suggerita.nome). Tocca per cambiarla.",
                              systemImage: "sparkles")
                    }
                }

                Section("Nome") {
                    TextField("Facoltativo, es. Camicia bianca", text: $nome)
                }
            }
            .navigationTitle("Nuovo capo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        Task { await salva() }
                    }
                    .disabled(originale == nil || inAnalisi || inSalvataggio)
                }
            }
            .onChange(of: selezioneFoto) { _, nuovo in
                guard let nuovo else { return }
                Task { await carica(nuovo) }
            }
            .fullScreenCover(isPresented: $mostraRitocco) {
                if let scontorno = analisi?.scontorno {
                    RitoccoView(
                        ritaglio: scontornoRitoccato ?? scontorno.ritaglio,
                        originale: scontorno.originale
                    ) { nuovo in
                        if let ritagliato = ImageProcessing.ritagliaAiBordi(nuovo) {
                            scontornoRitoccato = nuovo
                            ritaglioRitoccato = ritagliato
                        } else {
                            errore = "Hai cancellato tutto il capo: tengo il ritaglio di prima."
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $mostraFotocamera) {
                CameraPicker { foto in
                    Task { await analizza(foto) }
                }
                .ignoresSafeArea()
            }
            .alert("Qualcosa è andato storto",
                   isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errore ?? "")
            }
            .sensoryFeedback(.success, trigger: analisi?.ritaglio != nil)
        }
    }

    // MARK: - Viste

    private var anteprima: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
            if let immagineFinale {
                Image(uiImage: immagineFinale)
                    .resizable()
                    .scaledToFit()
                    .padding(usaRitaglio && analisi?.ritaglio != nil ? 24 : 8)
                    .shadow(color: .black.opacity(usaRitaglio && analisi?.ritaglio != nil ? 0.2 : 0), radius: 10, y: 6)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .id(usaRitaglio)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 44))
                    Text("Scegli o scatta una foto del capo")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            if inAnalisi {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Sto isolando il capo…")
                        .font(.footnote)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(height: 340)
    }

    private var sorgenti: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selezioneFoto, matching: .images) {
                Label("Libreria", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            if fotocameraDisponibile {
                Button {
                    mostraFotocamera = true
                } label: {
                    Label("Fotocamera", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .disabled(inAnalisi)
    }

    private var grigliaCategorie: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
            ForEach(Categoria.allCases) { valore in
                Button {
                    categoria = valore
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: valore.simbolo)
                            .font(.title3)
                        Text(valore.nome)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        categoria == valore ? Color.accentColor.opacity(0.18) : Color(.tertiarySystemFill),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .foregroundStyle(categoria == valore ? Color.accentColor : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(categoria == valore ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Azioni

    private func carica(_ elemento: PhotosPickerItem) async {
        do {
            guard let dati = try await elemento.loadTransferable(type: Data.self),
                  let foto = UIImage(data: dati) else {
                errore = "Non riesco ad aprire questa foto."
                return
            }
            await analizza(foto)
        } catch {
            errore = "Non riesco ad aprire questa foto."
        }
    }

    private func analizza(_ foto: UIImage) async {
        originale = foto
        analisi = nil
        usaRitaglio = true
        scontornoRitoccato = nil
        ritaglioRitoccato = nil
        inAnalisi = true
        let risultato = await Task.detached(priority: .userInitiated) {
            AnalisiService.analizza(foto)
        }.value
        // Se nel frattempo è stata scelta un'altra foto, questo risultato non serve più.
        guard originale === foto else { return }
        withAnimation {
            analisi = risultato
            if let suggerita = risultato.categoriaSuggerita {
                categoria = suggerita
            }
            inAnalisi = false
        }
    }

    private func salva() async {
        guard let originale, let immagineFinale else { return }
        inSalvataggio = true
        defer { inSalvataggio = false }
        let ritagliato = immagineFinale !== originale
        do {
            let (risultato, datiOriginale) = try await Task.detached(priority: .userInitiated) {
                let risultato = try ImageProcessing.prepara(immagineFinale, trasparente: ritagliato)
                return (risultato, ritagliato ? ImageProcessing.originale(originale) : nil)
            }.value
            let capo = Capo(
                nome: nome.trimmingCharacters(in: .whitespacesAndNewlines),
                categoria: categoria,
                foto: risultato.foto,
                miniatura: risultato.miniatura,
                fotoOriginale: datiOriginale,
                coloreHex: analisi?.colore?.hex
            )
            context.insert(capo)
            dismiss()
        } catch {
            errore = "Non sono riuscito a salvare il capo."
        }
    }
}

#Preview {
    AggiungiCapoView()
        .modelContainer(PreviewData.container)
}
