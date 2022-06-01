//
//  Utilities.swift
//  CardBrandChoice
//
//  Created by Leo Chen on 5/24/22.
//  Copyright © 2022 stripe. All rights reserved.
//

import Foundation
import Stripe

public class CardBrandChoiceUtilities: NSObject {
    /// This utility function is derived from STPCardBrandUtilities.stringFrom()
    /// The reason to not use STPCardBrandUtilities.stringFrom to convert brand enum to string is because  that STPCardBrandUtilities.stringFrom() returns a UI-friendly string representation rather than the internal brand code.
    /// Internal brand name is needed when hitting Stripe API
    /// The supported brand names in Stripe API are listed here https://stripe.com/docs/api/payment_methods/object#payment_method_object-card-brand.
    /// i.e. `CardBrandChoiceUtilities.toInternalCardBrandString(brand: .dinersClub) == "diners"`.
    /// - Parameter brand: the brand you want to convert to a string
    /// - Returns: A string representing the brand, suitable for displaying to a user.
    public static func toInternalCardBrandString(brand: STPCardBrand) -> String? {
        switch brand {
        case .amex:
            return "amex"
        case .dinersClub:
            return "diners"
        case .discover:
            return "discover"
        case .JCB:
            return "jcb"
        case .mastercard:
            return "mastercard"
        case .unionPay:
            return "unionpay"
        case .visa:
            return "visa"
        case .unknown:
            return "Unknown"
        }
    }
    
    public static func toInternalCardBrandString(userFacingCardBrandName: String) -> String? {
        switch userFacingCardBrandName {
        case "American Express":
            return "amex"
        case "Diners Club":
            return "diners"
        case "Discover":
            return "discover"
        case "JCB":
            return "jcb"
        case "Mastercard":
            return "mastercard"
        case "UnionPay":
            return "unionpay"
        case "Visa":
            return "visa"
        case "Cartes Bancaires":
            return "cartes_bancaires"
        default:
            return "Unknown"
        }
    }

}
