// A reference to Stripe.js
let stripe;
let purchase;
let card;
let networks = {
  "amex": "American Express",
  "cartes_bancaires": "Cartes Bancaires",
  "unionpay": "China UnionPay",
  "diners": "Diners Club",
  "discover": "Discover",
  "jcb": "JCB",
  "mastercard": "Mastercard",
  "visa": "Visa",
 }; 

fetch("/config")
  .then(function (result) {
    return result.json();
  })
  .then(function (data) {
    stripe = Stripe(data.publishableKey);
    purchase = data.purchase;
    // Show formatted price information.
    const price = (purchase.amount / 100).toFixed(2);
    const numberFormat = new Intl.NumberFormat(["en-US"], {
      style: "currency",
      currency: purchase.currency,
      currencyDisplay: "symbol",
    });
    document.getElementById("order-amount").innerText = numberFormat.format(
      price
    );

    // Set up Elements here
    setupElements();

    // Handle form submission.
    const form = document.getElementById("payment-form");
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      if (!document.getElementsByTagName("form")[0].reportValidity()) {
        // Form not valid, abort
        return;
      }
      // Initiate payment when the submit button is clicked
      pay();
    });
  });

function setupElements() {
  let elements = stripe.elements();
  let style = {
    base: {
      color: "#32325d",
      fontFamily: '"Helvetica Neue", Helvetica, sans-serif',
      fontSmoothing: "antialiased",
      fontSize: "16px",
      "::placeholder": {
        color: "#aab7c4",
      },
      padding: "10px 12px",
    },
    invalid: {
      color: "#fa755a",
      iconColor: "#fa755a",
    },
  };
  card = elements.create("card", {
    style: style,
    hideIcon: true,
  });
  card.mount("#card-element");
  card.on("networkschange", function (event) {
    var select = document.getElementById("card-brand-choice");
    select.options.length = 0;
    if (event.loading === false) {
      for(index in event.networks) {
        select.options[select.options.length] = new Option(networks[event.networks[index]], index);
      }
      select.value = 0;
    }
  }); 
}

async function createPaymentIntent(purchase) {
  return await fetch(`/create-payment-intent`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      items: [purchase], // Replace with your own logic
    }),
  }).then((res) => res.json());
}

async function pay() {
  changeLoadingState(true);

  let data = await createPaymentIntent(purchase);
  let secret = data.clientSecret;
  await confirmPaymentIntent(secret);
  orderComplete(secret);
}

async function confirmPaymentIntent(clientSecret) {
  var options = {
    payment_method: {
      card: card,
      billing_details: {
        name: document.getElementById("name").value,
      }
    },
  };

  // Get the selected card brand
  var cardBrand = document.getElementById("card-brand-choice").value;
  // Set the card network to the above value, skip step when not provided
  // If skipped, the network will be selected by Stripe
  if (!!cardBrand) {
    options["payment_method_options"] = {
      card: {
        network: cardBrand,
      },
    };
  }

  stripe.confirmCardPayment(clientSecret, options);
  return clientSecret;
}

/* ------- Post-payment helpers ------- */

/* Shows a success / error message when the payment is complete */
function orderComplete(clientSecret) {
  // Just for the purpose of the sample, show the PaymentIntent response object
  stripe.retrievePaymentIntent(clientSecret).then(function (result) {
    const paymentIntent = result.paymentIntent;
    const paymentIntentJson = JSON.stringify(paymentIntent, null, 2);

    document.querySelector(".sr-payment-form").classList.add("hidden");
    document.querySelector("pre").textContent = paymentIntentJson;

    document.querySelector(".sr-result").classList.remove("hidden");
    setTimeout(function () {
      document.querySelector(".sr-result").classList.add("expand");
    }, 200);

    changeLoadingState(false);
  });
}

function showError(errorMsgText) {
  changeLoadingState(false);
  const errorMsg = document.querySelector(".sr-field-error");
  errorMsg.textContent = errorMsgText;
  setTimeout(function () {
    errorMsg.textContent = "";
  }, 4000);
}

// Show a spinner on payment submission
function changeLoadingState(isLoading) {
  if (isLoading) {
    document.querySelector("button").disabled = true;
    document.querySelector("#spinner").classList.remove("hidden");
    document.querySelector("#button-text").classList.add("hidden");
  } else {
    document.querySelector("button").disabled = false;
    document.querySelector("#spinner").classList.add("hidden");
    document.querySelector("#button-text").classList.remove("hidden");
  }
}
