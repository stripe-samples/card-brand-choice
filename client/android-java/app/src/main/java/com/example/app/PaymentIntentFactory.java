package com.example.app;

import android.os.Handler;
import android.os.Looper;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicReference;

public class PaymentIntentFactory {
    private final Handler handler;
    private final AtomicReference<String> secret = new AtomicReference<>();
    private final AtomicReference<String> error = new AtomicReference<>();
    private CountDownLatch latch;
    private String _secret = null;
    private String _error = null;

    PaymentIntentFactory() {
        handler = new Handler(Looper.getMainLooper());
    }

    public void createPaymentIntent() {
        _secret = null;
        _error = null;
        latch = new CountDownLatch(1);
        new Thread(() -> new ApiClient().createPaymentIntent((_paymentIntentClientSecret, _error) -> {
            handler.post(() -> {
                if (_paymentIntentClientSecret != null) {
                    secret.set(_paymentIntentClientSecret);
                } else {
                    error.set(_error);
                }
                latch.countDown();
            });
            return null;
        })).start();
    }

    public String getPaymentIntentClientSecret() {
        resolveLatch();
        return _secret;
    }

    public String getError() {
        resolveLatch();
        return _error;
    }

    private void resolveLatch() {
        if (latch == null)
            return;

        try {
            latch.await();
            if ((_secret = secret.get()) == null)
                _error = error.get();
        } catch (InterruptedException e) {
            _error = e.toString();
        }
    }
}
