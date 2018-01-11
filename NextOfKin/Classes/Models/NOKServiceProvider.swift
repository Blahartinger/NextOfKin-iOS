//
//  NOKServiceProvider.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-11.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation
import KinSDK

public class NOKServiceProvider: ServiceProvider {
    public var url: URL
    
    public var networkId: NetworkId
    
    /**
     * urlString MUST be a valid url
     */
    init(urlString: String, networkId: NetworkId) {
        self.url = URL(string: urlString)!
        self.networkId = networkId
    }
    
    public func getProviderUrl() -> URL {
        return url;
    }
    
    public func getNetworkId() -> NetworkId {
        return networkId;
    }
    
    public func isMainNet() -> Bool {
        return networkId == NetworkId.mainNet;
    }
}
