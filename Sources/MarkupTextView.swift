import Cocoa

class MarkupTextView: SelfSizingTextView {

    // MARK: Initializers

    override init(frame frameRect: NSRect) {
        let textStorage = NSTextStorage(),
            layoutManager = MarkupLayoutManager(),
            textContainer = NSTextContainer(size: frameRect.size)

        super.init(frame: frameRect, textContainer: textContainer)

        commonSetup(container: textContainer, manager: layoutManager, storage: textStorage)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let textStorage = NSTextStorage(),
            layoutManager = MarkupLayoutManager(),
            textContainer = NSTextContainer(size: frame.size)

        commonSetup(container: textContainer, manager: layoutManager, storage: textStorage)

        replaceTextContainer(textContainer)
    }

    private func commonSetup(container: NSTextContainer, manager: NSLayoutManager, storage: NSTextStorage) {
        container.heightTracksTextView = false
        container.widthTracksTextView = false
        container.lineFragmentPadding = 0.0
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)

        textContainerInset = .zero
        isHorizontallyResizable = true
        isVerticallyResizable = true
        minSize = .zero
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        drawsBackground = false
        isEditable = false
        isSelectable = true
        isRichText = false
        usesRuler = false
        usesFontPanel = false
        isGrammarCheckingEnabled = false
        isContinuousSpellCheckingEnabled = false
        isAutomaticSpellingCorrectionEnabled = false
        smartInsertDeleteEnabled = false
        isAutomaticTextReplacementEnabled = false

        delegate = self
    }
}

// MARK: - NSTextView Delegate

extension MarkupTextView: NSTextViewDelegate {
    func textView(_: NSTextView, menu: NSMenu, for _: NSEvent, at _: Int) -> NSMenu? {
        let hiddenSubmenusTitles = ["Spelling and Grammar", "Substitutions", "Speech"]

        hiddenSubmenusTitles.compactMap(menu.item).forEach(menu.removeItem)

        return menu
    }

    func textView(_: NSTextView, clickedOnLink link: Any, at _: Int) -> Bool {
        guard let link = link as? URL else { return false }

        do {
            try NSWorkspace.shared.open(link, options: .withoutActivation, configuration: [:])
            return true
        } catch let error as NSError {
            NSLog("%@", error.localizedDescription)
            return false
        }
    }
}
