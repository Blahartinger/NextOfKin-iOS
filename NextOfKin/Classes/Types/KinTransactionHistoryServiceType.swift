//
//  KinTransactionHistoryServiceType.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-12.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation
import RxSwift

public protocol KinTransactionHistoryServiceType {
    func getTransactionsFor(publicKey: String) -> Single<[KinTransaction]>
}
