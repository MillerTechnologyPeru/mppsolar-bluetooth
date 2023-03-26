//
//  Mock.swift
//  
//
//  Created by Alsey Coleman Miller on 3/22/23.
//

import Foundation
import MPPSolar

#if os(macOS) && DEBUG

internal extension MPPSolar {
    
    final class Mock: MPPSolarConnection {
        
        var responses = [Data: Data]()
        
        init(responses: [Data: Data]) {
            self.responses = responses
        }
        
        private var lastRequest: Data?
        
        func send(_ data: Data) throws {
            guard let response = responses[data] else {
                throw POSIXError(.EBADF)
            }
            lastRequest = response
        }
        
        func recieve(_ size: Int) throws -> Data {
            guard let data = self.lastRequest else {
                throw POSIXError(.EBADF)
            }
            lastRequest = nil
            return data
        }
    }
}

internal extension MPPSolar {
    
    static var mock: MPPSolar {
        return MPPSolar(connection: .mock)
    }
}

internal extension MPPSolarConnection where Self == MPPSolar.Mock {
    
    static func mock(
        _ responses: [Data: Data]
    ) -> MPPSolar.Mock {
        MPPSolar.Mock(responses: responses)
    }
    
    static var mock: MPPSolar.Mock {
        MPPSolar.Mock()
    }
}

internal extension MPPSolar.Mock {
    
    convenience init() {
        self.init(responses: [
            // protocol id
            Data([81, 80, 73, 190, 172, 13]) : Data([40, 80, 73, 51, 48, 154, 11, 13]),
            // serial number
            Data([81, 73, 68, 214, 234, 13]) : Data([40, 57, 50, 54, 51, 49, 56, 48, 55, 49, 48, 48, 51, 53, 56, 151, 217, 13, 0, 0, 0, 0, 0, 0]),
            // device mode
            Data([81, 77, 79, 68, 73, 193, 13]) : Data([40, 66, 231, 201, 13, 0, 0, 0]),
            // general status
            Data([81, 80, 73, 71, 83, 183, 169, 13]) : Data([40, 48, 48, 49, 46, 48, 32, 48, 48, 46, 48, 32, 50, 50, 57, 46, 48, 32, 54, 48, 46, 48, 32, 48, 48, 48, 48, 32, 48, 48, 48, 48, 32, 48, 48, 48, 32, 51, 53, 48, 32, 50, 52, 46, 56, 51, 32, 48, 48, 53, 32, 48, 52, 53, 32, 48, 52, 50, 50, 32, 48, 48, 48, 54, 32, 48, 50, 52, 46, 53, 32, 50, 52, 46, 56, 57, 32, 48, 48, 48, 48, 48, 32, 49, 48, 48, 49, 48, 49, 49, 48, 32, 48, 48, 32, 48, 51, 32, 48, 48, 49, 53, 55, 32, 48, 48, 48, 189, 115, 13, 0, 0])
            
        ])
    }
}

#endif
