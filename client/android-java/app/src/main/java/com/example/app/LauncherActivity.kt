package com.example.app

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.example.app.databinding.ActivityLauncherBinding
import com.stripe.android.PaymentConfiguration

class LauncherActivity : AppCompatActivity() {
    private lateinit var publishableKey: String
    private lateinit var binding: ActivityLauncherBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLauncherBinding.inflate(layoutInflater)
        val view = binding.root
        setContentView(view)
        fetchPublishableKey()

        binding.launchCheckout.setOnClickListener {
            startActivity(Intent(this, CheckoutActivity::class.java))
        }
    }

    private fun displayAlert(
        title: String,
        message: String
    ) {
        runOnUiThread {
            val builder = AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage(message)

            builder.setPositiveButton("Ok", null)
            builder
                .create()
                .show()
        }
    }

    private fun fetchPublishableKey() {
        ApiClient().fetchPublishableKey(completion = { publishableKey, error ->
            run {
                publishableKey?.let {
                    this@LauncherActivity.publishableKey = it
                    PaymentConfiguration.init(
                        applicationContext,
                        this@LauncherActivity.publishableKey
                    )
                }
                error?.let {
                    displayAlert(
                        "Failed to load page",
                        "Error: $error"
                    )
                }
            }
        })
    }
}