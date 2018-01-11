//
//  NSData+NOKExtras.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-11.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation

extension NSData {
    static func randomData(withLength: UInt) -> NSData {
        let localLength = Int(withLength)
        var ptr = [CUnsignedChar](repeating: 0, count: localLength)
        for i in 0..<localLength {
            ptr[i] = CUnsignedChar(arc4random() % 255)
        }
        return NSData(bytes: ptr, length:localLength)
    }
}
