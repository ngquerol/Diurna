//
//  NSAlert+ShowModal.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 31/07/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

extension NSAlert {

    @discardableResult static func showModal(
        withTitle title: String,
        andText text: String = "",
        andStyle style: Style = .informational
    ) -> NSApplication.ModalResponse {
        let alert = NSAlert()
        alert.alertStyle = style
        alert.messageText = title
        alert.informativeText = text

        return alert.runModal()
    }
}
