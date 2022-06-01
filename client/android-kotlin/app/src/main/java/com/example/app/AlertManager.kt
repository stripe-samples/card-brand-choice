package com.example.app

import android.app.Activity
import androidx.appcompat.app.AlertDialog

class AlertManager {
    companion object {
        fun displayAlert(
            act: Activity,
            title: String,
            message: String,
            callback: (() -> Unit)? = null,
        ) {
            act.runOnUiThread {
                AlertDialog.Builder(act)
                    .setTitle(title)
                    .setMessage(message)
                    .setPositiveButton("Ok", null)
                    .setOnDismissListener {
                        callback?.let {
                            callback()
                        }
                    }
                    .create()
                    .show()
            }
        }
    }
}