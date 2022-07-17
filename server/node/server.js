// Replace if using a different env file or config.
require("dotenv").config({ path: "./.env" });
const express = require("express");
const app = express();
const { resolve } = require("path");
const bodyParser = require("body-parser");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

// For demo purposes we're hardcoding the amount and currency here.
// Replace this with your own inventory/cart/order logic.
const purchase = {
  amount: 1099,
  currency: "EUR",
};

const createPurchase = (items) => {
  // Extend this function with your logic to validate
  // the purchase details server-side and prevent
  // manipulation of price details on the client.
  return purchase;
};

app.use(express.static(resolve(process.env.STATIC_DIR, "html")));
// Use JSON parser for all non-webhook routes.
app.use((req, res, next) => {
  if (req.originalUrl === "/webhook") {
    next();
  } else {
    bodyParser.json()(req, res, next);
  }
});

app.get("/config", (req, res) => {
  res.send({
    publishableKey: process.env.STRIPE_PUBLISHABLE_KEY,
    purchase,
  });
});

app.get("/", (req, res) => {
  const path = resolve(process.env.STATIC_DIR + "/index.html");
  res.sendFile(path);
});

app.post("/create-payment-intent", async (req, res) => {
  const { items } = req.body;

  // Create the payment details based on your logic.
  const { amount, currency } = createPurchase(items);

  // Create a PaymentIntent with the purchase amount and currency.
  const paymentIntent = await stripe.paymentIntents.create({
    amount,
    currency,
  });

  // Send the PaymentIntent client_secret to the client.
  res.send({
    clientSecret: paymentIntent.client_secret,
  });
});

// Stripe requires the raw body to construct the event.
app.post(
  "/webhook",
  bodyParser.raw({ type: "application/json" }),
  (req, res) => {
    let event;

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        req.headers["stripe-signature"],
        process.env.STRIPE_WEBHOOK_SECRET
      );
    } catch (err) {
      // On error, log and return the error message
      console.log(`❌ Error message: ${err.message}`);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // Successfully constructed event
    console.log("✅ Success:", event.id);

    // Return a response to acknowledge receipt of the event
    res.json({ received: true });
  }
);

app.listen(4242, () => console.log(`Node server listening on port ${4242}!`));
