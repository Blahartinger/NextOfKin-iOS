//
//  TestTokenService.swift
//  CashCow
//
//  Created by Bryan Lahartinger on 2017-12-13.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation
import RxSwift

/**
 * This is used to fill a ropsten network wallet with 10K test ERC20 tokens.
 * You **MUST** be on the ropsten test network of this will fail.
 */
public class TestTokenService {
    public func giveMeTokensFor(publicKey: String) -> Completable {
        let subject = PublishSubject<Any>()
        guard let url = URL(string: String(format:"http://kin-faucet.rounds.video/send?public_address=%@", publicKey)) else {
            return Completable.error(RxError.argumentOutOfRange)
        }
        
        let task = URLSession.shared.dataTask(with: url){ data,response,error in
            if error != nil{
                return
            }
            
            subject.onCompleted()
        }
            
        task.resume()
        return subject.asCompletableIgnoringEvents()
    }
}
