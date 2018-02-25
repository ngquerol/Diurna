//
//  Int+KFormatted.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 16/12/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Foundation

extension Int {
    var kFormatted: String {
        return String(
            format: self >= 1000 ? "%.1gK" : "%d",
            self >= 1000 ? Double(self) / 1000.0 : self
        )
    }
}
