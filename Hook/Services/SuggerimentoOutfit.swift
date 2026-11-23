import Foundation

/// Propone un outfit con i capi dell'armadio, adatto al meteo.
/// Lo stesso seme dà sempre lo stesso outfit: così il suggerimento resta stabile
/// per tutta la giornata e cambia solo quando l'utente chiede di rimescolare.
enum SuggerimentoOutfit {
    static func suggerisci(capi: [Capo], meteo: Meteo?, seme: UInt64) -> [Capo] {
        var generatore = GeneratoreConSeme(seme: seme)
        func per(_ categorie: Categoria...) -> [Capo] {
            capi.filter { categorie.contains($0.categoria) }
        }
        func scegli(_ candidati: [Capo]) -> Capo? {
            guard !candidati.isEmpty else { return nil }
            // I preferiti contano doppio.
            let pesati = candidati + candidati.filter(\.preferito)
            return pesati[Int(generatore.next() % UInt64(pesati.count))]
        }

        let freddo = (meteo?.massima ?? 20) < 12
        let top = per(.top)
        // Con il freddo le gonne restano nell'armadio, se ci sono pantaloni.
        let sotto = freddo && !per(.pantaloni).isEmpty ? per(.pantaloni) : per(.pantaloni, .gonne)
        let vestiti = per(.vestiti)

        var scelti: [Capo] = []
        let puoUsareTopESotto = !top.isEmpty && !sotto.isEmpty
        let preferisciVestito = !vestiti.isEmpty && !freddo && generatore.next() % 10 < 3
        if !vestiti.isEmpty && (!puoUsareTopESotto || preferisciVestito) {
            scelti.append(contentsOf: [scegli(vestiti)].compactMap { $0 })
        } else {
            scelti.append(contentsOf: [scegli(top), scegli(sotto)].compactMap { $0 })
        }
        guard !scelti.isEmpty else { return [] }

        if meteo?.serveCapospalla ?? false, let capospalla = scegli(per(.capispalla)) {
            scelti.append(capospalla)
        }
        if let scarpe = scegli(per(.scarpe)) {
            scelti.append(scarpe)
        }
        if generatore.next() % 2 == 0, let borsa = scegli(per(.borse)) {
            scelti.append(borsa)
        }
        if generatore.next() % 2 == 0, let accessorio = scegli(per(.accessori)) {
            scelti.append(accessorio)
        }
        return scelti
    }

    /// Seme del giorno: cambia a mezzanotte.
    static func semeDelGiorno(_ data: Date = .now, calendario: Calendar = .current) -> UInt64 {
        let componenti = calendario.dateComponents([.year, .month, .day], from: data)
        let anno: Int = componenti.year ?? 0
        let mese: Int = componenti.month ?? 0
        let giorno: Int = componenti.day ?? 0
        let valore: Int = anno * 10_000 + mese * 100 + giorno
        return UInt64(valore)
    }
}

/// Generatore pseudocasuale deterministico (SplitMix64).
struct GeneratoreConSeme: RandomNumberGenerator {
    private var stato: UInt64

    init(seme: UInt64) {
        stato = seme
    }

    mutating func next() -> UInt64 {
        stato &+= 0x9E37_79B9_7F4A_7C15
        var z = stato
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
