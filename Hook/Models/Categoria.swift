import Foundation

/// Tipologia di un capo. Il valore grezzo è quello salvato nel database:
/// non rinominarlo senza una migrazione.
enum Categoria: String, Codable, CaseIterable, Identifiable, Sendable {
    case top
    case capispalla
    case pantaloni
    case gonne
    case vestiti
    case scarpe
    case borse
    case accessori

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .top: "Top"
        case .capispalla: "Capispalla"
        case .pantaloni: "Pantaloni"
        case .gonne: "Gonne"
        case .vestiti: "Vestiti"
        case .scarpe: "Scarpe"
        case .borse: "Borse"
        case .accessori: "Accessori"
        }
    }

    var simbolo: String {
        switch self {
        case .top: "tshirt"
        case .capispalla: "thermometer.snowflake"
        case .pantaloni: "figure.walk"
        case .gonne: "triangle"
        case .vestiti: "figure.dress.line.vertical.figure"
        case .scarpe: "shoe"
        case .borse: "handbag"
        case .accessori: "eyeglasses"
        }
    }
}
