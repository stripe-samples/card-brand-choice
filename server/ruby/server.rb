# frozen_string_literal: true

require 'stripe'
require 'sinatra'
require 'dotenv'

# Replace if using a different env file or config
Dotenv.load
Stripe.api_key = ENV['STRIPE_SECRET_KEY']

set :static, true
set :public_folder, File.join(File.dirname(__FILE__), ENV['STATIC_DIR'])
set :port, 4242

# For demo purposes we're hardcoding the amount and currency here.
# Replace this with your own inventory/cart/order logic.
$purchase = {
  amount: 1099,
  currency: 'EUR'
}

def create_purchase(_items)
  # Extend this function with your logic to validate
  # the purchase details server-side and prevent
  # manipulation of price details on the client.
  $purchase
end

get '/' do
  content_type 'text/html'
  send_file File.join(settings.public_folder, 'index.html')
end

get '/config' do
  content_type 'application/json'
  {
    publishableKey: ENV['STRIPE_PUBLISHABLE_KEY'],
    purchase: $purchase
  }.to_json
end

post '/create-payment-intent' do
  content_type 'application/json'
  data = JSON.parse(request.body.read)

  # Create the payment details based on your logic.
  purchase = create_purchase(data['items'])
  # Create a PaymentIntent with the purchase amount and currency.
  payment_intent = Stripe::PaymentIntent.create(
    amount: purchase[:amount],
    currency: purchase[:currency]
  )

  # Send the PaymentIntent client_secret to the client.
  {
    clientSecret: payment_intent['client_secret']
  }.to_json
end

post '/webhook' do
  # You can use webhooks to receive information about asynchronous payment events.
  # For more about our webhook events check out https://stripe.com/docs/webhooks.
  webhook_secret = ENV['STRIPE_WEBHOOK_SECRET']
  payload = request.body.read
  if !webhook_secret.empty?
    # Retrieve the event by verifying the signature using the raw body and secret if webhook signing is configured.
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, webhook_secret
      )
    rescue JSON::ParserError => e
      # Invalid payload
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      puts '⚠️  Webhook signature verification failed.'
      status 400
      return
    end
  else
    data = JSON.parse(payload, symbolize_names: true)
    event = Stripe::Event.construct_from(data)
  end
  # Get the type of webhook event sent - used to check the status of PaymentIntents.
  event_type = event['type']
  data = event['data']
  data_object = data['object']

  puts '🔔  Webhook received!' if event_type == 'some.event'

  content_type 'application/json'
  {
    status: 'success'
  }.to_json
end
