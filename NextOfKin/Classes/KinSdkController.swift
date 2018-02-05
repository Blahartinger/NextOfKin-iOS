//
//  KinSdkController.swift
//  NextOfKin
//
//  Created by Bryan Lahartinger on 2017-12-11.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation
import RxSwift
import KeychainAccess
import KinSDK

public class KinSdkController: KinControllerType, KinRespositoryType {

    typealias ProviderTuple = (url: String, network: NetworkId)
    
    enum NOKError : Error {
        case kinSdkControllerDeallocated
    }
    
    private struct Constants {
        static let kinPasskeyKey: String = "com.kik.kin.passkey"
        static let keystoreKeyLength: UInt = 128

        static let mainNet: ProviderTuple = ("http://mainnet.rounds.video:8545/", .mainNet)
        static let testNet: ProviderTuple = ("http://testnet.rounds.video:8545/", .ropsten)
        static let truffleNet: ProviderTuple = ("https://mainnet.infura.io/", .truffle) // TODO: James - switch local tests to this
    }

    private lazy var account = BehaviorSubject<KinAccount?>(value: nil)
    private lazy var disposeBag = DisposeBag()
    private lazy var kinOperationScheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "com.kin.KinSdkController.KinOperationQueue")

    private let keychain: Keychain
    private let serviceProvider: NOKServiceProvider

    public convenience init(usingTestNet: Bool = true) {
        let keychain = Keychain(service: String(format: "%@.kinSdkController.keychain.key", Bundle.bundleName()))
        self.init(keychain: keychain,
                  usingTestNet: usingTestNet)
    }

    public required init(keychain: Keychain, usingTestNet: Bool = true) {
        self.keychain = keychain
        
        if usingTestNet {
            self.serviceProvider = NOKServiceProvider(urlString: Constants.testNet.url,
                                                      networkId: Constants.testNet.network)
        } else {
            self.serviceProvider = NOKServiceProvider(urlString: Constants.mainNet.url,
                                                      networkId: Constants.mainNet.network)
        }
        
        // load initial existence of an account
        getClient().subscribe(onSuccess: { [weak self] (client) in
            guard let this = self else {
                return
            }
            this.account.onNext(client.account);
        }).disposed(by: self.disposeBag)
    }

    /**
     * @return The current provider Url used to access the kin network
     */
    public var providerUrl: String {
        return serviceProvider.url.description
    }

    /**
     * @return If the provided URL is approved to access the Kin SDK
     */
    public func isAllowedAccess(with url: URL) -> Bool {

        // Where was this being set anyways?
//        guard defaults.bool(forKey: Constants.isKinWalletRestricted) else { // TODO: Should "restricted" not be the default case?
//            // allow all domains to pass the check
//            return true
//        }

        // only allow the current wallet site, served over HTTPS to access restricted plugin methods
        let isValidHost = url.host == providerUrl
        let isValidScheme = url.scheme?.lowercased() == "https"

        return isValidHost && isValidScheme
    }

    /**
     * @return A stored passkey or generates a new, random passkey for single-session storage
     *
     * The Kin passkey is a 1024 bit random key which is unique per install. When the user
     * logs out, the wallet is unrecoverable. In the future, a user-derived key may be used
     * in place of the random key to allow the user to recover their wallet in certain
     * scenarios
     */
    private func getPassKey() -> String {
        
        guard let storedPasskey = keychain[Constants.kinPasskeyKey] else {
            let keyData = NSData.randomData(withLength: Constants.keystoreKeyLength)
            let generatedKey = keyData.base64EncodedString()
            keychain[Constants.kinPasskeyKey] = generatedKey
            return generatedKey
        }
        
        return storedPasskey
    }
    
    private func getClient() -> Single<KinClient> {
        return Single<KinClient>.create(subscribe: { [weak self] (single) -> Disposable in
            guard let this = self else {
                single(.error(NOKError.kinSdkControllerDeallocated))
                return Disposables.create()
            }
            do {
                let kinClient = try KinClient(provider: this.serviceProvider)
                single(.success(kinClient))
            } catch {
                single(.error(error))
            }
            return Disposables.create()
        })
        .subscribeOn(kinOperationScheduler)
        .observeOn(kinOperationScheduler)
    }
    
    /**
     * Returns a stream of account changes. This method will not force an account to be created,
     * it only observes all account changes. All account operations will be executed on
     * the Kin operation scheduler
     * @return
     */
    private func getAccount() -> Observable<KinAccount?> {
        return account
            .asObservable()
            .subscribeOn(kinOperationScheduler)
            .observeOn(kinOperationScheduler);
    }
    
    /**
     * Fetches the current account. If an account has not already been created,
     * a new account will be created with the correct passkey
     * @return A single with the existing or a new account if none exists
     */
    private func requireAccount() -> Single<KinAccount>  {
        return getAccount()
            .take(1)
            .asSingle()
            .flatMap({ [weak self] (accountOptional) -> Single<KinAccount> in
                guard let this = self else {
                    return Single.error(NOKError.kinSdkControllerDeallocated)
                }
                guard let account = accountOptional else {
                    return this.getOrCreateAccount()
                        .do(onSuccess: { (account) in
                            this.account.onNext(account)
                        })
                }
                
                return Single.just(account);
            });
    }
    
    private func getOrCreateAccount() -> Single<KinAccount> {
        return getClient()
            .flatMap({ [weak self] client in
                guard let this = self else {
                     return Single.error(NOKError.kinSdkControllerDeallocated)
                }
                // if no account is available
                guard let account = client.account else {
                    do {
                        // create a new account
                        return try Single.just(client.createAccountIfNeeded(with: this.getPassKey()))
                    } catch {
                        do {
                            // wipe out they existing keystore if we fail to access the existing keystore
                            try client.deleteKeystore()
                        } catch {
                            // ignored
                        }
                        
                        // retry account creation if we were unable to access the existing account
                        return try Single.just(client.createAccountIfNeeded(with: this.getPassKey()))
                    }
                }
            
                // return the existing account
                return Single.just(account)
            });
    }
    
    public func clearWallet() -> Completable {
        return getClient().do(onSuccess: { [weak self] (client) in
            try client.deleteKeystore()
            guard let this = self else {
                return
            }
            this.account.onNext(nil)
        })
        .asObservable().ignoreElements()
        //^ Make a completable, we don't care about the value
        //  and RxSwift can't map to a Single directly :/
    }

    public func sendKin(recipient: String, amount: NSDecimalNumber) -> Single<String> {
        return getAccount()
            .take(1)
            .asSingle()
            .map({ [weak self] account in
                guard let this = self, let account = account else {
                    // Transaction can't proceed, we're probably deallocated
                    return ""
                }
                return try account.sendTransaction(to: recipient,
                                                   kin: amount.uint64Value,
                                                   passphrase: this.getPassKey())
            });
    }

    public func exportKeyStore(passphrase: String) -> Single<String> {
        return getClient().map({ [weak self] (client) in
            guard let this = self else {
                // Can't proceed, we're probably deallocated
                return ""
            }
            return try client.account?.exportKeyStore(passphrase: this.getPassKey(), exportPassphrase: passphrase) ?? ""
        })
    }

    public func getBalance() -> Single<NSDecimalNumber> {
        return requireAccount()
            .map({ (account) -> NSDecimalNumber in
                return (try account.balance() as NSDecimalNumber)
            })
    }

    public func getPendingBalance() -> Single<NSDecimalNumber> {
        return requireAccount()
            .map({ (account) -> NSDecimalNumber in
                return (try account.pendingBalance() as NSDecimalNumber)
            })
    }

    public func isWalletAvailable() -> Observable<Bool> {
        return getAccount().map({ (accountOptional) -> Bool in
            guard accountOptional != nil else {
                return false
            }
            return true
        })
    }

    public func getPublicAddress() -> Observable<String?> {
        return requireAccount()
            .map({ (account) -> String? in
                return account.publicAddress
            }).asObservable()
    }
}
