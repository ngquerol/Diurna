//
//  Themeable.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/03/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

protocol Themeable {
    func themeDidChange(_ notification: Notification)
    func updateColors(from theme: ColorTheme)
}

