import SwiftUI
import SwiftData

/// Schermata principale: tutti i capi in griglia, con filtro per categoria.
struct ArmadioView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Capo.creatoIl, order: .reverse) private var capi: [Capo]

    @State private var filtro: Categoria?
    @State private var mostraAggiunta = false
    @State private var daEliminare: Capo?

    private let colonne = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    private var capiFiltrati: [Capo] {
        guard let filtro else { return capi }
        return capi.filter { $0.categoria == filtro }
    }

    var body: some View {
        NavigationStack {
            Group {
                if capi.isEmpty {
                    statoVuoto
                } else {
                    ScrollView {
                        FiltroCategorie(selezione: $filtro)
                            .padding(.vertical, 8)
                        if capiFiltrati.isEmpty {
                            ContentUnavailableView(
                                "Nessun capo in questa categoria",
                                systemImage: filtro?.simbolo ?? "hanger"
                            )
                            .padding(.top, 40)
                        } else {
                            griglia
                        }
                    }
                }
            }
            .navigationTitle("Armadio")
            .navigationDestination(for: Capo.self) { capo in
                CapoDettaglioView(capo: capo)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        mostraAggiunta = true
                    } label: {
                        Label("Aggiungi capo", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $mostraAggiunta) {
                AggiungiCapoView()
            }
            .confirmationDialog(
                "Eliminare questo capo?",
                isPresented: Binding(get: { daEliminare != nil }, set: { if !$0 { daEliminare = nil } }),
                titleVisibility: .visible,
                presenting: daEliminare
            ) { capo in
                Button("Elimina", role: .destructive) {
                    context.delete(capo)
                }
            } message: { _ in
                Text("Verrà tolto anche dagli outfit che lo contengono.")
            }
        }
    }

    private var griglia: some View {
        LazyVGrid(columns: colonne, spacing: 12) {
            ForEach(capiFiltrati) { capo in
                NavigationLink(value: capo) {
                    CapoThumbnail(capo: capo)
                        .aspectRatio(3 / 4, contentMode: .fit)
                        .overlay(alignment: .topTrailing) {
                            if capo.preferito {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(.black.opacity(0.35), in: Circle())
                                    .padding(6)
                            }
                        }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        capo.preferito.toggle()
                    } label: {
                        Label(capo.preferito ? "Togli dai preferiti" : "Aggiungi ai preferiti",
                              systemImage: capo.preferito ? "heart.slash" : "heart")
                    }
                    Button(role: .destructive) {
                        daEliminare = capo
                    } label: {
                        Label("Elimina", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    private var statoVuoto: some View {
        ContentUnavailableView {
            Label("Il tuo armadio è vuoto", systemImage: "hanger")
        } description: {
            Text("Fotografa i tuoi capi per iniziare a creare outfit.")
        } actions: {
            Button("Aggiungi il primo capo") { mostraAggiunta = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ArmadioView()
        .modelContainer(PreviewData.container)
}
