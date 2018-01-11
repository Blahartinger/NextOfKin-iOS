//
//  NSBundle+NOKExtras.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-11.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation

extension Bundle {
    static  func mainInfoDictionary(key: CFString) -> String? {
        return self.main.infoDictionary?[key as String] as? String
    }
    
    static func bundleName() -> String {
        guard let bundleName = Bundle.mainInfoDictionary(key: kCFBundleNameKey) else {
            return "(Undefined)"
        }
        return bundleName
    }
}
