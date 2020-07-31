//
//  OSLog+Categories.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 18/02/2020.
//  Copyright © 2020 Nicolas Gaulard-Querol. All rights reserved.
//

import OSLog

extension OSLog {
    static let apiRequests = OSLog(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "apiRequests"
    )

    static let webRequests = OSLog(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "webRequests"
    )
}
