/// Alle acties die Kader op een venster kan uitvoeren, los van hoe ze worden aangeroepen.
nonisolated enum WindowAction: String, CaseIterable, Identifiable, Sendable {
    case leftHalf
    case rightHalf
    case topHalf
    case bottomHalf
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case maximize
    case center

    var id: String { rawValue }

    var title: String {
        switch self {
        case .leftHalf: "Linkerhelft"
        case .rightHalf: "Rechterhelft"
        case .topHalf: "Bovenste helft"
        case .bottomHalf: "Onderste helft"
        case .topLeft: "Linksboven"
        case .topRight: "Rechtsboven"
        case .bottomLeft: "Linksonder"
        case .bottomRight: "Rechtsonder"
        case .maximize: "Maximaliseren"
        case .center: "Centreren"
        }
    }
}
