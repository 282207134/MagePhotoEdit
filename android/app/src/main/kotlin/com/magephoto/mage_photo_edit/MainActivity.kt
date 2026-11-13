package com.magephoto.mage_photo_edit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.content.Intent
import android.provider.MediaStore
import android.os.Build
import android.os.Environment
import java.io.File

class MainActivity : FlutterActivity() {
    private var mageChannel: MethodChannel? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra("mage_screen")?.let { mageChannel?.invokeMethod("previewScreenChanged", it) }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mageChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mage/export")
        mageChannel!!.setMethodCallHandler { call, result ->
            if (call.method == "previewScreen") {
                result.success(intent.getStringExtra("mage_screen"))
                return@setMethodCallHandler
            }
            if (call.method != "savePng") { result.notImplemented(); return@setMethodCallHandler }
            try {
                val bytes = call.argument<ByteArray>("bytes") ?: error("Missing PNG bytes")
                val name = call.argument<String>("name") ?: "mage.png"
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val values = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, name)
                        put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                        put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Mage")
                        put(MediaStore.Images.Media.IS_PENDING, 1)
                    }
                    val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values) ?: error("Cannot create image")
                    try {
                        contentResolver.openOutputStream(uri)?.use { it.write(bytes) } ?: error("Cannot write image")
                        values.clear(); values.put(MediaStore.Images.Media.IS_PENDING, 0)
                        contentResolver.update(uri, values, null, null)
                    } catch (e: Exception) { contentResolver.delete(uri, null, null); throw e }
                    result.success("Pictures/Mage/$name")
                } else {
                    val file = File(getExternalFilesDir(Environment.DIRECTORY_PICTURES), name)
                    file.writeBytes(bytes); result.success(file.absolutePath)
                }
            } catch (e: Exception) { result.error("EXPORT_FAILED", e.message, null) }
        }
    }
}
