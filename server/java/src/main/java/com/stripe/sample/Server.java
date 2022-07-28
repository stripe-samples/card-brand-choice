package com.stripe.sample;

import java.nio.file.Paths;

import java.util.HashMap;
import java.util.Map;

import static spark.Spark.get;
import static spark.Spark.post;
import static spark.Spark.port;
import static spark.Spark.staticFiles;

import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;

import com.stripe.Stripe;
import com.stripe.model.Event;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentCreateParams;
import com.stripe.exception.*;
import com.stripe.net.Webhook;

import io.github.cdimascio.dotenv.Dotenv;

public class Server {
    private static Gson gson = new Gson();

    // For demo purposes we're hardcoding the amount and currency here.
    // Replace this with your own inventory/cart/order logic.
    static final Map<String, Object> PURCHASE = new HashMap<String, Object>() {{
        put("amount", 1099L);
        put("currency", "EUR");
    }};

    static Map<String, Object> createPurchase(Map<String, Object>[] items) {
        // Extend this function with your logic to validate
        // the purchase details server-side and prevent
        // manipulation of price details on the client.
        return PURCHASE;
    }

    static class CreateRequestBody {
        @SerializedName("items")
        Map<String, Object>[] items;

        public Map<String, Object>[] getItems() {
            return items;
        }
    }

    public static void main(String[] args) {
        port(4242);
        Dotenv dotenv = Dotenv.load();
        Stripe.apiKey = dotenv.get("STRIPE_SECRET_KEY");

        staticFiles.externalLocation(
                Paths.get(Paths.get("").toAbsolutePath().toString(), dotenv.get("STATIC_DIR"), "web").normalize().toString());

        get("/config", (request, response) -> {
            response.type("application/json");

            Map<String, Object> responseData = new HashMap<>();
            responseData.put("publishableKey", dotenv.get("STRIPE_PUBLISHABLE_KEY"));
            Map<String, Object> nestedParams = new HashMap<>();
            nestedParams.put("amount", PURCHASE.get("amount"));
            nestedParams.put("currency", PURCHASE.get("currency"));
            responseData.put("purchase", nestedParams);
            return gson.toJson(responseData);
        });

        post("/create-payment-intent", (request, response) -> {
            response.type("application/json");

            CreateRequestBody postBody = gson.fromJson(request.body(), CreateRequestBody.class);
            
            // Create the payment details based on your logic.
            Map<String, Object> purchase = createPurchase(postBody.getItems());
            
            PaymentIntentCreateParams createParams = new PaymentIntentCreateParams.Builder()
                    .setAmount((Long) purchase.get("amount"))
                    .setCurrency((String) purchase.get("currency"))
                    .build();
            // Create a PaymentIntent with the purchase amount and currency
            PaymentIntent intent = PaymentIntent.create(createParams);
            // Send the PaymentIntent client_secret to the client
            Map<String, Object> responseData = new HashMap<>();
            responseData.put("clientSecret", intent.getClientSecret());
            return gson.toJson(responseData);
        });

        post("/webhook", (request, response) -> {
            String payload = request.body();
            String sigHeader = request.headers("Stripe-Signature");
            String endpointSecret = dotenv.get("STRIPE_WEBHOOK_SECRET");

            Event event = null;

            try {
                event = Webhook.constructEvent(payload, sigHeader, endpointSecret);
            } catch (SignatureVerificationException e) {
                // Invalid signature
                response.status(400);
                return "";
            }

            switch (event.getType()) {
            case "payment_intent.succeeded":
                // Fulfill any orders, e-mail receipts, etc
                // To cancel the payment you will need to issue a Refund
                // (https://stripe.com/docs/api/refunds)
                System.out.println("💰Payment received!");
                break;
            case "payment_intent.payment_failed":
                System.out.println("❌ Payment failed.");
                break;
            }
            
            // Acknowledge receipt of webhook event.
            response.status(200);
            return "";    
        });
    }
}