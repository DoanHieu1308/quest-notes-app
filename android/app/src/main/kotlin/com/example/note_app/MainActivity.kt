package com.example.note_app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "quest_notes/widget")
            .setMethodCallHandler { call, result ->
                if (call.method != "updateWidget") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val prefs = getSharedPreferences("quest_notes_widget", Context.MODE_PRIVATE)
                prefs.edit()
                    .putInt("coins", call.argument<Int>("coins") ?: 0)
                    .putInt("done", call.argument<Int>("done") ?: 0)
                    .putInt("total", call.argument<Int>("total") ?: 0)
                    .putString("next", call.argument<String>("next") ?: "Không có task nào hôm nay")
                    .apply()

                val manager = AppWidgetManager.getInstance(this)
                val ids = manager.getAppWidgetIds(ComponentName(this, QuestNoteWidgetProvider::class.java))
                val intent = Intent(this, QuestNoteWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                sendBroadcast(intent)
                result.success(true)
            }
    }
}
