//
// Created by James Sangalli on 8/3/18.
//

import Foundation
import XCTest
@testable import AlphaWallet
import BigInt
import TrustKeystore

class ClaimOrderCoordinatorTests: XCTestCase {

    var expectations = [XCTestExpectation]()

    func testClaimOrder() {
        let keystore = try! EtherKeystore()
        let claimOrderCoordinator = FakeClaimOrderCoordinator()
        let expectation = self.expectation(description: "wait til callback")
        expectations.append(expectation)
        var indices = [UInt16]()
        indices.append(14)
        let expiry = BigUInt("0")
        let v = UInt8(27)
        let r = "0x2d8e40406bf6175036ab1e1099b48590438bf48d429a8b209120fecd07894566"
        let s = "0x59ccf58ca36f681976228309fdd9de7e30e860084d9d63014fa79d48a25bb93d"

        let token = TokenObject(
            contract: "0xacDe9017473D7dC82ACFd0da601E4de291a7d6b0",
            name: "MJ Comeback",
            symbol: "MJC",
            decimals: 0,
            value: "0",
            isCustom: true,
            isDisabled: false,
            type: .erc875
        )
        
        let order = Order(price: BigUInt(0),
                          indices: indices,
                          expiry: expiry!,
                          contractAddress: token.contract,
                          count: 1,
                          nonce: BigUInt(0),
                          tokenIds: [BigUInt](),
                          spawnable: false,
                          nativeCurrencyDrop: false
        )
        
        let signedOrder = SignedOrder(order: order, message: [UInt8](), signature: "")

        claimOrderCoordinator.claimOrder(signedOrder: signedOrder, expiry: expiry!, v: v, r: r, s: s, contractAddress: order.contractAddress, recipient: "0xacDe9017473D7dC82ACFd0da601E4de291a7d6b0") { result in
            switch result {
            case .success(let payload):
                let address: Address = .makeStormBird()
                let transaction = UnconfirmedTransaction(
                    transferType: .ERC875TokenOrder(token),
                    value: BigInt("0"),
                    to: address,
                    data: Data(bytes: payload.hexa2Bytes),
                    gasLimit: .none,
                    tokenId: Constants.nullTokenId,
                    gasPrice: 200000,
                    nonce: .none,
                    v: v,
                    r: r,
                    s: s,
                    expiry: expiry,
                    indices: indices,
                    tokenIds: [BigUInt]()
                )

                let session: WalletSession = .makeStormBirdSession()

                let configurator = TransactionConfigurator(
                    session: session,
                    account: .make(),
                    transaction: transaction
                )

                let unsignedTransaction = configurator.formUnsignedTransaction()

                let account = keystore.createAccount(password: "test")

                let _ = UnsignedTransaction(value: unsignedTransaction.value,
                                                        account: account,
                                                        to: unsignedTransaction.to,
                                                        nonce: unsignedTransaction.nonce,
                                                        data: unsignedTransaction.data,
                                                        gasPrice: unsignedTransaction.gasPrice,
                                                        gasLimit: unsignedTransaction.gasLimit,
                                                        chainID: 3)
                
                let _ = SendTransactionCoordinator(session: session,
                                                                            keystore: keystore,
                                                                            confirmType: .signThenSend)
                keystore.delete(wallet: Wallet(type: WalletType.real(account)))
                expectation.fulfill()

            case .failure: break
            }
        }
        wait(for: expectations, timeout: 10)
    }
    
}
