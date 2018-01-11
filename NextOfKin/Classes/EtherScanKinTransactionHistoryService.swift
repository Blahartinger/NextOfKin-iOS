//
//  EtherScanKinTransactionHistoryService.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-12.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation
import RxSwift

public class EtherScanKinTransactionHistoryService: KinTransactionHistoryServiceType {

    struct Constants {
        // Transaction topic for an ERC20 token
        static let testTokenTransferEventTopic = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
        static let testTokenContractAddress = "0xef2fcc998847db203dea15fc49d0872c7614910c"
    }
    let queue:OperationQueue = OperationQueue()
    
    private func paddPublicKey(_ publicKey: String) -> String {
        return String(format:"0x%@", String(publicKey.suffix(publicKey.count-2)).leftPadding(toLength: 64, withPad: "0"))
    }
    
    public func getTransactionsFor(publicKey: String) -> Single<[KinTransaction]> {
        
        var urlComponents = URLComponents.init(string: "https://ropsten.etherscan.io/")
        urlComponents?.path = "/api"
        urlComponents?.queryItems = [URLQueryItem(name: "module", value: "logs"),
                                     URLQueryItem(name: "action", value: "getLogs"),
                                     URLQueryItem(name: "fromBlock", value: "0"),
                                     URLQueryItem(name: "toBlock", value: "latest"),
                                     URLQueryItem(name: "address", value: Constants.testTokenContractAddress),
                                     URLQueryItem(name: "topic0", value: Constants.testTokenTransferEventTopic),
                                     URLQueryItem(name: "topic1", value: paddPublicKey(publicKey))]
        
        let url: URL = (urlComponents?.url)!
        
        let subject = PublishSubject<[KinTransaction]>()
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue) ?? "")
            
            let response: [String:Any] = try! JSONSerialization.jsonObject(with: data!,
                                                                           options: []) as! [String:Any]

            let result = response["result"] as! [Any]
           
            NSLog(String(describing: result))
            
            var transactions = [KinTransaction]()
            for jsonTransaction in result {
                transactions.append(KinTransaction(json: jsonTransaction as! [String:Any] )!)
            }
            
            subject.onNext(transactions)
        }
        
        task.resume()
        
        return subject.asObservable().take(1).asSingle()
    }
}


