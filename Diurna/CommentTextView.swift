import Cocoa

class CommentTextView: NSTextView {

    // MARK: Properties
    override var intrinsicContentSize: NSSize {
        guard
            let container = textContainer,
            let manager = layoutManager
        else {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }

        // FIXME: The text container's width is supposed to update according to the text view's frame,
        // but it is seems `widthTracksTextView` is not enough here.
        let availableWidth = bounds.width - textContainerInset.width

        container.size = NSSize(width: availableWidth, height: .greatestFiniteMagnitude)
        manager.ensureLayout(for: container)

        var textSize = manager.usedRect(for: container).size

        textSize.height += textContainerInset.height

        return textSize
    }

    override var textContainerOrigin: NSPoint {
        var origin = super.textContainerOrigin

        origin.x -= textContainerInset.width / 2.0
        origin.y -= textContainerInset.height / 2.0

        return origin
    }

    var attributedStringValue: NSAttributedString {
        set {
            textStorage?.setAttributedString(newValue)
        }

        get {
            return attributedString()
        }
    }

    // MARK: Initializers
    override init(frame frameRect: NSRect) {
        let textStorage = NSTextStorage(),
            layoutManager = CommentLayoutManager(),
            textContainer = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))

        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        super.init(frame: frameRect, textContainer: textContainer)

        commonSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let textStorage = NSTextStorage(),
            layoutManager = CommentLayoutManager(),
            textContainer = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))

        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        replaceTextContainer(textContainer)

        commonSetup()
    }

    private func commonSetup() {
        textContainerInset = NSSize(width: 5.0, height: 5.0) // FIXME: @IBInspectable et al.
        isHorizontallyResizable = false
        isVerticallyResizable = false
        drawsBackground = true
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

    // MARK: Methods
    override func layout() {
        super.layout()

        if bounds.size != intrinsicContentSize {
            invalidateIntrinsicContentSize()
        }
    }

    override func didChangeText() {
        super.didChangeText()

        invalidateIntrinsicContentSize()
    }
}

// MARK: - NSTextView Delegate
extension CommentTextView: NSTextViewDelegate {
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        let hiddenSubmenusTitles = [ "Spelling and Grammar", "Substitutions", "Speech" ]

        hiddenSubmenusTitles.flatMap { menu.item(withTitle: $0) }.forEach { menu.removeItem($0) }

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
