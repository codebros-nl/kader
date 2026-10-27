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
    case firstThird
    case centerThird
    case lastThird
    case firstTwoThirds
    case lastTwoThirds
    case maximize
    case center
    case nextScreen
    case previousScreen
    case restore
    case stashLeft
    case stashRight
    case unstashAll

    /// Indeling in groepen voor het menu en de instellingen.
    static let groups: [[WindowAction]] = [
        [.leftHalf, .rightHalf, .topHalf, .bottomHalf],
        [.topLeft, .topRight, .bottomLeft, .bottomRight],
        [.firstThird, .centerThird, .lastThird, .firstTwoThirds, .lastTwoThirds],
        [.maximize, .center, .restore],
        [.nextScreen, .previousScreen],
        [.stashLeft, .stashRight, .unstashAll],
    ]

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
        case .firstThird: "Eerste derde"
        case .centerThird: "Middelste derde"
        case .lastThird: "Laatste derde"
        case .firstTwoThirds: "Eerste tweederde"
        case .lastTwoThirds: "Laatste tweederde"
        case .maximize: "Maximaliseren"
        case .center: "Centreren"
        case .nextScreen: "Volgend scherm"
        case .previousScreen: "Vorig scherm"
        case .restore: "Herstellen"
        case .stashLeft: "Parkeer links"
        case .stashRight: "Parkeer rechts"
        case .unstashAll: "Geparkeerde vensters terugzetten"
        }
    }

    /// Aantal stappen bij herhaald drukken: helften lopen door ½ → ⅓ → ⅔.
    var cycleLength: Int {
        switch self {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf: 3
        default: 1
        }
    }
}
