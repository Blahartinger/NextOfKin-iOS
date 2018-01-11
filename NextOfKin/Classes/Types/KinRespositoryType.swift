//
//  KinRespositoryType.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-11.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation
import RxSwift

public protocol KinRespositoryType {
    /**
     * @return A single of the confirmed balance of the user's Kin wallet
     */
    func getBalance() -> Single<NSDecimalNumber>
    
    /**
     * @return A single of the user's pending balance according to the proxy node
     */
    func getPendingBalance() -> Single<NSDecimalNumber>
    
    /**
     * @return True when the user's wallet is created and available for use
     */
    func isWalletAvailable() -> Observable<Bool>
    
    /**
     * @return The public address of the currently-active Kin wallet of the user
     */
    func getPublicAddress() -> Observable<String?>
}
