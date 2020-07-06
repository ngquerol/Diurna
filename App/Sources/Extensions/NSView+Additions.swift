//
//  NSView+Additions.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 10/02/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

// MARK: - PlaceholderShowing

/// A view controller that is able to present a full-view placeholder, hiding all other subviews.
protocol PlaceholderShowing: NSViewController {
    /// The currently presented placeholder, if any.
    var placeholderView: NSView? { get set }
}

extension PlaceholderShowing {

    /// Present a placeholder with the specified message.
    ///
    /// - Note: If a progress overlay is already presented, it will be dismissed.
    /// - Parameter with: The message to display in the placeholder.
    func showPlaceholder(withTitle title: String) {
        // Reuse current placeholder, if any.
        guard case .none = placeholderView else {
            // Not pretty but the view's implementation *is* known.
            (placeholderView?.subviews.first as? NSTextField)?.stringValue = title
            return
        }

        let container = NSView(frame: view.frame)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.setValue(NSColor.controlBackgroundColor, forKey: "backgroundColor")

        let label = NSTextField(wrappingLabelWithString: title)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.isEnabled = false
        label.textColor = .placeholderTextColor

        container.addSubview(label)

        placeholderView = container

        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
    }

    /// Hide the currently presented placeholder.
    func hidePlaceholder() {
        placeholderView?.removeFromSuperview()
        placeholderView = nil
    }
}

// MARK: - ProgressShowing

private let progressOverlayAnimationDuration = 0.25

/// A view controller that is able to present a full-view overlay to indicate progress.
protocol ProgressShowing: NSViewController {
    /// The overlay view currently indicating progress, if any.
    var progressOverlayView: NSView? { get set }
}

extension ProgressShowing {
    /// Present a progress overlay with the specified message and an optional animation (fade-in).
    ///
    /// - Note: If a progress overlay is already presented, it will be dismissed.
    /// - Parameters:
    ///   - with: The message to display in the overlay.
    ///   - animating: Whether to animate the overlay presentation.
    func showProgressOverlay(with message: String, animating: Bool = true) {
        // Reuse the existing overlay, if any.
        if let _ = progressOverlayView { hideProgressOverlay(animating: false) }

        let overlay = ProgressOverlayView(frame: view.frame)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.alphaValue = 0
        overlay.messageTextField.stringValue = message

        progressOverlayView = overlay

        view.addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = animating ? progressOverlayAnimationDuration : 0
            progressOverlayView?.animator().alphaValue = 1
        }
    }

    /// Hide the currently presented progress overlay, with an optional animation (fade-out).
    ///
    /// - Parameter animating: Whether to animate the overlay presentation.
    func hideProgressOverlay(animating: Bool = true) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = animating ? progressOverlayAnimationDuration : 0
            ctx.completionHandler = {
                self.progressOverlayView?.removeFromSuperview()
                self.progressOverlayView = nil
            }
            progressOverlayView?.animator().alphaValue = 0
        }
    }
}
