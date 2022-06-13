package com.example.app

import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.IOException

const val BackendUrl = BuildConfig.BACKEND_URL

class ApiClient {
    private val httpClient = OkHttpClient()

    private fun buildUrl(url: String): String {
        return BackendUrl.replace(Regex("/$"), "") + "/" + url
    }

    fun fetchPublishableKey(completion: (publishableKey: String?, error: String?) -> Unit) {
        val request = Request.Builder()
            .url(buildUrl("config"))
            .build()

        httpClient.newCall(request)
            .enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    completion(null, "$e")
                }

                override fun onResponse(call: Call, response: Response) {
                    if (!response.isSuccessful) {
                        completion(null, "$response")
                    } else {
                        val responseData = response.body?.string()
                        val responseJson =
                            responseData?.let { JSONObject(it) } ?: JSONObject()
                        // For added security, our sample app gets the publishable key
                        // from the server.
                        completion(responseJson.getString("publishableKey"), null)
                    }
                }
            })
    }

    fun createPaymentIntent(
        completion: (paymentIntentClientSecret: String?, error: String?) -> Unit
    ) {

        val mediaType = "application/json; charset=utf-8".toMediaType()
        val requestJson = "{}"
        val body = requestJson.toRequestBody(mediaType)
        val request = Request.Builder()
            .url(buildUrl("create-payment-intent"))
            .post(body)
            .build()
        httpClient.newCall(request)
            .enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    completion(null, "$e")
                }

                override fun onResponse(call: Call, response: Response) {
                    if (!response.isSuccessful) {
                        completion(null, "$response")
                    } else {
                        val responseData = response.body?.string()
                        val responseJson =
                            responseData?.let { JSONObject(it) } ?: JSONObject()

                        // The response from the server contains the PaymentIntent's client_secret
                        val paymentIntentClientSecret: String =
                            responseJson.getString("clientSecret")
                        completion(paymentIntentClientSecret, null)
                    }
                }
            })
    }
}