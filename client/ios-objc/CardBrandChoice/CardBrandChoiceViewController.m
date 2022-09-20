//
//  CheckoutViewController.m
//  app
//
//  Created by Ben Guo on 9/29/19, adapted by Nina Becx & Kevin Yang on 5/20/22.
//  Copyright © 2022 stripe-samples. All rights reserved.
//

#import "CardBrandChoiceViewController.h"
#import "DownPicker.h"
@import Stripe;

/**
* To run this app, you'll need to first run the sample server locally.
* Follow the "How to run locally" instructions in the root directory's README.md to get started.
* Once you've started the server, open http://localhost:4242 in your browser to check that the
* server is running locally.
* After verifying the sample server is running locally, build and run the app using the iOS simulator.
*/
NSString *const BackendUrl = @"http://127.0.0.1:4242/";

@interface CardBrandChoiceViewController ()

@property (nonatomic, weak) STPPaymentCardTextField *cardTextField;
@property (nonatomic, weak) UIButton *payButton;
@property (nonatomic, copy) NSString *paymentIntentClientSecret;
@property (nonatomic, weak) UITextField *dropdownTextField;
@property (strong, nonatomic) DownPicker *downPicker;

@end

@implementation CardBrandChoiceViewController

// Construct UI
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    // Card Form
    STPPaymentCardTextField *cardTextField = [[STPPaymentCardTextField alloc] init];
    self.cardTextField = cardTextField;
    [self.cardTextField addTarget:self action:@selector(onCardNumberChange) forControlEvents:UIControlEventValueChanged];

    // Dropdown
    UITextField *dropdownTextField = [[UITextField alloc] initWithFrame:CGRectMake(10, 200, 300, 40)];
    dropdownTextField.borderStyle = UITextBorderStyleRoundedRect;
    dropdownTextField.font = [UIFont systemFontOfSize:15];
    dropdownTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    dropdownTextField.keyboardType = UIKeyboardTypeDefault;
    dropdownTextField.returnKeyType = UIReturnKeyDone;
    dropdownTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    dropdownTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.dropdownTextField = dropdownTextField;

    self.downPicker = [[DownPicker alloc] initWithTextField:dropdownTextField withData:[[self brandMap] allKeys]];
    [self.downPicker setPlaceholder:@"Please Select a Card Brand"];

    // Pay Button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 5;
    button.backgroundColor = [UIColor systemBlueColor];
    button.titleLabel.font = [UIFont systemFontOfSize:22];
    [button setTitle:@"Pay" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(pay) forControlEvents:UIControlEventTouchUpInside];
    self.payButton = button;

    // Render all components
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[cardTextField, dropdownTextField, button]];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.spacing = 20;
    [self.view addSubview:stackView];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.leftAnchor constraintEqualToSystemSpacingAfterAnchor:self.view.leftAnchor multiplier:2],
        [self.view.rightAnchor constraintEqualToSystemSpacingAfterAnchor:stackView.rightAnchor multiplier:2],
        [stackView.topAnchor constraintEqualToSystemSpacingBelowAnchor:self.view.topAnchor multiplier:2],
    ]];

    [self startCheckout];
}

// Mapping of brand external id to internal id
- (NSDictionary<NSString *, NSString *> *)brandMap {
    NSDictionary<NSString *, NSString *> *map = @{
        @"Visa" : @"visa",
        @"Mastercard" : @"mastercard",
        @"American Express" : @"amex",
        @"Discover" : @"discover",
        @"Diners Club" : @"diners",
        @"JCB" : @"jcb",
        @"UnionPay" : @"unionpay",
        @"Cartes Bancaires" : @"cartes_bancaires",
    };

    return map;
}

// Handler for observing the Card Number input field
- (void)onCardNumberChange {
    STPCardBrand brand = [STPCardValidator brandForNumber:self.cardTextField.cardNumber];
    NSString *brandString = [STPCardBrandUtilities stringFromCardBrand:brand];

    if (brandString != nil) {
        self.dropdownTextField.text = brandString;
    }
}

- (void)displayAlertWithTitle:(NSString *)title message:(NSString *)message restartDemo:(BOOL)restartDemo {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        if (restartDemo) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Restart demo" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                self.dropdownTextField.text = nil;
                [self.cardTextField clear];

                [self startCheckout];
            }]];
        }
        else {
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        }
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)fetchPublishableKey {
    // Fetch publishable key by calling the sample server's /config endpoint.
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@config", BackendUrl]];
    NSMutableURLRequest *request = [[NSURLRequest requestWithURL:url] mutableCopy];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *requestError) {
        NSError *error = requestError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error != nil || httpResponse.statusCode != 200 || json[@"publishableKey"] == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = error.localizedDescription ?: @"";
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error loading page" message:message preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
        else {
            NSString *stripePublishableKey = json[@"publishableKey"];
            // Configure the SDK with your Stripe publishable key so that it can make requests to the Stripe API
            [StripeAPI setDefaultPublishableKey:stripePublishableKey];
        }
    }];
    [task resume];
}

- (void)startCheckout {
    [self fetchPublishableKey];
    // Create a PaymentIntent by calling the sample server's /create-payment-intent endpoint.
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@create-payment-intent", BackendUrl]];
    NSMutableURLRequest *request = [[NSURLRequest requestWithURL:url] mutableCopy];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *jsonBodyDict = @{};
    NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:jsonBodyDict options:kNilOptions error:nil];

    [request setHTTPBody:jsonBodyData];

    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *requestError) {
        NSError *error = requestError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error != nil || httpResponse.statusCode != 200 || json[@"clientSecret"] == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *message = error.localizedDescription ?: @"";
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error loading page" message:message preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
        else {
            self.paymentIntentClientSecret = json[@"clientSecret"];
        }
    }];
    [task resume];
}

- (void)pay {
    if (!self.paymentIntentClientSecret) {
        NSLog(@"PaymentIntent hasn't been created");
        return;
    }

    [self.payButton setTitle:@"Paying..." forState:UIControlStateNormal];
    self.payButton.enabled = NO;
    
    // Set customer details
    STPPaymentMethodBillingDetails *billingDetails = [[STPPaymentMethodBillingDetails alloc] init];
    billingDetails.name = @"Jenny Rosen";

    // Collect card details on the client
    STPPaymentMethodCardParams *cardParams = self.cardTextField.cardParams;
    STPPaymentMethodParams *paymentMethodParams = [STPPaymentMethodParams paramsWithCard:cardParams billingDetails:billingDetails metadata:nil];
    STPPaymentIntentParams *paymentIntentParams = [[STPPaymentIntentParams alloc] initWithClientSecret:self.paymentIntentClientSecret];

    [[STPAPIClient sharedClient] createPaymentMethodWithParams:paymentMethodParams completion:^(STPPaymentMethod *paymentMethod, NSError *handleActionError) {
        if (paymentMethod) {
            NSArray *availableNetworks = paymentMethod.card.networks.available;
            NSString *network = [self brandMap][self.dropdownTextField.text];
            if ([availableNetworks containsObject:network]) {
                STPConfirmCardOptions *cardOptions = [[STPConfirmCardOptions alloc] init];
                STPConfirmPaymentMethodOptions *paymentMethodOptions = [[STPConfirmPaymentMethodOptions alloc] init];
                cardOptions.network = network;
                paymentMethodOptions.cardOptions = cardOptions;
                paymentIntentParams.paymentMethodOptions = paymentMethodOptions;
            }
            paymentIntentParams.paymentMethodId = paymentMethod.stripeId;
            [self confirmPayment:paymentIntentParams];
            return;
        }
        // For demo purposes, we expose the descriptive error message from the Stripe API
        [self displayAlertWithTitle:@"Payment method creation failed" message:handleActionError.userInfo[@"com.stripe.lib:ErrorMessageKey"] ?: @"" restartDemo:NO];
        [self.payButton setTitle:@"Pay" forState:UIControlStateNormal];
        self.payButton.enabled = YES;
    }];
}

- (void)confirmPayment:(STPPaymentIntentParams *)paymentIntentParams {
    // Complete the payment
    STPPaymentHandler *paymentHandler = [STPPaymentHandler sharedHandler];
    [paymentHandler confirmPayment:paymentIntentParams withAuthenticationContext:self completion:^(STPPaymentHandlerActionStatus status, STPPaymentIntent *paymentIntent, NSError *handleActionError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case STPPaymentHandlerActionStatusFailed: {
                    // For demo purposes, we expose the descriptive error message from the Stripe API
                    [self displayAlertWithTitle:@"Payment failed" message:handleActionError.userInfo[@"com.stripe.lib:ErrorMessageKey"] ?: @"" restartDemo:NO];
                    break;
                }
                case STPPaymentHandlerActionStatusCanceled: {
                    [self displayAlertWithTitle:@"Payment canceled" message:handleActionError.localizedDescription ?: @"" restartDemo:NO];
                    break;
                }
                case STPPaymentHandlerActionStatusSucceeded: {
                    [self displayAlertWithTitle:@"Payment succeeded" message:paymentIntent.description restartDemo:YES];
                    break;
                }
                default:
                    break;
            }

            [self.payButton setTitle:@"Pay" forState:UIControlStateNormal];
            self.payButton.enabled = YES;
        });
    }];
}

# pragma mark STPAuthenticationContext
- (UIViewController *)authenticationPresentingViewController {
    return self;
}

@end
