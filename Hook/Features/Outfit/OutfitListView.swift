import SwiftUI
import SwiftData

/// Galleria degli outfit salvati.
struct OutfitListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Outfit.creatoIl, order: .reverse) private var outfit: [Outfit]
    @Query private var capi: [Capo]
    @State private var mostraNuovo = false

    private let colonne = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            Group {
                if outfit.isEmpty {
                    ContentUnavailableView {
                        Label("Nessun outfit", systemImage: "rectangle.stack")
                    } description: {
                        Text(capi.isEmpty
                             ? "Aggiungi prima qualche capo all'armadio."
                             : "Combina i tuoi capi e salva i look che ti piacciono.")
                    } actions: {
                        if !capi.isEmpty {
                            Button("Crea un outfit") { mostraNuovo = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: colonne, spacing: 12) {
                            ForEach(outfit) { elemento in
                                OutfitCard(outfit: elemento)
                                    .contextMenu {
                                        Button {
                                            elemento.preferito.toggle()
                                        } label: {
                                            Label(elemento.preferito ? "Togli dai preferiti" : "Aggiungi ai preferiti",
                                                  systemImage: elemento.preferito ? "heart.slash" : "heart")
                                        }
                                        Button(role: .destructive) {
                                            context.delete(elemento)
                                        } label: {
                                            Label("Elimina outfit", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Outfit")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        mostraNuovo = true
                    } label: {
                        Label("Nuovo outfit", systemImage: "plus")
                    }
                    .disabled(capi.isEmpty)
                }
            }
            .sheet(isPresented: $mostraNuovo) {
                NuovoOutfitView()
            }
        }
    }
}

/// "Cartolina" di un outfit: i capi impilati su sfondo neutro.
struct OutfitCard: View {
    let outfit: Outfit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let capi = Array(outfit.capiOrdinati.prefix(4))
            VStack(spacing: 4) {
                ForEach(capi) { capo in
                    CapoThumbnail(capo: capo, cornerRadius: 10)
                        .frame(height: capi.count > 2 ? 64 : 96)
                }
                if capi.isEmpty {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.tertiarySystemFill))
                        .frame(height: 96)
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack {
                Text(outfit.titolo)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                if outfit.preferito {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OutfitListView()
        .modelContainer(PreviewData.container)
}
