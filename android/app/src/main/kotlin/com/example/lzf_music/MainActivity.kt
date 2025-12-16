package com.example.lzf_music

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import androidx.annotation.NonNull
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceFragmentActivity() {
    
    private val CHANNEL = "com.lzf_music/secure_bookmarks"
    private val REQUEST_CODE_PICK_FILE = 8888
    
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Android 手动选择文件
                "pickFilesAndroid" -> {
                    if (pendingResult != null) {
                        result.error("BUSY", "Another picker is already active", null)
                        return@setMethodCallHandler
                    }
                    pendingResult = result
                    openFilePicker()
                }
                
                // 兼容接口
                "createBookmark", "startAccessing", "stopAccessing" -> {
                    val bookmark = call.argument<String>("bookmark")
                    result.success(bookmark)
                }
                
                else -> result.notImplemented()
            }
        }
    }

    // 打开文件选择器 (调用各家厂商的管理器)
    private fun openFilePicker() {
        // 修改点 1: 使用 ACTION_GET_CONTENT 代替 ACTION_OPEN_DOCUMENT
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*" // 只显示音频
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true) // 允许多选
            
            // 注意：ACTION_GET_CONTENT 不支持 FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            // 所以这里不需要 addFlags
        }
        
        // 创建选择器 (这样会弹出一个底部菜单，让用户选是用 "文件管理" 还是 "音乐" 打开)
        val chooserIntent = Intent.createChooser(intent, "选择音乐")
        startActivityForResult(chooserIntent, REQUEST_CODE_PICK_FILE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CODE_PICK_FILE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val results = mutableListOf<Map<String, String>>()

                // 处理多选
                if (data.clipData != null) {
                    val count = data.clipData!!.itemCount
                    for (i in 0 until count) {
                        val uri = data.clipData!!.getItemAt(i).uri
                        // 修改点 2: 去掉了 takePersistableUriPermission，因为 GET_CONTENT 不支持
                        results.add(getFileInfo(uri))
                    }
                } 
                // 处理单选
                else if (data.data != null) {
                    val uri = data.data!!
                    results.add(getFileInfo(uri))
                }

                pendingResult?.success(results)
            } else {
                pendingResult?.success(listOf<Map<String, String>>()) 
            }
            pendingResult = null
        }
    }

    private fun getFileInfo(uri: Uri): Map<String, String> {
        var name = "unknown"
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (nameIndex != -1) name = it.getString(nameIndex)
            }
        }
        return mapOf(
            "uri" to uri.toString(),
            "name" to name
        )
    }
}