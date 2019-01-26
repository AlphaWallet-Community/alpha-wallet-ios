//
// Created by James Sangalli on 26/1/19.
//

import Foundation
import BigInt

struct claimXDAIOrder: Web3Request {

    typealias Response = String
    let address: String
    let contractAddress: String
    let nonce: BigUInt
    let expiry: BigUInt
    let amount: BigUInt //in full ether units
    let v: String
    let r: String
    let s: String
    let receiver: String

    var type: Web3RequestType {
        let abi = "{ \"constant\": false, \"inputs\": [{ \"name\": \"nonce\", \"type\": \"uint256\" }, { \"name\": \"amount\", \"type\": \"uint256\" }, { \"name\": \"expiry\", \"type\": \"uint256\" }, { \"name\": \"v\", \"type\": \"uint8\" }, { \"name\": \"r\", \"type\": \"bytes32\" }, { \"name\": \"s\", \"type\": \"bytes32\" }, { \"name\": \"reciever\", \"type\": \"address\" } ], \"name\": \"dropDai\", \"outputs\": [], \"payable\": false, \"stateMutability\": \"nonpayable\", \"type\": \"function\" }, [\"\(nonce)\", \"\(amount)\", \"\(expiry)\", \"\(v)\", \"\(r)\", \"\(s)\", \"\(receiver)\" ]"
        let run = "web3.eth.abi.encodeFunctionCall(" + abi + ")"
        return .script(command: run)
    }

}
