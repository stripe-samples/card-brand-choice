#! /usr/bin/env python3.6

"""
server.py
Stripe Sample.
Python 3.6 or newer required.
"""

import stripe
import json
import os

from flask import Flask, render_template, jsonify, request, send_from_directory
from dotenv import load_dotenv, find_dotenv

# Setup Stripe python client library
load_dotenv(find_dotenv())
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
stripe.api_version = os.getenv('STRIPE_API_VERSION')

static_dir = str(os.path.abspath(os.path.join(
    __file__, "..", os.getenv("STATIC_DIR"))))
app = Flask(__name__, static_folder=static_dir,
            static_url_path="", template_folder=static_dir)

# For demo purposes we're hardcoding the amount and currency here.
# Replace this with your own inventory/cart/order logic.
purchase = {
    'amount': 1099,
    'currency': 'USD'
}


def create_purchase(items):
    # Extend this function with your logic to validate
    # the purchase details server-side and prevent
    # manipulation of price details on the client.
    return purchase


@app.route('/', methods=['GET'])
def get_checkout_page():
    # Display checkout page
    return render_template('index.html')


@app.route('/config', methods=['GET'])
def get_PUBLISHABLE_KEY():
    return jsonify({
        'publishableKey': os.getenv('STRIPE_PUBLISHABLE_KEY'),
        'purchase': purchase
    })


@app.route('/create-payment-intent', methods=['POST'])
def create_payment():
    data = json.loads(request.data)

    # Create the payment details based on your logic.
    purchase = create_purchase(data['items'])
    # Create a PaymentIntent with the purchase amount and currency.
    intent = stripe.PaymentIntent.create(
        amount=purchase['amount'],
        currency=purchase['currency']
    )

    try:
        # Send the PaymentIntent client_secret to the client.
        return jsonify({'clientSecret': intent.client_secret})
    except Exception as e:
        return jsonify(error=str(e)), 403


@app.route('/webhook', methods=['POST'])
def webhook_received():
    # You can use webhooks to receive information about asynchronous payment events.
    # For more about our webhook events check out https://stripe.com/docs/webhooks.
    webhook_secret = os.getenv('STRIPE_WEBHOOK_SECRET')
    request_data = json.loads(request.data)

    if webhook_secret:
        # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
        signature = request.headers.get('stripe-signature')
        try:
            event = stripe.Webhook.construct_event(
                payload=request.data, sig_header=signature, secret=webhook_secret)
            data = event['data']
        except Exception as e:
            return e
        # Get the type of webhook event sent - used to check the status of PaymentIntents.
        event_type = event['type']
    else:
        data = request_data['data']
        event_type = request_data['type']
    data_object = data['object']

    print('event ' + event_type)

    if event_type == 'some.event':
        print('🔔Webhook received!')

    return jsonify({'status': 'success'})


if __name__ == '__main__':
    app.run(port=4242)
