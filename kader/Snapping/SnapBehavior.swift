import Foundation

/// Plek langs de schermrand waar een gesleept venster kan snappen.
nonisolated enum SnapPosition: String, CaseIterable, Identifiable, Sendable {
    case left
    case right
    case top
    case bottom
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .left: String(localized: "Left Edge", comment: "Screen edge or corner where a dragged window snaps")
        case .right: String(localized: "Right Edge", comment: "Screen edge or corner where a dragged window snaps")
        case .top: String(localized: "Top Edge", comment: "Screen edge or corner where a dragged window snaps")
        case .bottom: String(localized: "Bottom Edge", comment: "Screen edge or corner where a dragged window snaps")
        case .topLeft: String(localized: "Top Left Corner", comment: "Screen edge or corner where a dragged window snaps")
        case .topRight: String(localized: "Top Right Corner", comment: "Screen edge or corner where a dragged window snaps")
        case .bottomLeft: String(localized: "Bottom Left Corner", comment: "Screen edge or corner where a dragged window snaps")
        case .bottomRight: String(localized: "Bottom Right Corner", comment: "Screen edge or corner where a dragged window snaps")
        }
    }

    var defaultBehavior: SnapBehavior {
        switch self {
        case .left: .action(.leftHalf)
        case .right: .action(.rightHalf)
        case .top: .action(.maximize)
        case .bottom: .thirds
        case .topLeft: .action(.topLeft)
        case .topRight: .action(.topRight)
        case .bottomLeft: .action(.bottomLeft)
        case .bottomRight: .action(.bottomRight)
        }
    }

    var isHorizontalEdge: Bool { self == .top || self == .bottom }

    var settingsKey: String { "snapArea.\(rawValue)" }
}

/// Wat er gebeurt als een venster op een snapplek wordt losgelaten.
/// Opgeslagen als tekst, zodat het met `@AppStorage` werkt.
nonisolated enum SnapBehavior: Hashable, Sendable, RawRepresentable {
    /// Deze plek doet niets.
    case none
    /// Eerste, middelste of laatste derde, afhankelijk van de positie langs de rand.
    case thirds
    case action(WindowAction)

    /// Acties met een vaste indeling; parkeren, herstellen en scherm wisselen passen niet bij slepen.
    static let layoutActions: [WindowAction] = [
        .leftHalf, .rightHalf, .topHalf, .bottomHalf,
        .topLeft, .topRight, .bottomLeft, .bottomRight,
        .firstThird, .centerThird, .lastThird, .firstTwoThirds, .lastTwoThirds,
        .maximize, .center,
    ]

    init?(rawValue: String) {
        switch rawValue {
        case "none": self = .none
        case "thirds": self = .thirds
        default:
            guard let action = WindowAction(rawValue: rawValue), Self.layoutActions.contains(action) else {
                return nil
            }
            self = .action(action)
        }
    }

    var rawValue: String {
        switch self {
        case .none: "none"
        case .thirds: "thirds"
        case .action(let action): action.rawValue
        }
    }

    var title: String {
        switch self {
        case .none: String(localized: "Do Nothing", comment: "What happens when a window is dropped on a screen edge or corner")
        case .thirds: String(localized: "Thirds, by Position", comment: "What happens when a window is dropped on a screen edge or corner")
        case .action(let action): action.title
        }
    }

    /// Keuzes voor een plek. Derden op positie kan alleen langs de boven- en onderrand.
    static func options(for position: SnapPosition) -> [SnapBehavior] {
        [.none] + (position.isHorizontalEdge ? [.thirds] : []) + layoutActions.map { .action($0) }
    }

    /// Het ingestelde gedrag voor een plek, of de standaard als er niets (geldigs) is ingesteld.
    static func current(for position: SnapPosition, defaults: UserDefaults = .standard) -> SnapBehavior {
        defaults.string(forKey: position.settingsKey).flatMap(SnapBehavior.init(rawValue:)) ?? position.defaultBehavior
    }
}
