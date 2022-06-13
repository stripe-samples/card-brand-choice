package com.example.app;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.Spinner;

import androidx.appcompat.app.AppCompatActivity;

import com.stripe.android.PaymentConfiguration;
import com.stripe.android.model.CardParams;
import com.stripe.android.model.ConfirmPaymentIntentParams;
import com.stripe.android.model.PaymentMethodCreateParams;
import com.stripe.android.model.PaymentMethodOptionsParams;
import com.stripe.android.payments.paymentlauncher.PaymentLauncher;
import com.stripe.android.payments.paymentlauncher.PaymentResult;
import com.stripe.android.view.CardInputWidget;
import com.stripe.android.view.CardValidCallback;

import java.util.Arrays;
import java.util.Set;

public class CheckoutActivity extends AppCompatActivity {
    private final int spinnerEmptyElementIndex = 0;
    private PaymentLauncher paymentLauncher;
    private CardInputWidget cardInputWidget;
    private boolean cardInputWidgetValid = false;
    private ProgressBar progressBar;
    private Button payButton;
    private Spinner cardBrandsSpinner;
    private PaymentIntentFactory paymentIntentFactory;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.card_activity);

        payButton = findViewById(R.id.payButton);
        cardInputWidget = findViewById(R.id.cardInputWidget);
        cardBrandsSpinner = findViewById(R.id.cardBrandsSpinner);
        progressBar = findViewById(R.id.progressBar);

        paymentIntentFactory = new PaymentIntentFactory();
        paymentIntentFactory.createPaymentIntent();

        final PaymentConfiguration paymentConfiguration = PaymentConfiguration.getInstance(getApplicationContext());
        paymentLauncher = PaymentLauncher.Companion.create(
                this,
                paymentConfiguration.getPublishableKey(),
                paymentConfiguration.getStripeAccountId(),
                this::onPaymentResult
        );

        cardInputWidget.setPostalCodeEnabled(false);
        cardInputWidget.setCardValidCallback(this::onCardValidityChange);

        payButton.setEnabled(false);
        payButton.setOnClickListener(this::onPaymentButtonClick);

        final ArrayAdapter<CharSequence> adapter = ArrayAdapter.createFromResource(
                this,
                R.array.network_cards,
                android.R.layout.simple_spinner_dropdown_item
        );
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        cardBrandsSpinner.setAdapter(adapter);
        cardBrandsSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                if (position == spinnerEmptyElementIndex) {
                    setSelectedBrandCodeFromCardParams();
                }
            }

            @Override
            public void onNothingSelected(AdapterView<?> parent) {

            }
        });
    }

    private void displayAlert(String title, String message, DialogInterface.OnClickListener listener) {
        new AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage(message)
                .setPositiveButton("OK", listener)
                .create()
                .show();
    }

    private void onPaymentResult(PaymentResult paymentResult) {
        String message = paymentResult.getClass().getSimpleName() + ".";

        stopPaymentProgressDisplay();

        if (paymentResult instanceof PaymentResult.Failed) {
            message += (" " + ((PaymentResult.Failed) paymentResult).getThrowable().getMessage());
            displayAlert("Payment result", message, null);
        } else {
            displayAlert("Payment result", message, (dialog, which) -> this.finish());
        }
    }

    private void onPaymentButtonClick(View view) {
        final String paymentIntentClientSecret;
        final PaymentMethodCreateParams createParams;
        final PaymentMethodOptionsParams methodParams;
        final ConfirmPaymentIntentParams confirmParams;

        startPaymentProgressDisplay();

        if ((createParams = cardInputWidget.getPaymentMethodCreateParams()) != null) {
            if ((paymentIntentClientSecret = paymentIntentFactory.getPaymentIntentClientSecret()) == null) {
                displayAlert("Backend error", "failed to create PaymentIntent: " + paymentIntentFactory.getError(), (dialog, which) -> this.finish());
                return;
            }
            methodParams = new PaymentMethodOptionsParams.Card(null, getSelectedBrandCode(), null, null);
            confirmParams = ConfirmPaymentIntentParams.createWithPaymentMethodCreateParams(createParams, paymentIntentClientSecret);
            confirmParams.setPaymentMethodOptions(methodParams);
            paymentLauncher.confirm(confirmParams);
        } else {
            stopPaymentProgressDisplay();
        }
    }

    private void onCardValidityChange(boolean isValid, Set<? extends CardValidCallback.Fields> invalidFields) {
        payButton.setEnabled(isValid);
        cardInputWidgetValid = isValid;
        setSelectedBrandCodeFromCardParams();
    }

    private int getSpinnerBrandCodePos(String brandCode) {
        return Arrays.asList(getResources().getStringArray(R.array.network_cards_values)).indexOf(brandCode);
    }

    private String getSelectedBrandCode() {
        final int index = cardBrandsSpinner.getSelectedItemPosition();
        if (index == spinnerEmptyElementIndex)
            return null;
        else
            return getResources().getStringArray(R.array.network_cards_values)[index];
    }

    private void setSelectedBrandCode(String brandCode) {
        cardBrandsSpinner.setSelection(getSpinnerBrandCodePos(brandCode));
    }

    private void setSelectedBrandCodeFromCardParams() {
        if (cardInputWidgetValid) {
            final CardParams cardParams;
            if ((cardParams = cardInputWidget.getCardParams()) != null) {
                final String brandCode = cardParams.getBrand().getCode();
                setSelectedBrandCode(brandCode);
            }
        }
    }

    private void startPaymentProgressDisplay() {
        payButton.setEnabled(false);
        progressBar.setVisibility(View.VISIBLE);
    }

    private void stopPaymentProgressDisplay() {
        progressBar.setVisibility(View.INVISIBLE);
        payButton.setEnabled(true);
    }
}
