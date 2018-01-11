//
//  ObservableType+NOKExtras.swift
//  KeychainAccess
//
//  Created by Bryan Lahartinger on 2018-01-11.
//

import Foundation
import RxSwift

// allow turning anything into a Completable ignoring all events
// Workaround to support flatmaping an Observable to a Completable
// ( which you can do with ignoreEvents() directly in RxSwift 4.x with swift 4 dep ).
public extension ObservableType {
    public func asCompletableIgnoringEvents() -> Completable {
        return self.ignoreElements()
            .map { _ in preconditionFailure() }
            .asCompletable()
    }
}
