import AppKit


enum PasteboardHelper {
    private static let pasteboard = NSPasteboard.general


    private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")


    static func readString() -> String? {
        pasteboard.string(forType: .string)
    }


    static func writeString(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }


    static func clear() {
        pasteboard.clearContents()
    }


    static func getChangeCount() -> Int {
        pasteboard.changeCount
    }


    static func isPasteboardConcealed() -> Bool {
        let types = pasteboard.types ?? []
        return types.contains(concealedType) || types.contains(transientType)
    }
}
