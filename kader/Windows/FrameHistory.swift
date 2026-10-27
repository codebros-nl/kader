import CoreGraphics

/// Onthoudt per venster het frame van vóór de eerste Kader-actie, voor "Herstellen".
nonisolated struct FrameHistory<Window: Hashable> {
    private var originalFrames: [Window: CGRect] = [:]
    private var lastKaderFrames: [Window: CGRect] = [:]

    /// Aanroepen vlak voordat Kader een venster verplaatst.
    mutating func willMove(_ window: Window, from currentFrame: CGRect) {
        // Heeft de gebruiker het venster zelf verplaatst sinds onze laatste actie,
        // dan wordt die positie het nieuwe uitgangspunt.
        if originalFrames[window] == nil || lastKaderFrames[window] != currentFrame {
            originalFrames[window] = currentFrame
        }
    }

    /// Aanroepen nadat Kader een venster heeft verplaatst, met het frame dat het venster werkelijk kreeg.
    mutating func didMove(_ window: Window, to frame: CGRect) {
        lastKaderFrames[window] = frame
    }

    /// Het frame om naar terug te gaan. Daarna is de geschiedenis van dit venster leeg.
    mutating func takeRestoreFrame(for window: Window) -> CGRect? {
        lastKaderFrames[window] = nil
        return originalFrames.removeValue(forKey: window)
    }
}
