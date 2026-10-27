import CoreGraphics

/// Houdt bij welke actie het laatst op welk venster is uitgevoerd,
/// zodat herhaald drukken door de varianten van een actie loopt (½ → ⅓ → ⅔).
nonisolated struct ActionCycle<Window: Hashable> {
    private var last: (window: Window, action: WindowAction, step: Int, frame: CGRect)?

    /// De stap voor deze actie. Er wordt alleen doorgelopen als het venster sinds de vorige keer
    /// niet door iets anders is verplaatst; anders begint de cyclus opnieuw.
    func step(for action: WindowAction, window: Window, currentFrame: CGRect) -> Int {
        guard
            action.cycleLength > 1,
            let last,
            last.window == window,
            last.action == action,
            last.frame == currentFrame
        else {
            return 0
        }
        return (last.step + 1) % action.cycleLength
    }

    mutating func record(_ action: WindowAction, step: Int, window: Window, resultingFrame: CGRect) {
        last = (window, action, step, resultingFrame)
    }
}
