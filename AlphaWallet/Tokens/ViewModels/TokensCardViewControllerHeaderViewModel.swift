// Copyright © 2018 Stormbird PTE. LTD.

import UIKit
import BigInt

struct TokensCardViewControllerHeaderViewModel {
    private let tokenObject: TokenObject
    private let server: RPCServer

    init(tokenObject: TokenObject, server: RPCServer) {
        self.tokenObject = tokenObject
        self.server = server
    }

    var title: String {
        return "\((totalValidTokenCount)) \(tokenObject.title)"
    }

    var issuer: String {
        let xmlHandler = XMLHandler(contract: tokenObject.address.eip55String)
        let issuer = xmlHandler.getIssuer()
        if issuer.isEmpty {
            return ""
        } else {
            return "\(R.string.localizable.aWalletContentsIssuerTitle()): \(issuer)"
        }
    }

    var issuerSeparator: String {
        if issuer.isEmpty {
            return ""
        } else {
            return "|"
        }
    }

    var blockChainName: String {
        switch server {
        case .xDai:
            return R.string.localizable.blockchainXDAI()
        case .rinkeby, .ropsten, .main, .custom, .callisto, .classic, .kovan, .sokol, .poa:
            return R.string.localizable.blockchainEthereum()
        }
    }

    var backgroundColor: UIColor {
        return Colors.appWhite
    }

    var contentsBackgroundColor: UIColor {
        return Colors.appWhite
    }

    var titleColor: UIColor {
        return Colors.appText
    }

    var subtitleColor: UIColor {
        return Colors.appBackground
    }

    var titleFont: UIFont {
        return Fonts.light(size: 25)!
    }

    var subtitleFont: UIFont {
        return Fonts.semibold(size: 10)!
    }

    var totalValidTokenCount: String {
        let validTokens = tokenObject.nonZeroBalance
        return validTokens.count.toString()
    }
}
