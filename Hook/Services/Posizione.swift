import CoreLocation

struct Coordinate: Equatable, Sendable {
    let latitudine: Double
    let longitudine: Double
}

/// Chiede una sola volta la posizione approssimativa, per il meteo.
@MainActor
final class Posizione: NSObject, CLLocationManagerDelegate {
    enum Errore: Error {
        case permessoNegato
        case nonDisponibile
    }

    private let manager = CLLocationManager()
    private var attesa: CheckedContinuation<Coordinate, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var permessoNegato: Bool {
        manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted
    }

    func attuale() async throws -> Coordinate {
        if permessoNegato { throw Errore.permessoNegato }
        // Una richiesta alla volta: se ce n'è già una in corso, la chiudiamo.
        attesa?.resume(throwing: Errore.nonDisponibile)
        return try await withCheckedThrowingContinuation { continuazione in
            attesa = continuazione
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    private func autorizzazioneCambiata(_ stato: CLAuthorizationStatus) {
        guard attesa != nil else { return }
        switch stato {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            completa(.failure(Errore.permessoNegato))
        default:
            break
        }
    }

    private func completa(_ risultato: Result<Coordinate, Error>) {
        attesa?.resume(with: risultato)
        attesa = nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let stato = manager.authorizationStatus
        Task { @MainActor in self.autorizzazioneCambiata(stato) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else { return }
        let posizione = Coordinate(latitudine: coordinate.latitude, longitudine: coordinate.longitude)
        Task { @MainActor in self.completa(.success(posizione)) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.completa(.failure(Errore.nonDisponibile)) }
    }
}
