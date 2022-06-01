// Env variable path defined in .env.ts file.
import { resolve } from "path";
import "./env";

import bodyParser from "body-parser";
import express from "express";
const app: express.Application = express();

// Initialise Stripe with Typescript.
import Stripe from "stripe";
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: "2019-12-03"
});

// For demo purposes we're hardcoding the amount and currency here.
// Replace this with your own inventory/cart/order logic.
const purchase = {
  amount: 1099 as const,
  currency: "EUR" as const
};

const createPurchase = (
  items: object[]
): { amount: number; currency: string } => {
  // Extend this function with your logic to validate
  // the purchase details server-side and prevent
  // manipulation of price details on the client.
  return purchase;
};

app.use(express.static(process.env.STATIC_DIR));
// Only use the raw body parser for webhooks
app.use(
  (
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ): void => {
    if (req.originalUrl === "/webhook") {
      next();
    } else {
      bodyParser.json()(req, res, next);
    }
  }
);

app.get("/config", (_: express.Request, res: express.Response): void => {
  res.send({
    publishableKey: process.env.STRIPE_PUBLISHABLE_KEY,
    purchase
  });
});

app.get("/", (_: express.Request, res: express.Response): void => {
  const path = resolve(process.env.STATIC_DIR + "/index.html");
  res.sendFile(path);
});

app.post(
  "/create-payment-intent",
  async (
    req: express.Request,
    res: express.Response
  ): Promise<express.Response | void> => {
    const {
      items
    }: {
      items: object[];
    } = req.body;

    // Create the payment details based on your logic.
    const { amount, currency } = createPurchase(items);

    // Create a PaymentIntent with the purchase amount and currency.
    const paymentIntent: Stripe.PaymentIntent = await stripe.paymentIntents.create(
      {
        amount,
        currency
      }
    );

    // Send the PaymentIntent client_secret to the client.
    res.send({
      clientSecret: paymentIntent.client_secret
    });
  }
);

// Webhook handler for asynchronous events.
app.post(
  "/webhook",
  // Use body-parser to retrieve the raw body as a buffer.
  bodyParser.raw({ type: "application/json" }),
  (req: express.Request, res: express.Response): void => {
    // Retrieve the event by verifying the signature using the raw body and secret.
    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        req.headers["stripe-signature"],
        process.env.STRIPE_WEBHOOK_SECRET
      );
    } catch (err) {
      console.log(`⚠️  Webhook signature verification failed.`);
      res.sendStatus(400);
      return;
    }

    // Extract the data from the event.
    const data: Stripe.Event.Data = event.data;
    const eventType: string = event.type;

    if (eventType === "payment_intent.succeeded") {
      // Cast the event into a PaymentIntent to make use of the types.
      const pi: Stripe.PaymentIntent = data.object as Stripe.PaymentIntent;
      console.log(`🔔  Webhook received: ${pi.object} ${pi.status}!`);
    }

    res.sendStatus(200);
  }
);

app.listen(4242, (): void =>
  console.log(`Node server listening on port ${4242}!`)
);
