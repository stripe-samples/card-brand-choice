//
//  CardBrandChoiceViewController.swift
//  app
//
//  Created by Yuki Tokuhiro on 9/25/19, Adapted by Leo Chen on 05/26/22.
//  Copyright © 2022 stripe-samples. All rights reserved.
//

import UIKit
import Stripe
import DropDown

/**
 * To run this app, you'll need to first run the sample server locally.
 * Follow the "How to run locally" instructions in the root directory's README.md to get started.
 * Once you've started the server, open http://localhost:4242 in your browser to check that the
 * server is running locally.
 * After verifying the sample server is running locally, build and run the app using the iOS simulator.
 */
let BackendUrl = "http://127.0.0.1:4242/"

class CardBrandChoiceViewController: UIViewController {
    var paymentIntentClientSecret: String?
    
    var cardBrand: String?
    
    lazy var cardHolderFullNameField: UITextField = {
        let cardHolderFullNameField = UITextField()
        cardHolderFullNameField.placeholder = "Full Name"
        cardHolderFullNameField.borderStyle = .roundedRect
        return cardHolderFullNameField
    }()
    
    lazy var cardTextField: STPPaymentCardTextField = {
        let cardTextField = STPPaymentCardTextField()
        cardTextField.addTarget(self, action: #selector(editingCardNumberTextFieldValueChanged), for: .valueChanged)
        
        return cardTextField
    }()
    
    lazy var cardBrandChoiceButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5
        button.backgroundColor = .clear
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.setTitle("Select Card Brand", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        // Show card brand dropdown when click the button
        button.addTarget(self, action: #selector(cardBrandChoiceDropdown), for: .touchUpInside)
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 0);
        return button
    }()

    lazy var payButton: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = 5
        button.backgroundColor = .systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        button.setTitle("Pay", for: .normal)
        button.addTarget(self, action: #selector(pay), for: .touchUpInside)
        return button
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let stackView = UIStackView(arrangedSubviews: [cardHolderFullNameField, cardTextField, cardBrandChoiceButton, payButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalToSystemSpacingAfter: view.leftAnchor, multiplier: 2),
            view.rightAnchor.constraint(equalToSystemSpacingAfter: stackView.rightAnchor, multiplier: 2),
            stackView.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 2),
        ])
        startCheckout()
    }
    
    @IBAction func cardBrandChoiceDropdown(_ sender: UIButton) {
        let dropDown = DropDown()
        let userFacingCardBrandNames = ["American Express", "Diners Club", "UnionPay", "Cartes Bancaires", "Discover", "JCB", "Mastercard", "Visa"]
        dropDown.dataSource = userFacingCardBrandNames
        dropDown.anchorView = sender
        dropDown.bottomOffset = CGPoint(x: 0, y: sender.frame.size.height)
        dropDown.show()
        dropDown.selectionAction = { [weak self] (index: Int, item: String) in
          guard let _ = self else { return }
        sender.setTitle(item, for: .normal)
        self?.cardBrand = CardBrandChoiceUtilities.toInternalCardBrandString(userFacingCardBrandName: item)
        }
      }
    
    @IBAction func editingCardNumberTextFieldValueChanged(_ sender: STPPaymentCardTextField) {
        let cardNumber = sender.cardNumber
        
        let brand = STPCardValidator.brand(forNumber: cardNumber ?? "")
        
        if brand != .unknown {
            let internalCardBrandStr = CardBrandChoiceUtilities.toInternalCardBrandString(brand: brand)
            let userFacingCardBrandStr = STPCardBrandUtilities.stringFrom(brand)
            cardBrandChoiceButton.setTitle(userFacingCardBrandStr, for: .normal)
            self.cardBrand = internalCardBrandStr
        }
    }
    
    func displayAlert(title: String, message: String, restartDemo: Bool = false) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            if restartDemo {
                alert.addAction(UIAlertAction(title: "Restart demo", style: .cancel) { _ in
                    self.cardTextField.clear()
                    self.cardHolderFullNameField.text = nil
                    self.cardBrand = nil
                    self.cardBrandChoiceButton.setTitle("Select Card Brand", for: .normal)
                    self.startCheckout()
                })
            }
            else {
                alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            }
            self.present(alert, animated: true, completion: nil)
        }
    }

    func startCheckout() {
        setStripePublishableKey()
        setPaymentIntentClientSecret()
    }
    
    func setStripePublishableKey() {
        let url = URL(string: BackendUrl + "config")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                let stripePublishableKey = json["publishableKey"] as? String else {
                    let message = error?.localizedDescription ?? "Failed to decode response from server."
                    self?.displayAlert(title: "Error loading page", message: message)
                    return
            }
            StripeAPI.defaultPublishableKey = stripePublishableKey
        })
        task.resume()
    }
    
    func setPaymentIntentClientSecret(){
        // Create a PaymentIntent by calling the sample server's /create-payment-intent endpoint.
        let url = URL(string: BackendUrl + "create-payment-intent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                  let clientSecret = json["clientSecret"] as? String else {
                    let message = error?.localizedDescription ?? "Failed to decode response from server."
                    self?.displayAlert(title: "Error loading page", message: message)
                    return
            }
            self?.paymentIntentClientSecret = clientSecret
        })
        task.resume()
    }
    @objc
    func pay(sender: UIButton) {
        guard let paymentIntentClientSecret = paymentIntentClientSecret else {
            return;
        }
        
        sender.setTitle("Paying...", for: UIControl.State.normal)
        sender.isEnabled = false
        
        // Collect card details
        let cardParams = cardTextField.cardParams
        
    
        // Collect the customer's full name to know which customer the PaymentMethod belongs to.
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = cardHolderFullNameField.text
        
        // Create PaymentIntent confirm parameters with the above
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: billingDetails, metadata: nil)
        
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)

        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        if cardBrand != nil {
            let confirmCardOptions = STPConfirmCardOptions()
            let confirmPaymentMethodOptions = STPConfirmPaymentMethodOptions()
            confirmCardOptions.network = cardBrand
            confirmPaymentMethodOptions.cardOptions = confirmCardOptions
            paymentIntentParams.paymentMethodOptions = confirmPaymentMethodOptions
        }
        
        // Complete the payment
        let paymentHandler = STPPaymentHandler.shared()
        paymentHandler.confirmPayment(paymentIntentParams, with: self) { status, paymentIntent, error in
            switch (status) {
            case .failed:
                self.displayAlert(title: "Payment failed", message: error?.debugDescription ?? "")
                break
            case .canceled:
                self.displayAlert(title: "Payment canceled", message: error?.localizedDescription ?? "")
                break
            case .succeeded:
                self.displayAlert(title: "Payment succeeded", message: paymentIntent?.description ?? "", restartDemo: true)
                break
            @unknown default:
                fatalError()
                break
            }
            sender.setTitle("Pay", for: .normal)
            sender.isEnabled = true
        }
    }
}

extension CardBrandChoiceViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
}

