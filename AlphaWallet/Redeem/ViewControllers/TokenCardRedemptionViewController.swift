//
//  TokenCardRedemptionViewController.swift
//  Alpha-Wallet
//
//  Created by Oguzhan Gungor on 3/6/18.
//  Copyright © 2018 Alpha-Wallet. All rights reserved.
//

import UIKit

protocol TokenCardRedemptionViewControllerDelegate: class, CanOpenURL {
}

class TokenCardRedemptionViewController: UIViewController, TokenVerifiableStatusViewController {
    private var viewModel: TokenCardRedemptionViewModel
    private var titleLabel = UILabel()
    private let imageView =  UIImageView()
    private let tokenRowView: TokenRowView & UIView
    private var timer: Timer!
    private var session: WalletSession
    private let token: TokenObject
    private let redeemListener = RedeemEventListener()

    let config: Config
    var contract: String {
        return token.contract
    }
    weak var delegate: TokenCardRedemptionViewControllerDelegate?

    init(config: Config, session: WalletSession, token: TokenObject, viewModel: TokenCardRedemptionViewModel) {
        self.config = config
		self.session = session
        self.token = token
        self.viewModel = viewModel

        let tokenType = OpenSeaNonFungibleTokenHandling(token: token)
        switch tokenType {
        case .supportedByOpenSea:
            tokenRowView = OpenSeaNonFungibleTokenCardRowView()
        case .notSupportedByOpenSea:
            tokenRowView = TokenCardRowView()
        }

        super.init(nibName: nil, bundle: nil)

        updateNavigationRightBarButtons(isVerified: true)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        imageView.translatesAutoresizingMaskIntoConstraints = false

        let imageHolder = UIView()
        imageHolder.translatesAutoresizingMaskIntoConstraints = false
        imageHolder.backgroundColor = Colors.appWhite
        imageHolder.cornerRadius = 20
        imageHolder.addSubview(imageView)

        tokenRowView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = [
            titleLabel,
            .spacer(height: 10),
            imageHolder,
            .spacer(height: 4),
            tokenRowView,
        ].asStackView(axis: .vertical, alignment: .center)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            imageView.leadingAnchor.constraint(equalTo: imageHolder.leadingAnchor, constant: 70),
            imageView.trailingAnchor.constraint(equalTo: imageHolder.trailingAnchor, constant: -70),
            imageView.topAnchor.constraint(equalTo: imageHolder.topAnchor, constant: 70),
            imageView.bottomAnchor.constraint(equalTo: imageHolder.bottomAnchor, constant: -70),

            imageHolder.leadingAnchor.constraint(equalTo: tokenRowView.background.leadingAnchor),
            imageHolder.trailingAnchor.constraint(equalTo: tokenRowView.background.trailingAnchor),
			imageHolder.widthAnchor.constraint(equalTo: imageHolder.heightAnchor),

            tokenRowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tokenRowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override
    func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(timeInterval: 30,
                                     target: self,
                                     selector: #selector(configureUI),
                                     userInfo: nil,
                                     repeats: true)
        redeemListener.shouldListen = true
        redeemListener.start(for: session.account.address,
                             completion: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.redeemListener.stop()
            strongSelf.showSuccessMessage()
        })
    }

    override
    func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        invalidateTimer()
        redeemListener.stop()
    }

    @objc
    private func configureUI() {
        let redeem = CreateRedeem(config: session.config, token: token)
        let redeemData = redeem.redeemMessage(tokenIndices: viewModel.tokenHolder.indices)
        switch session.account.type {
        case .real(let account):
            let decimalSignature = SignatureHelper.signatureAsDecimal(for: redeemData.message, account: account)!
            let qrCodeInfo = redeemData.qrCode + decimalSignature
            imageView.image = qrCodeInfo.toQRCode()
        case .watch: break
        }
    }

    func showInfo() {
        let controller = TokenCardRedemptionInfoViewController(delegate: self)
        navigationController?.pushViewController(controller, animated: true)
    }

    func showContractWebPage() {
        delegate?.didPressViewContractWebPage(forContract: viewModel.token.contract, in: self)
    }

    private func showSuccessMessage() {
        invalidateTimer()

        let tokenTypeName = XMLHandler(contract: contract).getTokenTypeName()
        UIAlertController.alert(title: R.string.localizable.aWalletTokenRedeemSuccessfulTitle(),
                                message: R.string.localizable.aWalletTokenRedeemSuccessfulDescription(tokenTypeName),
                                alertButtonTitles: [R.string.localizable.oK()],
                                alertButtonStyles: [.cancel],
                                viewController: self,
                                completion: { [weak self] _ in
                                    guard let strongSelf = self else { return }
                                    // TODO: let token coordinator handle this as we need to refresh the token list as well
                                    strongSelf.dismiss(animated: true, completion: nil)
                                })

    }

    private func invalidateTimer() {
        if timer.isValid {
            timer.invalidate()
        }
    }
    
    func configure(viewModel newViewModel: TokenCardRedemptionViewModel? = nil) {
        if let newViewModel = newViewModel {
            viewModel = newViewModel
        }
        updateNavigationRightBarButtons(isVerified: isContractVerified)

        view.backgroundColor = viewModel.backgroundColor

        titleLabel.textAlignment = .center
        titleLabel.textColor = viewModel.headerColor
        titleLabel.font = viewModel.headerFont
        titleLabel.numberOfLines = 0
        titleLabel.text = viewModel.headerTitle

        configureUI()

        tokenRowView.configure(tokenHolder: viewModel.tokenHolder)

        tokenRowView.stateLabel.isHidden = true
    }
 }

extension TokenCardRedemptionViewController: StaticHTMLViewControllerDelegate {
}

extension TokenCardRedemptionViewController: CanOpenURL {
    func didPressViewContractWebPage(forContract contract: String, in viewController: UIViewController) {
        delegate?.didPressViewContractWebPage(forContract: contract, in: viewController)
    }

    func didPressViewContractWebPage(_ url: URL, in viewController: UIViewController) {
        delegate?.didPressViewContractWebPage(url, in: viewController)
    }

    func didPressOpenWebPage(_ url: URL, in viewController: UIViewController) {
        delegate?.didPressOpenWebPage(url, in: viewController)
    }
}
