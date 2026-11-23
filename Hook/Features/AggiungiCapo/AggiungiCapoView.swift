import SwiftUI
import SwiftData
import PhotosUI

/// Foglio per aggiungere un capo: foto da libreria o fotocamera, categoria, nome.
struct AggiungiCapoView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var selezioneFoto: PhotosPickerItem?
    @State private var immagine: UIImage?
    @State private var categoria: Categoria = .top
    @State private var nome = ""
    @State private var mostraFotocamera = false
    @State private var inCaricamento = false
    @State private var errore: String?

    private let fotocameraDisponibile = UIImagePickerController.isSourceTypeAvailable(.camera)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    anteprima
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
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
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section("Categoria") {
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
                    .disabled(immagine == nil || inCaricamento)
                }
            }
            .onChange(of: selezioneFoto) { _, nuovo in
                guard let nuovo else { return }
                Task { await carica(nuovo) }
            }
            .fullScreenCover(isPresented: $mostraFotocamera) {
                CameraPicker { foto in
                    immagine = foto
                }
                .ignoresSafeArea()
            }
            .alert("Qualcosa è andato storto", isPresented: Binding(get: { errore != nil }, set: { if !$0 { errore = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errore ?? "")
            }
        }
    }

    @ViewBuilder
    private var anteprima: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
            if let immagine {
                Image(uiImage: immagine)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 44))
                    Text("Scegli o scatta una foto del capo")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
            }
            if inCaricamento {
                ProgressView()
            }
        }
        .frame(height: 320)
    }

    private func carica(_ elemento: PhotosPickerItem) async {
        inCaricamento = true
        defer { inCaricamento = false }
        do {
            guard let dati = try await elemento.loadTransferable(type: Data.self),
                  let foto = UIImage(data: dati) else {
                errore = "Non riesco ad aprire questa foto."
                return
            }
            immagine = foto
        } catch {
            errore = "Non riesco ad aprire questa foto."
        }
    }

    private func salva() async {
        guard let immagine else { return }
        inCaricamento = true
        defer { inCaricamento = false }
        do {
            let risultato = try await Task.detached(priority: .userInitiated) {
                try ImageProcessing.prepara(immagine)
            }.value
            let capo = Capo(
                nome: nome.trimmingCharacters(in: .whitespacesAndNewlines),
                categoria: categoria,
                foto: risultato.foto,
                miniatura: risultato.miniatura
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
