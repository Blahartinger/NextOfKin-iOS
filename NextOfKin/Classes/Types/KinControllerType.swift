//
//  KinControllerType.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-11.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation
import RxSwift

/**
 * Exposes the ability to interact with the user's Kin wallet and the balance of their wallet
 */
public protocol KinControllerType {
    /**
     * Clears the state of the Kin wallet, removing any existing wallet from storage
     */
    func clearWallet() -> Completable
    
    /**
     * Transfers Kin from the user's wallet to the recipient
     * @param recipient The hex-encoded public address of the Kin recipient
     * @param amount The amount of Kin to transfer to the recipient
     * @return A single of the transaction ID for the transfer. The single will resolve
     * when the transaction has been sent to the network, *not* after confirmation
     */
    func sendKin(recipient: String, amount: NSDecimalNumber) -> Single<String>
    
    /**
     * Exports the keystore in JSON format for consumption by other ethereum wallets
     * @param passphrase The passphrase with which to encrypt the keystore content
     * @return A single of the JSON-encoded wallet
     */
    func exportKeyStore(passphrase: String) -> Single<String>
}
