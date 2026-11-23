import Foundation

/// Meteo di oggi in un punto, con quello che serve per scegliere cosa indossare.
struct Meteo: Equatable, Sendable {
    /// Temperatura attuale in °C.
    let temperatura: Double
    let minima: Double
    let massima: Double
    /// Probabilità massima di pioggia nella giornata, 0...100.
    let probabilitaPioggia: Int
    /// Codice WMO delle condizioni attuali.
    let codice: Int

    var piove: Bool {
        probabilitaPioggia >= 50 || (51...67).contains(codice) || (80...82).contains(codice) || codice >= 95
    }

    /// Serve uno strato in più: giornata fresca o pioggia probabile.
    var serveCapospalla: Bool {
        massima < 18 || piove
    }

    var descrizione: String {
        switch codice {
        case 0: "Sereno"
        case 1: "Poco nuvoloso"
        case 2: "Parzialmente nuvoloso"
        case 3: "Coperto"
        case 45, 48: "Nebbia"
        case 51...57: "Pioviggine"
        case 61...67: "Pioggia"
        case 71...77, 85, 86: "Neve"
        case 80...82: "Rovesci"
        case 95...99: "Temporale"
        default: "Variabile"
        }
    }

    var simbolo: String {
        switch codice {
        case 0: "sun.max.fill"
        case 1, 2: "cloud.sun.fill"
        case 3: "cloud.fill"
        case 45, 48: "cloud.fog.fill"
        case 51...57: "cloud.drizzle.fill"
        case 61...67, 80...82: "cloud.rain.fill"
        case 71...77, 85, 86: "cloud.snow.fill"
        case 95...99: "cloud.bolt.rain.fill"
        default: "cloud.sun.fill"
        }
    }

    /// Un consiglio breve su cosa mettere.
    var consiglio: String {
        if massima < 5 { return "Fa molto freddo: cappotto e strati caldi." }
        if piove { return "Probabile pioggia: meglio una giacca e scarpe chiuse." }
        if massima < 12 { return "Giornata fredda: non dimenticare un capospalla." }
        if massima < 18 { return "Fresco: porta uno strato in più." }
        if massima < 26 { return "Temperatura piacevole: vestiti leggero." }
        return "Fa caldo: capi leggeri e traspiranti."
    }
}

/// Dati meteo da Open-Meteo (gratuito, senza chiave né account; dati CC BY 4.0).
enum MeteoService {
    enum Errore: Error {
        case rispostaNonValida
    }

    static func carica(latitudine: Double, longitudine: Double) async throws -> Meteo {
        // Coordinate arrotondate a circa 1 km: bastano per il meteo e proteggono la privacy.
        var componenti = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        componenti.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.2f", latitudine)),
            URLQueryItem(name: "longitude", value: String(format: "%.2f", longitudine)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        guard let url = componenti.url else { throw Errore.rispostaNonValida }
        let (dati, risposta) = try await URLSession.shared.data(from: url)
        guard let http = risposta as? HTTPURLResponse, http.statusCode == 200 else {
            throw Errore.rispostaNonValida
        }
        return try decodifica(dati)
    }

    static func decodifica(_ dati: Data) throws -> Meteo {
        struct Risposta: Decodable {
            struct Attuale: Decodable {
                let temperature_2m: Double
                let weather_code: Int
            }
            struct Giornaliero: Decodable {
                let temperature_2m_max: [Double?]
                let temperature_2m_min: [Double?]
                let precipitation_probability_max: [Int?]?
            }
            let current: Attuale
            let daily: Giornaliero
        }
        let risposta = try JSONDecoder().decode(Risposta.self, from: dati)
        let attuale = risposta.current.temperature_2m
        return Meteo(
            temperatura: attuale,
            minima: risposta.daily.temperature_2m_min.first.flatMap { $0 } ?? attuale,
            massima: risposta.daily.temperature_2m_max.first.flatMap { $0 } ?? attuale,
            probabilitaPioggia: risposta.daily.precipitation_probability_max?.first.flatMap { $0 } ?? 0,
            codice: risposta.current.weather_code
        )
    }
}
