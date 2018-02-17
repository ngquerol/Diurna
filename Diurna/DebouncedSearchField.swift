//
//  DebouncedSearchField.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 11/02/2018.
//  Copyright © 2018 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

@IBDesignable class DebouncedSearchField: NSSearchField {

    // MARK: Properties

    @IBInspectable var delay: TimeInterval = 0.5

    @IBInspectable var tolerance: TimeInterval = 0.2

    private var timer: Timer?

    // MARK: (De)initializers

    deinit {
        timer?.invalidate()
    }

    // MARK: Methods

    override func sendAction(_ action: Selector?, to target: Any?) -> Bool {
        guard
            let action = action,
            let target = target
        else {
            return false
        }

        debounce(action, on: target)

        return true
    }

    private func debounce(_ action: Selector, on target: Any) {
        if let timer = timer, timer.isValid {
            timer.fireDate = Date(timeIntervalSinceNow: delay)
        } else {
            timer = Timer.scheduledTimer(
                timeInterval: delay,
                target: target,
                selector: action,
                userInfo: nil,
                repeats: false
            )
        }

        self.timer?.tolerance = tolerance * delay
    }
}
