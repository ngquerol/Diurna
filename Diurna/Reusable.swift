//
//  Reusable.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 28/01/2017.
//  Copyright © 2017 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

protocol Reusable {

    static var reuseIdentifier: NSUserInterfaceItemIdentifier { get }
}
