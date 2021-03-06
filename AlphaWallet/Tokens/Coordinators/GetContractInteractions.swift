//
// Created by James Sangalli on 6/6/18.
// Copyright © 2018 Stormbird PTE. LTD.
//

import Foundation
import Alamofire
import SwiftyJSON

class GetContractInteractions {
    //This function only gets a list of contracts you have transacted with
    //if you have not transacted with the contract then it will not show up
    //there is currently no efficient way to get all your tokens but it might be for the best
    //as people spam via sending tokens
    func getContractList(address: String, chainId: Int, completion: @escaping ([String]) -> Void) {
        let etherscanURL = RPCServer(chainID: chainId).etherscanAPIURLForTransactionList(for: address)
        Alamofire.request(etherscanURL).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let contracts: [String] = json["result"].map { _, transactionJson in
                    if transactionJson["input"] != "0x" {
                        //every transaction that has input is by default a transaction to a contract
                        if transactionJson["contractAddress"].description == "" {
                            return transactionJson["to"].description
                        } else {
                            return transactionJson["contractAddress"].description
                        }
                    }
                    return ""
                }
                let nonEmptyContracts = contracts.filter { !$0.isEmpty }
                let uniqueNonEmptyContracts = Array(Set(nonEmptyContracts))
                completion(uniqueNonEmptyContracts)
            case .failure(let error):
                print(error)
                completion([])
            }
        }
    }
}
