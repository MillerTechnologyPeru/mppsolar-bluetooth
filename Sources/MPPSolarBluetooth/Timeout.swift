//
//  Timeout.swift
//
//
//  Created by Alsey Coleman Miller on 19/04/21.
//

import Foundation
import GATT

internal struct Timeout {
    
    let start: Date
    
    let duration: TimeInterval
    
    var end: Date {
        return start + duration
    }
    
    init(start: Date = Date(),
         duration: TimeInterval) {
        self.start = start
        self.duration = duration
    }
    
    @discardableResult
    func timeRemaining(for date: Date = Date()) throws -> TimeInterval {
        let remaining = end.timeIntervalSince(date)
        if remaining > 0 {
            return remaining
        } else {
            throw CentralError.timeout
        }
    }
}
