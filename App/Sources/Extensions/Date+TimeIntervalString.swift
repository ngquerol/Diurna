//
//  Date+TimeIntervalString.swift
//  Diurna
//
//  Created by Nicolas Gaulard-Querol on 07/03/2016.
//  Copyright © 2016 Nicolas Gaulard-Querol. All rights reserved.
//

import AppKit

// Note to self: this property is global, but only visible in this file.
private var formatter: DateComponentsFormatter = {
    var calendar = Calendar.current
    var formatter = DateComponentsFormatter()

    calendar.locale = Locale(identifier: "en_EN")

    formatter.calendar = calendar
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.minute, .hour, .day, .year]
    formatter.maximumUnitCount = 1

    return formatter
}()

extension Date {
    /// The amount of upcoming or elapsed time relative to now, expressed in English.
    ///
    /// If said amount is less or equal than a minute, returns `just now`.
    /// - note: Returns `some time { ago | from now }` as a fallback if formatting fails.
    var timeIntervalString: String {
        let now = Date(),
            components = Calendar.current.dateComponents(
                [.minute, .hour, .day, .year],
                from: self,
                to: now
            )

        if Calendar.current.isDateInToday(self),
            components.hour == 0,
            components.minute == 0
        {
            return "just now"
        }

        let timeString = formatter.string(from: components) ?? "some time"

        return now < self ? "\(timeString) from now" : "\(timeString) ago"
    }
}
