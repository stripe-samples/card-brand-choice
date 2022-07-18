# Supporting Card Brand Choice with Elements

## What is card brand choice?

Since June 2016, EU regulation mandates merchants and acquirers to follow consumers card brand choice for payments made with co-badged cards (e.g., card branded both with Visa/MC and a local scheme such as Cartes Bancaires). In practice, this means that merchants must enable consumers to select their preferred brand in a payment form. Merchants can set a default brand choice as long as they give consumers the option to change that choice.

## How does Stripe help your business stay compliant?

The PaymentIntents API enables merchants to follow a customer’s preferred card brand choice if specified. If a preferred choice is not specified by the customer, you instruct us to select one based on optimizing for authorization rate.

## Stripe Elements and SDKs

To be compliant, you should modify your checkout form to include a way for customers to specify their preferred brand. This is currently not included in Elements and SDKs so you will need to create this component yourself.

## Sample clients

This repository contains the Card Brand Choice client sample code written in:
- [HTML+JS](client/html)
- [Android Kotlin](client/android-kotlin)
- [Android Java](client/android-java)
- [IOS Swift](client/ios-swift)
- [IOS Objective-C](client/ios-objc)

Go to the corresponding folder and follow the instruction in the README.md within the folder to run the client code.

## Web Demo

The demo is running in test mode. Use the following test card numbers with any CVC + future expiration date:

* Visa: `4242 4242 4242 4242`
* Mastercard: `5555 5555 5555 4444`
* Cartes Bancaires/Visa: `4000 0025 0000 1001`
* Cartes Bancaires/Mastercard: `5555 5525 0000 1001`

<img src="./card-brand-choice-sample.gif" alt="Preview of sample" align="center">

This sample demonstrates how you can

* Prompt your customer to select a card brand
* Dynamically update the card brand selection using the CardElement's `onChange` event
* Select the card brand when using `confirmCardPayment`

## How to run server locally

This sample includes 5 server implementations in Node, Ruby, Python, Java, and PHP.

Follow the steps below to run locally.

**1. Clone and configure the sample**

The Stripe CLI is the fastest way to clone and configure a sample to run locally.

**Using the Stripe CLI**

If you haven't already installed the CLI, follow the [installation steps](https://github.com/stripe/stripe-cli#installation) in the project README. The CLI is useful for cloning samples and locally testing webhooks and Stripe integrations.

In your terminal shell, run the Stripe CLI command to clone the sample:

```
stripe samples create card-brand-choice
```

The CLI will walk you through picking your integration type, server and client languages, and configuring your .env config file with your Stripe API keys.

**Installing and cloning manually**

If you do not want to use the Stripe CLI, you can manually clone and configure the sample yourself:

```
git clone https://github.com/stripe-samples/card-brand-choice
```

Copy the .env.example file into a file named .env in the folder of the server you want to use. For example:

```
cp .env.example server/node/.env
```

You will need a Stripe account in order to run the demo. Once you set up your account, go to the Stripe [developer dashboard](https://stripe.com/docs/development/quickstart#api-keys) to find your API keys.

```
STRIPE_PUBLISHABLE_KEY=<replace-with-your-publishable-key>
STRIPE_SECRET_KEY=<replace-with-your-secret-key>
```

`STATIC_DIR` tells the server where the client files are located and should be modified to match the client you wish to run.

For example, to let the HTML+JS client work in this approach, `STATIC_DIR` should be set to `../../client/html`

**2. Follow the server instructions on how to run:**

Pick the server language you want and follow the instructions in the server folder README on how to run.

For example, if you want to run the Node server:

```
cd server/node # there's a README in this folder with instructions
npm install
npm start
```

**3.[Optional] Run a webhook locally:**

If you want to test the `using-webhooks` integration with a local webhook on your machine, you can use the Stripe CLI to easily spin one up.

Make sure to [install the CLI](https://stripe.com/docs/stripe-cli) and [link your Stripe account](https://stripe.com/docs/stripe-cli#link-account).

```
stripe listen --forward-to localhost:4242/webhook
```

The CLI will print a webhook secret key to the console. Set `STRIPE_WEBHOOK_SECRET` to this value in your .env file.

You should see events logged in the console where the CLI is running.

When you are ready to create a live webhook endpoint, follow our guide in the docs on [configuring a webhook endpoint in the dashboard](https://stripe.com/docs/webhooks/setup#configure-webhook-settings).

## FAQ

Q: Why did you pick these frameworks?

A: We chose the most minimal framework to convey the key Stripe calls and concepts you need to understand. These demos are meant as an educational tool that helps you roadmap how to integrate Stripe within your own system independent of the framework.

## Get support
If you found a bug or want to suggest a new [feature/use case/sample], please [file an issue](../../issues).

If you have questions, comments, or need help with code, we're here to help:
- on [Discord](https://stripe.com/go/developer-chat)
- on Twitter at [@StripeDev](https://twitter.com/StripeDev)
- on Stack Overflow at the [stripe-payments](https://stackoverflow.com/tags/stripe-payments/info) tag
- by [email](mailto:support+github@stripe.com)

Sign up to [stay updated with developer news](https://go.stripe.global/dev-digest).

## Author(s)

@aliaso-stripe
@baz-stripe
@josegranjamartinez-stripe
@kyang-stripe
@leochen-stripe
@ninabecx-stripe
