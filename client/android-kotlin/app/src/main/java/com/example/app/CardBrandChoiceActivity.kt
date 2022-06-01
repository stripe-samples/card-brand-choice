package com.example.app

import android.os.Bundle
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import androidx.appcompat.app.AppCompatActivity
import com.example.app.databinding.CardActivityBinding
import com.stripe.android.PaymentConfiguration
import com.stripe.android.model.ConfirmPaymentIntentParams
import com.stripe.android.model.PaymentMethodOptionsParams
import com.stripe.android.payments.paymentlauncher.PaymentLauncher
import com.stripe.android.payments.paymentlauncher.PaymentResult
import com.stripe.android.view.CardValidCallback


class CardBrandChoiceActivity : AppCompatActivity() {

    private lateinit var paymentLauncher: PaymentLauncher
    private lateinit var binding: CardActivityBinding
    private var cardBrand: String? = null
    private lateinit var paymentIntentClientSecret: String
    private val unknownIndexPosition = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = CardActivityBinding.inflate(layoutInflater)
        val view = binding.root
        setContentView(view)

        this.createIntent()
        this.wireViewEvents()

        val paymentConfiguration = PaymentConfiguration.getInstance(applicationContext)
        paymentLauncher = PaymentLauncher.Companion.create(
            this,
            paymentConfiguration.publishableKey,
            paymentConfiguration.stripeAccountId,
            ::onPaymentResult
        )
    }

    private fun wireViewEvents() {
        // set card network
        binding.listBrands.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onNothingSelected(parent: AdapterView<*>?) {}
            override fun onItemSelected(
                parent: AdapterView<*>?,
                view: View?,
                position: Int,
                id: Long
            ) {
                cardBrand = if (position === unknownIndexPosition) {
                    null
                } else {
                    resources.getStringArray(R.array.network_cards_values)[position]
                }
            }
        }

        binding.cardInputWidget.setCardValidCallback(callback = { isValid: Boolean, _: Set<CardValidCallback.Fields> ->
            if (isValid) {
                binding.cardInputWidget.cardParams?.brand?.code?.let { code ->
                    cardBrand = code
                    val brands = resources.getStringArray(R.array.network_cards_values)
                    binding.listBrands.setSelection(brands.indexOf(code))
                }
            }
        })

        //binding the spinner
        val adapter = ArrayAdapter.createFromResource(
            this,
            R.array.network_cards,
            android.R.layout.simple_spinner_item
        )
        binding.listBrands.adapter = adapter

        //selecting Unknown by default
        binding.listBrands.setSelection(unknownIndexPosition)

        // binding the submit button
        binding.payButton.setOnClickListener {
            val paymentMethodOptions = PaymentMethodOptionsParams.Card(null, cardBrand)
            binding.cardInputWidget.paymentMethodCreateParams?.let { myParams ->
                val confirmParams = ConfirmPaymentIntentParams
                    .createWithPaymentMethodCreateParams(
                        paymentMethodCreateParams = myParams,
                        clientSecret = paymentIntentClientSecret,
                        paymentMethodOptions = paymentMethodOptions
                    )
                // give UI feedback and prevent re-submit
                binding.payButton.isEnabled = false
                paymentLauncher.confirm(confirmParams)
            }
        }
    }

    private fun createIntent() {
        ApiClient().createPaymentIntent(completion = { paymentIntentClientSecret, error ->
            run {
                paymentIntentClientSecret?.let {
                    this.paymentIntentClientSecret = it
                }
                error?.let {
                    AlertManager.displayAlert(
                        this,
                        "Failed to load page",
                        "Error: $error",

                        )
                }
            }
        })
    }

    private fun onPaymentResult(paymentResult: PaymentResult) {
        val message = when (paymentResult) {
            is PaymentResult.Completed -> {
                "Completed! The demo will now restart"
            }
            is PaymentResult.Canceled -> {
                "Canceled!"
            }
            is PaymentResult.Failed -> {
                // This string comes from the PaymentIntent's error message.
                // See here: https://stripe.com/docs/api/payment_intents/object#payment_intent_object-last_payment_error-message
                "Failed: " + paymentResult.throwable.message
            }
        }

        AlertManager.displayAlert(
            this, "Payment Result:", message,
        ) {
            if (paymentResult == PaymentResult.Completed) {
                this.finish()
            }
        }

        binding.payButton.isEnabled = true
    }
}
