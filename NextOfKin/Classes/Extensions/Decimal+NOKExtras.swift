//
//  Decimall+NOKExtras.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-12.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation

private let kinDecimal = Decimal(sign: .plus,
                                 exponent: -18,
                                 significand: Decimal(1))

public extension Decimal {
    
    public func kinToWei() -> Decimal {
        return self / kinDecimal
    }
    
    public func weiToKin() -> Decimal {
        return self * kinDecimal
    }
}
