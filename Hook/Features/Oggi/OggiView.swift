import SwiftUI
import SwiftData

/// Schermata "Oggi": meteo del posto in cui sei e un outfit suggerito con i tuoi capi.
struct OggiView: View {
    @Environment(\.modelContext) private var context
    @Query private var capi: [Capo]

    @State private var posizione = Posizione()
    @State private var stato: StatoMeteo = .caricamento
    @State private var rimescolamenti: UInt64 = 0
    @State private var salvato = false

    enum StatoMeteo: Equatable {
        case caricamento
        case pronto(Meteo)
        case permessoNegato
        case errore
    }

    private var meteo: Meteo? {
        if case .pronto(let meteo) = stato { return meteo }
        return nil
    }

    private var suggeriti: [Capo] {
        SuggerimentoOutfit.suggerisci(
            capi: capi,
            meteo: meteo,
            seme: SuggerimentoOutfit.semeDelGiorno() &+ rimescolamenti
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    schedaMeteo
                    schedaOutfit
                }
                .padding()
            }
            .navigationTitle("Oggi")
            .refreshable { await caricaMeteo() }
            .task { await caricaMeteo() }
            .sensoryFeedback(.success, trigger: salvato)
        }
    }

    // MARK: - Meteo

    @ViewBuilder
    private var schedaMeteo: some View {
        Group {
            switch stato {
            case .caricamento:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Controllo il meteo…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 110)
            case .pronto(let meteo):
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 16) {
                        Image(systemName: meteo.simbolo)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 48))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(meteo.temperatura.rounded()))°")
                                .font(.system(size: 44, weight: .semibold, design: .rounded))
                            Text(meteo.descrizione)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("\(Int(meteo.massima.rounded()))°", systemImage: "arrow.up")
                            Label("\(Int(meteo.minima.rounded()))°", systemImage: "arrow.down")
                            Label("\(meteo.probabilitaPioggia)%", systemImage: "drop")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                    }
                    Text(meteo.consiglio)
                        .font(.subheadline.weight(.medium))
                }
                .accessibilityElement(children: .combine)
            case .permessoNegato:
                avviso(
                    titolo: "Posizione non disponibile",
                    testo: "Per il meteo serve la posizione approssimativa. Puoi attivarla in Impostazioni.",
                    azione: "Apri Impostazioni"
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            case .errore:
                avviso(
                    titolo: "Meteo non disponibile",
                    testo: "Controlla la connessione e riprova.",
                    azione: "Riprova"
                ) {
                    Task { await caricaMeteo() }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func avviso(titolo: String, testo: String, azione: String, esegui: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(titolo, systemImage: "location.slash")
                .font(.headline)
            Text(testo)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(azione, action: esegui)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Outfit

    @ViewBuilder
    private var schedaOutfit: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cosa mettere oggi")
                .font(.title3.weight(.semibold))

            let capiSuggeriti = suggeriti
            if capiSuggeriti.isEmpty {
                ContentUnavailableView {
                    Label("Ancora pochi capi", systemImage: "hanger")
                } description: {
                    Text("Aggiungi almeno una maglia e un paio di pantaloni, oppure un vestito, e qui troverai l'outfit del giorno.")
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(capiSuggeriti) { capo in
                        VStack(alignment: .leading, spacing: 4) {
                            CapoThumbnail(capo: capo)
                                .aspectRatio(3 / 4, contentMode: .fit)
                            Text(capo.titolo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .animation(.snappy, value: rimescolamenti)

                HStack(spacing: 12) {
                    Button {
                        rimescolamenti &+= 1
                        salvato = false
                    } label: {
                        Label("Rimescola", systemImage: "shuffle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        salva(capiSuggeriti)
                    } label: {
                        Label(salvato ? "Salvato" : "Salva outfit", systemImage: salvato ? "checkmark" : "heart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(salvato)
                }

                if meteo != nil {
                    Link("Dati meteo: Open-Meteo.com", destination: URL(string: "https://open-meteo.com/")!)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    // MARK: - Azioni

    private func caricaMeteo() async {
        if meteo == nil { stato = .caricamento }
        do {
            let coordinate = try await posizione.attuale()
            let nuovo = try await MeteoService.carica(
                latitudine: coordinate.latitudine,
                longitudine: coordinate.longitudine
            )
            withAnimation { stato = .pronto(nuovo) }
        } catch Posizione.Errore.permessoNegato {
            stato = .permessoNegato
        } catch {
            if meteo == nil { stato = .errore }
        }
    }

    private func salva(_ capi: [Capo]) {
        let nome = "Look del " + Date.now.formatted(.dateTime.day().month(.wide))
        context.insert(Outfit(nome: nome, capi: capi))
        salvato = true
    }
}

#Preview {
    OggiView()
        .modelContainer(PreviewData.container)
}
