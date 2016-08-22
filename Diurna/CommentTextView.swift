import Cocoa

class CommentTextView: NSTextView {

    // MARK: Properties
    override var intrinsicContentSize: NSSize {
        get {
            guard let container = textContainer,
                let manager = layoutManager else {
                    return NSSize(width: NSViewNoIntrinsicMetric,
                                  height: NSViewNoIntrinsicMetric)
            }

            let availableWidth = bounds.width - textContainerInset.width

            container.size = NSSize(width: availableWidth,
                                    height: CGFloat.greatestFiniteMagnitude)
            manager.ensureLayout(for: container)

            var textSize = manager.usedRect(for: container).size

            textSize.height += textContainerInset.height

            return textSize
        }
    }

    override var textContainerOrigin: NSPoint {
        get {
            var origin = super.textContainerOrigin
            
            origin.x -= textContainerInset.width / 2.0
            origin.y -= textContainerInset.height / 2.0

            return origin
        }
    }

    var attributedStringValue: NSAttributedString {
        set {
            textStorage?.setAttributedString(newValue)
            invalidateIntrinsicContentSize()
        }
        
        get {
            return attributedString()
        }
    }

    // MARK: Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)

        commonSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonSetup()
    }

    private func commonSetup() {
        let storage = NSTextStorage(),
        manager = CommentLayoutManager(),
        container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))

        container.widthTracksTextView = true
        manager.allowsNonContiguousLayout = true // FIXME: messes up rendering ?

        manager.addTextContainer(container)
        storage.addLayoutManager(manager)

        textContainer = container

        textContainerInset = NSSize(width: 5.0, height: 5.0) // FIXME: @IBInspectable et al.
        isHorizontallyResizable = false
        isVerticallyResizable = false
        drawsBackground = false
        isEditable = false
        isSelectable = true
        isRichText = false
        usesRuler = false
        usesFontPanel = false

        delegate = self
    }

    // MARK: Methods
    override func layout() {
        invalidateIntrinsicContentSize()

        super.layout()
    }
}

// MARK: - NSTextViewDelegate
extension CommentTextView: NSTextViewDelegate {
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        return nil
    }
}
