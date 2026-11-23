import Foundation
import Testing
@testable import Hook

struct MeteoTests {
    @Test func decodificaLaRispostaDiOpenMeteo() throws {
        let json = """
        {
          "latitude": 41.9, "longitude": 12.5,
          "current": {"time": "2026-11-23T16:00", "temperature_2m": 11.4, "weather_code": 61},
          "daily": {
            "time": ["2026-11-23"],
            "temperature_2m_max": [14.2],
            "temperature_2m_min": [7.8],
            "precipitation_probability_max": [80]
          }
        }
        """
        let meteo = try MeteoService.decodifica(Data(json.utf8))
        #expect(meteo.temperatura == 11.4)
        #expect(meteo.massima == 14.2)
        #expect(meteo.minima == 7.8)
        #expect(meteo.probabilitaPioggia == 80)
        #expect(meteo.descrizione == "Pioggia")
        #expect(meteo.piove)
        #expect(meteo.serveCapospalla)
    }

    @Test func valoriGiornalieriMancantiUsanoLaTemperaturaAttuale() throws {
        let json = """
        {"current": {"temperature_2m": 20.0, "weather_code": 0},
         "daily": {"temperature_2m_max": [null], "temperature_2m_min": [null]}}
        """
        let meteo = try MeteoService.decodifica(Data(json.utf8))
        #expect(meteo.massima == 20)
        #expect(meteo.minima == 20)
        #expect(meteo.probabilitaPioggia == 0)
        #expect(!meteo.piove)
    }

    @Test func giornataCaldaESerenaNonChiedeCapospalla() {
        let meteo = Meteo(temperatura: 27, minima: 20, massima: 30, probabilitaPioggia: 5, codice: 0)
        #expect(!meteo.serveCapospalla)
        #expect(meteo.descrizione == "Sereno")
        #expect(meteo.consiglio.contains("caldo"))
    }
}

struct SuggerimentoOutfitTests {
    private let freddo = Meteo(temperatura: 6, minima: 2, massima: 9, probabilitaPioggia: 10, codice: 3)
    private let caldo = Meteo(temperatura: 28, minima: 21, massima: 31, probabilitaPioggia: 0, codice: 0)

    private func armadio() -> [Capo] {
        [
            Capo(nome: "Maglia", categoria: .top, foto: nil, miniatura: nil),
            Capo(nome: "Jeans", categoria: .pantaloni, foto: nil, miniatura: nil),
            Capo(nome: "Gonna", categoria: .gonne, foto: nil, miniatura: nil),
            Capo(nome: "Giacca", categoria: .capispalla, foto: nil, miniatura: nil),
            Capo(nome: "Sneakers", categoria: .scarpe, foto: nil, miniatura: nil),
        ]
    }

    @Test func conIlFreddoAggiungeIlCapospallaEEvitaLeGonne() {
        for seme in UInt64(0)..<50 {
            let outfit = SuggerimentoOutfit.suggerisci(capi: armadio(), meteo: freddo, seme: seme)
            let categorie = outfit.map(\.categoria)
            #expect(categorie.contains(.capispalla))
            #expect(categorie.contains(.top))
            #expect(categorie.contains(.pantaloni))
            #expect(!categorie.contains(.gonne))
            #expect(categorie.contains(.scarpe))
        }
    }

    @Test func conIlCaldoNienteCapospalla() {
        for seme in UInt64(0)..<50 {
            let outfit = SuggerimentoOutfit.suggerisci(capi: armadio(), meteo: caldo, seme: seme)
            #expect(!outfit.map(\.categoria).contains(.capispalla))
        }
    }

    @Test func stessoSemeStessoOutfit() {
        let capi = armadio() + [
            Capo(nome: "Camicia", categoria: .top, foto: nil, miniatura: nil),
            Capo(nome: "Chino", categoria: .pantaloni, foto: nil, miniatura: nil),
        ]
        let primo = SuggerimentoOutfit.suggerisci(capi: capi, meteo: caldo, seme: 42).map(\.nome)
        let secondo = SuggerimentoOutfit.suggerisci(capi: capi, meteo: caldo, seme: 42).map(\.nome)
        #expect(primo == secondo)
    }

    @Test func senzaTopUsaUnVestito() {
        let capi = [
            Capo(nome: "Vestito", categoria: .vestiti, foto: nil, miniatura: nil),
            Capo(nome: "Sandali", categoria: .scarpe, foto: nil, miniatura: nil),
        ]
        let outfit = SuggerimentoOutfit.suggerisci(capi: capi, meteo: caldo, seme: 1)
        #expect(outfit.map(\.nome) == ["Vestito", "Sandali"])
    }

    @Test func armadioInsufficienteNonSuggerisceNulla() {
        let capi = [Capo(nome: "Sneakers", categoria: .scarpe, foto: nil, miniatura: nil)]
        #expect(SuggerimentoOutfit.suggerisci(capi: capi, meteo: nil, seme: 1).isEmpty)
    }

    @Test func ilSemeCambiaOgniGiorno() throws {
        var calendario = Calendar(identifier: .gregorian)
        calendario.timeZone = try #require(TimeZone(identifier: "Europe/Rome"))
        let oggi = try #require(calendario.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 9)))
        let staseraTardi = try #require(calendario.date(from: DateComponents(year: 2026, month: 11, day: 23, hour: 23)))
        let domani = try #require(calendario.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: 9)))
        #expect(SuggerimentoOutfit.semeDelGiorno(oggi, calendario: calendario)
                == SuggerimentoOutfit.semeDelGiorno(staseraTardi, calendario: calendario))
        #expect(SuggerimentoOutfit.semeDelGiorno(oggi, calendario: calendario)
                != SuggerimentoOutfit.semeDelGiorno(domani, calendario: calendario))
    }
}
