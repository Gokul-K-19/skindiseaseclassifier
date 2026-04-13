package com.example.skindisease_app

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.pytorch.IValue
import org.pytorch.Module
import org.pytorch.torchvision.TensorImageUtils

class MainActivity: FlutterActivity() {

    private val CHANNEL = "model_channel"
    private var module: Module? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Load model
        try {
            module = Module.load(assetFilePath("sgcm_mobile.pt"))
            Log.d("MODEL", "Model loaded successfully")
        } catch (e: Exception) {
            Log.e("MODEL", "Error loading model", e)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                if (call.method == "predict") {
                    val imagePath = call.argument<String>("path")

                    if (imagePath != null) {
                        val prediction = runModel(imagePath)
                        result.success(prediction)
                    } else {
                        result.error("ERROR", "No image path", null)
                    }
                }
            }
    }

    private fun runModel(path: String): String {
        val bitmap = BitmapFactory.decodeFile(path)

        val inputTensor = TensorImageUtils.bitmapToFloat32Tensor(
            bitmap,
            floatArrayOf(0.485f, 0.456f, 0.406f),
            floatArrayOf(0.229f, 0.224f, 0.225f)
        )

        val output = module!!.forward(IValue.from(inputTensor)).toTensor()
        val scores = output.dataAsFloatArray
        for (i in scores.indices) {
            Log.d("MODEL_OUTPUT", "Class $i: ${scores[i]}")
        }
        val classes = arrayOf(
            "Acne Vulgaris",
            "Clear Skin",
            "Dermatitis",
            "Fungal Infection"
        )

        var maxScore = scores[0]
        var maxIndex = 0

        for (i in scores.indices) {
            if (scores[i] > maxScore) {
                maxScore = scores[i]
                maxIndex = i
            }
        }

        return classes[maxIndex]
    }

    private fun assetFilePath(assetName: String): String {
        val file = java.io.File(filesDir, assetName)
        if (file.exists() && file.length() > 0) return file.absolutePath

        assets.open(assetName).use { input ->
            java.io.FileOutputStream(file).use { output ->
                input.copyTo(output)
            }
        }
        return file.absolutePath
    }
}