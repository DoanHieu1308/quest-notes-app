package com.example.note_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class QuestNoteWidgetProvider : AppWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_COMPLETE_TASK -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID)
                if (!taskId.isNullOrBlank()) {
                    completeTask(context, taskId)
                    clampTaskPage(context)
                    updateAllWidgets(context)
                }
            }

            ACTION_PREV_PAGE -> {
                moveTaskPage(context, -1)
                updateAllWidgets(context)
            }

            ACTION_NEXT_PAGE -> {
                moveTaskPage(context, 1)
                updateAllWidgets(context)
            }
        }
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { id ->
            manager.updateAppWidget(id, buildViews(context))
        }
    }

    private fun buildViews(context: Context): RemoteViews {
        val state = readState(context)
        val allTasks = todayOpenTasks(state)
        val totalPages = pageCount(allTasks.size)
        val savedPage = readTaskPage(context)
        val page = savedPage.coerceIn(0, totalPages - 1)
        if (savedPage != page) writeTaskPage(context, page)
        val tasks = allTasks.drop(page * PAGE_SIZE).take(PAGE_SIZE)
        val coins = state?.optInt("coins", 0) ?: readSummaryCoins(context)
        val todayTotal = todayTaskCount(state)
        val todayDone = todayDoneCount(state)
        val progress = if (todayTotal == 0) "0%" else "${todayDone * 100 / todayTotal}%"

        val openAppIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return RemoteViews(context.packageName, R.layout.quest_note_widget).apply {
            val background = if (todayTotal > 0 && todayDone == todayTotal) {
                R.drawable.quest_widget_background_done
            } else {
                R.drawable.quest_widget_background_pending
            }
            setInt(R.id.widget_root, "setBackgroundResource", background)
            setTextViewText(R.id.widget_coin_text, "$coins xu")
            setTextViewText(R.id.widget_progress_text, "$todayDone/$todayTotal task - $progress")
            setTextViewText(R.id.widget_page_text, "${page + 1}/$totalPages")
            setOnClickPendingIntent(R.id.widget_root, openAppPendingIntent)
            setOnClickPendingIntent(R.id.widget_prev_page, pageIntent(context, ACTION_PREV_PAGE, 9001))
            setOnClickPendingIntent(R.id.widget_next_page, pageIntent(context, ACTION_NEXT_PAGE, 9002))

            if (tasks.isEmpty()) {
                setViewVisibility(R.id.widget_empty_text, View.VISIBLE)
                setViewVisibility(R.id.widget_task_grid, View.GONE)
                setTextViewText(
                    R.id.widget_empty_text,
                    if (todayTotal == 0) "Mo app de them task hom nay" else "Tat ca task hom nay da xong"
                )
            } else {
                setViewVisibility(R.id.widget_empty_text, View.GONE)
                setViewVisibility(R.id.widget_task_grid, View.VISIBLE)
            }

            bindTaskRow(context, this, 0, tasks.getOrNull(0), R.id.widget_task_row_1, R.id.widget_task_text_1, R.id.widget_task_done_1)
            bindTaskRow(context, this, 1, tasks.getOrNull(1), R.id.widget_task_row_2, R.id.widget_task_text_2, R.id.widget_task_done_2)
            bindTaskRow(context, this, 2, tasks.getOrNull(2), R.id.widget_task_row_3, R.id.widget_task_text_3, R.id.widget_task_done_3)
            bindTaskRow(context, this, 3, tasks.getOrNull(3), R.id.widget_task_row_4, R.id.widget_task_text_4, R.id.widget_task_done_4)
            bindTaskReward(this, tasks.getOrNull(0), R.id.widget_task_reward_1)
            bindTaskReward(this, tasks.getOrNull(1), R.id.widget_task_reward_2)
            bindTaskReward(this, tasks.getOrNull(2), R.id.widget_task_reward_3)
            bindTaskReward(this, tasks.getOrNull(3), R.id.widget_task_reward_4)
        }
    }

    private fun bindTaskRow(
        context: Context,
        views: RemoteViews,
        index: Int,
        task: WidgetTask?,
        rowId: Int,
        textId: Int,
        doneId: Int
    ) {
        if (task == null) {
            views.setViewVisibility(rowId, View.GONE)
            return
        }

        views.setViewVisibility(rowId, View.VISIBLE)
        views.setTextViewText(textId, task.title)
        val intent = Intent(context, QuestNoteWidgetProvider::class.java).apply {
            action = ACTION_COMPLETE_TASK
            putExtra(EXTRA_TASK_ID, task.id)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            task.id.hashCode() + index,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(doneId, pendingIntent)
    }

    private fun bindTaskReward(
        views: RemoteViews,
        task: WidgetTask?,
        rewardId: Int
    ) {
        if (task == null) return
        views.setTextViewText(rewardId, "+${task.reward} xu")
    }

    private fun completeTask(context: Context, taskId: String) {
        val state = readState(context) ?: return
        val tasks = state.optJSONArray("tasks") ?: return
        for (index in 0 until tasks.length()) {
            val task = tasks.optJSONObject(index) ?: continue
            if (task.optString("id") == taskId && !task.optBoolean("done", false)) {
                task.put("done", true)
                state.put("coins", state.optInt("coins", 0) + task.optInt("reward", 0))
                writeState(context, state)
                return
            }
        }
    }

    private fun todayOpenTasks(state: JSONObject?): List<WidgetTask> {
        if (state == null) return emptyList()
        val today = todayKey()
        val tasks = state.optJSONArray("tasks") ?: return emptyList()
        val result = mutableListOf<WidgetTask>()
        for (index in 0 until tasks.length()) {
            val task = tasks.optJSONObject(index) ?: continue
            if (task.optString("dateKey") == today && !task.optBoolean("done", false)) {
                result.add(WidgetTask(task.optString("id"), task.optString("title"), task.optInt("reward", 0)))
            }
        }
        return result
    }

    private fun moveTaskPage(context: Context, delta: Int) {
        val totalPages = pageCount(todayOpenTasks(readState(context)).size)
        val nextPage = (readTaskPage(context) + delta).coerceIn(0, totalPages - 1)
        writeTaskPage(context, nextPage)
    }

    private fun clampTaskPage(context: Context) {
        val totalPages = pageCount(todayOpenTasks(readState(context)).size)
        val page = readTaskPage(context).coerceIn(0, totalPages - 1)
        writeTaskPage(context, page)
    }

    private fun pageIntent(context: Context, actionName: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, QuestNoteWidgetProvider::class.java).apply {
            action = actionName
        }
        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun pageCount(taskCount: Int): Int {
        return maxOf(1, (taskCount + PAGE_SIZE - 1) / PAGE_SIZE)
    }

    private fun todayTaskCount(state: JSONObject?): Int {
        if (state == null) return readSummaryTotal(null)
        val today = todayKey()
        val tasks = state.optJSONArray("tasks") ?: return 0
        var count = 0
        for (index in 0 until tasks.length()) {
            val task = tasks.optJSONObject(index) ?: continue
            if (task.optString("dateKey") == today) count++
        }
        return count
    }

    private fun todayDoneCount(state: JSONObject?): Int {
        if (state == null) return 0
        val today = todayKey()
        val tasks = state.optJSONArray("tasks") ?: return 0
        var count = 0
        for (index in 0 until tasks.length()) {
            val task = tasks.optJSONObject(index) ?: continue
            if (task.optString("dateKey") == today && task.optBoolean("done", false)) count++
        }
        return count
    }

    private fun readState(context: Context): JSONObject? {
        val raw = context
            .getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .getString(STATE_KEY, null)
        if (raw.isNullOrBlank()) return null
        return runCatching { JSONObject(raw) }.getOrNull()
    }

    private fun writeState(context: Context, state: JSONObject) {
        context
            .getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(STATE_KEY, state.toString())
            .apply()
    }

    private fun updateAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, QuestNoteWidgetProvider::class.java))
        onUpdate(context, manager, ids)
    }

    private fun readSummaryCoins(context: Context): Int {
        return context.getSharedPreferences("quest_notes_widget", Context.MODE_PRIVATE).getInt("coins", 0)
    }

    private fun readSummaryTotal(context: Context?): Int {
        return context?.getSharedPreferences("quest_notes_widget", Context.MODE_PRIVATE)?.getInt("total", 0) ?: 0
    }

    private fun readTaskPage(context: Context): Int {
        return context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE).getInt(TASK_PAGE_KEY, 0)
    }

    private fun writeTaskPage(context: Context, page: Int) {
        context.getSharedPreferences(WIDGET_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putInt(TASK_PAGE_KEY, page)
            .apply()
    }

    private fun todayKey(): String {
        return SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    }

    private data class WidgetTask(val id: String, val title: String, val reward: Int)

    companion object {
        private const val PAGE_SIZE = 4
        private const val ACTION_COMPLETE_TASK = "com.example.note_app.COMPLETE_TASK"
        private const val ACTION_PREV_PAGE = "com.example.note_app.PREV_TASK_PAGE"
        private const val ACTION_NEXT_PAGE = "com.example.note_app.NEXT_TASK_PAGE"
        private const val EXTRA_TASK_ID = "task_id"
        private const val FLUTTER_PREFS = "FlutterSharedPreferences"
        private const val STATE_KEY = "flutter.quest_state_v2"
        private const val WIDGET_PREFS = "quest_notes_widget"
        private const val TASK_PAGE_KEY = "task_page"
    }
}
