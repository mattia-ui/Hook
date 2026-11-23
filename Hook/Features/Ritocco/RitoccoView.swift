import SwiftUI

/// Ritocco a mano dello scontorno: gomma per togliere i pezzi di sfondo rimasti,
/// pennello per ripristinare parti del capo tagliate per errore.
struct RitoccoView: View {
    let originale: UIImage
    var onFine: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var corrente: UIImage
    @State private var storico: [UIImage] = []
    @State private var tratto: [CGPoint] = []
    @State private var modalita: Pennello.Modalita = .gomma
    @State private var spessoreSchermo: CGFloat = 28
    @State private var scalaImmagine: CGFloat = 1
    @State private var mostraOriginale = false

    private let massimoAnnullamenti = 15

    init(ritaglio: UIImage, originale: UIImage, onFine: @escaping (UIImage) -> Void) {
        self.originale = originale
        self.onFine = onFine
        _corrente = State(initialValue: ritaglio)
    }

    /// Lo spessore del pennello in pixel dell'immagine, a parità di dimensione sullo schermo.
    private var spessoreImmagine: CGFloat {
        spessoreSchermo * scalaImmagine
    }

    private var anteprima: UIImage {
        guard !tratto.isEmpty else { return corrente }
        return Pennello.applica(
            tratto: tratto,
            spessore: spessoreImmagine,
            modalita: modalita,
            a: corrente,
            originale: originale
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                GeometryReader { geometria in
                    let riquadro = Pennello.riquadroAdattato(dimensioneImmagine: corrente.size, in: geometria.size)
                    ZStack(alignment: .topLeading) {
                        Scacchiera()
                            .frame(width: riquadro.width, height: riquadro.height)
                            .offset(x: riquadro.minX, y: riquadro.minY)
                        Image(uiImage: mostraOriginale ? originale : anteprima)
                            .resizable()
                            .interpolation(.medium)
                            .frame(width: riquadro.width, height: riquadro.height)
                            .offset(x: riquadro.minX, y: riquadro.minY)
                    }
                    .frame(width: geometria.size.width, height: geometria.size.height)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { valore in
                                scalaImmagine = corrente.size.width / max(riquadro.width, 1)
                                tratto.append(Pennello.puntoImmagine(
                                    valore.location,
                                    riquadro: riquadro,
                                    dimensioneImmagine: corrente.size
                                ))
                            }
                            .onEnded { _ in conferma() }
                    )
                    .onAppear {
                        scalaImmagine = corrente.size.width / max(riquadro.width, 1)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                comandi
            }
            .padding()
            .navigationTitle("Ritocca")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") {
                        onFine(corrente)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        annulla()
                    } label: {
                        Label("Annulla tratto", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(storico.isEmpty)
                }
            }
        }
    }

    private var comandi: some View {
        VStack(spacing: 12) {
            Picker("Strumento", selection: $modalita) {
                ForEach(Pennello.Modalita.allCases) { valore in
                    Label(valore.nome, systemImage: valore.simbolo).tag(valore)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Circle()
                    .frame(width: 8, height: 8)
                Slider(value: $spessoreSchermo, in: 8...80) {
                    Text("Dimensione pennello")
                }
                Circle()
                    .frame(width: 22, height: 22)
            }
            .foregroundStyle(.secondary)

            Text(modalita == .gomma
                 ? "Passa il dito sui pezzi di sfondo da togliere."
                 : "Passa il dito sulle parti del capo da riportare.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
            } label: {
                Label("Tieni premuto per vedere l'originale", systemImage: "eye")
                    .font(.footnote)
            }
            .buttonStyle(.bordered)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in mostraOriginale = true }
                    .onEnded { _ in mostraOriginale = false }
            )
        }
    }

    private func conferma() {
        guard !tratto.isEmpty else { return }
        storico.append(corrente)
        if storico.count > massimoAnnullamenti {
            storico.removeFirst()
        }
        corrente = anteprima
        tratto = []
    }

    private func annulla() {
        guard let precedente = storico.popLast() else { return }
        corrente = precedente
    }
}

/// Sfondo a scacchi che rende visibile la trasparenza.
struct Scacchiera: View {
    var lato: CGFloat = 12

    var body: some View {
        Canvas { contesto, dimensione in
            let colonne = Int(dimensione.width / lato) + 1
            let righe = Int(dimensione.height / lato) + 1
            contesto.fill(Path(CGRect(origin: .zero, size: dimensione)), with: .color(Color(.systemBackground)))
            for riga in 0..<righe {
                for colonna in 0..<colonne where (riga + colonna) % 2 == 0 {
                    let quadrato = CGRect(x: CGFloat(colonna) * lato, y: CGFloat(riga) * lato, width: lato, height: lato)
                    contesto.fill(Path(quadrato), with: .color(Color(.tertiarySystemFill)))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
