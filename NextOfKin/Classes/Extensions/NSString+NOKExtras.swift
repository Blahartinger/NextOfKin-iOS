//
//  NSString+NOKExtras.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-12.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation

extension String {
    public func leftPadding(toLength: Int, withPad character: Character) -> String {
        let newLength = self.characters.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
        }
    }
}
