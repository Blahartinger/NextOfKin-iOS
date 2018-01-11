//
//  KinTransaction.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-12.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation

// Example:
//{
//    "address": "0xef2fcc998847db203dea15fc49d0872c7614910c",
//    "topics": [
//    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
//    "0x0000000000000000000000006207055328234551cc6176096707cdd498460521",
//    "0x0000000000000000000000005f4546837fe5c3ac268fd023cc870dffc29b6fc9"
//    ],
//    "data": "0x0000000000000000000000000000000000000000000000007ce66c50e2840000",
//    "blockNumber": "0x2261fe",
//    "timeStamp": "0x5a3004bc",
//    "gasPrice": "0x3b9aca00",
//    "gasUsed": "0x8f1f",
//    "logIndex": "0xc",
//    "transactionHash": "0xad75c0314081595083f1a4971c2ba42bb6a66fa0c5a312fcd2579e88b778794d",
//    "transactionIndex": "0x11"
//}

public struct KinTransaction: KinTransactionType {
    let address: String
    let from: String
    let to: String
    let timestamp: Date
    let value: UInt64
    let data: String
}

// MARK: Json Constructor
public extension KinTransaction {
    init?(json: [String:Any]) {
        guard let address = json["address"] as? String,
            let from = (json["topics"] as! [Any])[1] as? String,
            let to = (json["topics"] as! [Any])[2] as? String,
            let timestampHex = json["timeStamp"] as? String,
            let data = json["data"] as? String
            else {
                return nil
        }

        self.address = address
        self.from = from
        self.to = to
        self.data = data
        
//        let valueDecimalNumber: NSDecimalNumber = Decimal(string: String(data.suffix(data.count-2))) as! NSDecimalNumber
//
//        guard let value = UInt64(data.suffix(data.count-2), radix: 16) else {
//            return nil
//        }
//        self.value = value
        self.value = 0
        
        guard let timeDecimalValue = Int64(timestampHex.suffix(timestampHex.count-2), radix: 16) else {
            return nil
        }
        
        self.timestamp = Date(timeIntervalSince1970: TimeInterval(timeDecimalValue))
    }
}


