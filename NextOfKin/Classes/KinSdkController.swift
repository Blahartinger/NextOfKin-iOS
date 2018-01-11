//
//  KinSdkController.swift
//  CashCow
//
//  Created by Bryan Lahartinger on 2017-12-11.
//  Copyright © 2017 Bryan Lahartinger. All rights reserved.
//

import Foundation
import RxSwift
import KeychainAccess
import KinSDK

public class KinSdkController: KinControllerType, KinRespositoryType {
    
    enum NOKError : Error {
        case kinSdkControllerDeallocated
    }
    
    private struct Constants {
        static let kinPasskeyKey: String = "com.kik.kin.passkey"
        static let keystoreKeyLength: UInt = 128
        static let configKinProviderUrl = "kin-provider-url"
        static let providerUrlOptions = ["http://mainnet.rounds.video:8545/",
                                         "http://testnet.rounds.video:8545/",
                                         "https://mainnet.infura.io/"]
        static let providerUrlNetworks = [NetworkId.mainNet,
                                          NetworkId.ropsten,
                                          NetworkId.truffle]
    }
    
    // Injectables
    private let keychain: Keychain
    private let defaults: UserDefaults
    
    private let account = BehaviorSubject<KinAccount?>(value: nil)
    private let disposeBag = DisposeBag()
    private let kinOperationScheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "com.kin.KinSdkController.KinOperationQueue")
    private var kinClient: KinClient!
    
    init(keychain: Keychain = Keychain(service: String(format: "%@.kinSdkController.keychain.key", Bundle.bundleName())),
         defaults: UserDefaults = UserDefaults.standard) {
        self.keychain = keychain
        self.defaults = defaults
        
        // MARK: forced on test network
        self.defaults.set(Constants.providerUrlOptions[1],
                          forKey: Constants.configKinProviderUrl)
        
        // load initial existence of an account
        getClient().subscribe(onSuccess: { [weak self] (client) in
            guard let this = self else {
                return
            }
            this.account.onNext(client.account);
        })
        .disposed(by: self.disposeBag)
    }
    
    private var providerUrl: String {
        guard let providerUrl: String = defaults.string(forKey: Constants.configKinProviderUrl) else {
            return "nok://undefined"
        }
        return providerUrl
    }
    
    /**
     * @return A service provider which connects to the chosen provider URL
     * on the correct protocol
     */
    private func getServiceProvider() -> ServiceProvider {
        
        var networkId = NetworkId.ropsten
        for i in 0..<Constants.providerUrlOptions.count {
            if Constants.providerUrlOptions[i] == providerUrl {
                networkId = Constants.providerUrlNetworks[i];
            }
        }
        
        return NOKServiceProvider(urlString: providerUrl, networkId: networkId)
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
                this.kinClient = try KinClient(provider: this.getServiceProvider())
                single(.success(this.kinClient))
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
                        .do(onNext: { (account) in
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
        return getClient().do(onNext: { [weak self] (client) in
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
