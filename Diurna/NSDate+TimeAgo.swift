//
//  NSDate+TimeAgo.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 07/03/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import Cocoa

private var formatter: NSDateComponentsFormatter = {
    let calendar = NSCalendar.currentCalendar()
    calendar.locale = NSLocale(localeIdentifier: "en_EN")

    let formatter = NSDateComponentsFormatter()
    formatter.calendar = calendar
    formatter.unitsStyle = .Full
    formatter.allowedUnits = [.Minute, .Hour, .Day, .Year]
    formatter.maximumUnitCount = 1
    return formatter
}()

extension NSDate {
    func timeAgo() -> String {
        let components = NSCalendar.currentCalendar().components(
            [.Minute, .Hour, .Day, .Year],
            fromDate: self,
            toDate: NSDate(),
            options: []
        )

        if components.minute == 0 {
            return "just now"
        }

        return "\(formatter.stringFromDateComponents(components)!) ago"
    }
}