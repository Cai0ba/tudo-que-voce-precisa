package br.com.tqvp.tqvp

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de favoritos. Lê de SharedPreferences (gravadas pelo Dart via
 * HomeWidget.saveWidgetData): fav_count, fav_<i>_id, fav_<i>_name, fav_<i>_cat.
 * Toque -> deep link tqvp://tool/<id> (ou tqvp://home), tratado no Dart.
 */
class FavoritesWidgetProvider : HomeWidgetProvider() {

    private val slotIds = intArrayOf(R.id.slot_0, R.id.slot_1, R.id.slot_2, R.id.slot_3)
    private val iconIds = intArrayOf(R.id.icon_0, R.id.icon_1, R.id.icon_2, R.id.icon_3)
    private val nameIds = intArrayOf(R.id.name_0, R.id.name_1, R.id.name_2, R.id.name_3)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val count = widgetData.getInt("fav_count", 0).coerceIn(0, slotIds.size)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.favorites_widget)
            val homeIntent = HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, Uri.parse("tqvp://home"),
            )
            views.setOnClickPendingIntent(R.id.widget_root, homeIntent)
            views.setViewVisibility(R.id.empty_text, if (count == 0) View.VISIBLE else View.GONE)

            for (i in slotIds.indices) {
                if (i >= count) {
                    views.setViewVisibility(slotIds[i], View.GONE)
                    continue
                }
                val id = widgetData.getString("fav_${i}_id", null)
                if (id == null) {
                    views.setViewVisibility(slotIds[i], View.GONE)
                    continue
                }
                views.setViewVisibility(slotIds[i], View.VISIBLE)
                views.setTextViewText(nameIds[i], widgetData.getString("fav_${i}_name", "") ?: "")
                views.setImageViewResource(iconIds[i], iconFor(widgetData.getString("fav_${i}_cat", null)))
                val pending = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse("tqvp://tool/$id"),
                )
                views.setOnClickPendingIntent(slotIds[i], pending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /** Ícone por categoria (IconData do Flutter não existe no lado nativo). */
    private fun iconFor(category: String?): Int = when (category) {
        "calculators" -> R.drawable.ic_widget_calculators
        "converters" -> R.drawable.ic_widget_converters
        "organization" -> R.drawable.ic_widget_organization
        "utilities" -> R.drawable.ic_widget_utilities
        else -> R.drawable.ic_widget_tool
    }
}
