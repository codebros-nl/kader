import CoreGraphics

/// Pure logica: koppelt opgeslagen plaatsingen aan de open vensters van één app.
nonisolated enum LayoutMatcher {
    /// Eerst op gelijke titel, daarna de overgebleven plaatsingen en vensters op volgorde.
    /// Een venster wordt hooguit één keer gebruikt; overtollige plaatsingen of vensters vallen af.
    static func match<Window>(
        _ placements: [WindowPlacement],
        to windows: [(window: Window, title: String)]
    ) -> [(window: Window, frame: CGRect)] {
        var windowForPlacement: [Int: Int] = [:]
        var usedWindows = Set<Int>()

        for (placementIndex, placement) in placements.enumerated() where !placement.title.isEmpty {
            if let windowIndex = windows.indices.first(where: {
                !usedWindows.contains($0) && windows[$0].title == placement.title
            }) {
                windowForPlacement[placementIndex] = windowIndex
                usedWindows.insert(windowIndex)
            }
        }

        var remainingWindows = windows.indices.filter { !usedWindows.contains($0) }.makeIterator()
        for placementIndex in placements.indices where windowForPlacement[placementIndex] == nil {
            guard let windowIndex = remainingWindows.next() else { break }
            windowForPlacement[placementIndex] = windowIndex
        }

        return placements.indices.compactMap { placementIndex in
            windowForPlacement[placementIndex].map { (windows[$0].window, placements[placementIndex].frame) }
        }
    }
}
