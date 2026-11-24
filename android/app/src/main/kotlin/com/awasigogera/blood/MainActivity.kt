package com.awasigogera.blood

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.graphics.BitmapFactory
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.UUID
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val worker = Executors.newSingleThreadExecutor()
    private var pendingSave: Pair<ByteArray, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val prefs = getSharedPreferences("blood_request", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.awasigogera.blood/device")
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "read" -> onWorker(result) { prefs.getString("state", null) }
                        "write" -> onWorker(result) {
                            check(prefs.edit().putString("state", call.arguments as String).commit())
                            null
                        }
                        "jpeg" -> {
                            val bytes = requireNotNull(call.argument<ByteArray>("bytes"))
                            val quality = requireNotNull(call.argument<Int>("quality"))
                            onWorker(result) {
                                val bitmap = requireNotNull(BitmapFactory.decodeByteArray(bytes, 0, bytes.size))
                                try {
                                    ByteArrayOutputStream().use { output ->
                                        check(bitmap.compress(Bitmap.CompressFormat.JPEG, quality, output))
                                        output.toByteArray()
                                    }
                                } finally {
                                    bitmap.recycle()
                                }
                            }
                        }
                        "save" -> {
                            check(pendingSave == null)
                            val bytes = requireNotNull(call.argument<ByteArray>("bytes"))
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = requireNotNull(call.argument<String>("mime"))
                                putExtra(Intent.EXTRA_TITLE, requireNotNull(call.argument<String>("name")))
                            }
                            pendingSave = bytes to result
                            try {
                                @Suppress("DEPRECATION")
                                startActivityForResult(intent, SAVE_POSTER)
                            } catch (exception: Exception) {
                                pendingSave = null
                                throw exception
                            }
                        }
                        "open" -> {
                            val uri = Uri.parse(requireNotNull(call.argument<String>("uri")))
                            check(uri.scheme == "content")
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                setDataAndType(uri, requireNotNull(call.argument<String>("mime")))
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            startActivity(intent)
                            result.success(null)
                        }
                        "share" -> {
                            val bytes = requireNotNull(call.argument<ByteArray>("bytes"))
                            val mime = requireNotNull(call.argument<String>("mime"))
                            val name = requireNotNull(call.argument<String>("name"))
                            val caption = call.argument<String>("caption")
                            worker.execute {
                                try {
                                    check(name == "blood-request.jpg" || name == "blood-request.png")
                                    val directory = File(cacheDir, "posters").apply { mkdirs() }
                                    val cutoff = System.currentTimeMillis() - 60 * 60 * 1000
                                    directory.listFiles()?.filter { it.lastModified() < cutoff }?.forEach { it.deleteRecursively() }
                                    val folder = File(directory, UUID.randomUUID().toString())
                                    check(folder.mkdir())
                                    val file = File(folder, name).apply { writeBytes(bytes) }
                                    val uri = FileProvider.getUriForFile(this, "$packageName.posters", file)
                                    val intent = Intent(Intent.ACTION_SEND).apply {
                                        type = mime
                                        putExtra(Intent.EXTRA_STREAM, uri)
                                        if (caption != null) putExtra(Intent.EXTRA_TEXT, caption)
                                        clipData = ClipData.newUri(contentResolver, name, uri)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }
                                    runOnUiThread {
                                        try {
                                            startActivity(Intent.createChooser(intent, null))
                                            result.success(null)
                                        } catch (_: Exception) {
                                            result.error("share", null, null)
                                        }
                                    }
                                } catch (_: Exception) {
                                    result.error("share", null, null)
                                }
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (_: Exception) {
                    result.error("device", null, null)
                }
            }
    }

    @Deprecated("FlutterActivity forwards the legacy activity callback")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAVE_POSTER) return
        val (bytes, result) = pendingSave ?: return
        pendingSave = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        onWorker(result) {
            try {
                requireNotNull(contentResolver.openOutputStream(uri, "w")).use { it.write(bytes) }
                uri.toString()
            } catch (exception: Exception) {
                runCatching { contentResolver.delete(uri, null, null) }
                throw exception
            }
        }
    }

    private fun onWorker(result: MethodChannel.Result, action: () -> Any?) {
        worker.execute {
            try {
                result.success(action())
            } catch (_: OutOfMemoryError) {
                result.error("memory", null, null)
            } catch (_: Exception) {
                result.error("io", null, null)
            }
        }
    }

    companion object {
        private const val SAVE_POSTER = 7241
    }
}
