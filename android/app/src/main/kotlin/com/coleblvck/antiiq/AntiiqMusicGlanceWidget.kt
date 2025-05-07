package com.coleblvck.antiiq

import HomeWidgetGlanceState
import HomeWidgetGlanceStateDefinition
import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Log
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.net.toUri
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.ActionParameters
import androidx.glance.action.ActionParameters.Key
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.LinearProgressIndicator
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.action.actionSendBroadcast
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.updateAll
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.ContentScale
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

private val TextPrimaryColorFallback = Color(0xFFFFFFFF)
private val TextSecondaryColorFallback = Color(0xFFCCCCCC)
private val ProgressBgColorFallback = Color(0xFF444444)
private val ProgressFillColorFallback = Color(0xFF007BFF)
private val OverlayColorFallback = Color(0x99000000)

val ActionTypeKey: Key<String> = Key("action_type")

class AntiiqMusicGlanceWidget : GlanceAppWidget() {

    override val stateDefinition: GlanceStateDefinition<*> get() = HomeWidgetGlanceStateDefinition()

    override val sizeMode: SizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            MusicWidgetContent(
                context = context,
                currentState = currentState()
            )
        }
    }

    private suspend fun loadBitmapFromUri(context: Context, uriString: String): Bitmap? {
        if (uriString.isEmpty()) {
            return null
        }
        return withContext(Dispatchers.IO) {
            try {
                val uri = uriString.toUri()
                context.contentResolver.openInputStream(uri)?.use { inputStream ->
                    BitmapFactory.decodeStream(inputStream)
                }
            } catch (e: Exception) {
                Log.e("AntiiqWidget", "Error loading artwork from URI: $uriString", e)
                null
            }
        }
    }

    private fun getWidgetSizeCategory(width: Int?, height: Int?): WidgetSizeCategory {
        if (width == null || height == null) return WidgetSizeCategory.SMALL

        return when {
            height >= 290.dp.value -> WidgetSizeCategory.LARGE
            width >= 180.dp.value && height < 290.dp.value -> WidgetSizeCategory.MEDIUM
            else -> WidgetSizeCategory.SMALL
        }
    }

    @SuppressLint("RestrictedApi")
    @Composable
    private fun MusicWidgetContent(
        context: Context,
        currentState: HomeWidgetGlanceState,
    ) {
        val widgetSize = LocalSize.current
        val prefs = currentState.preferences
        val title = prefs.getString("song_title", "Not Playing") ?: "Not Playing"
        val artist = prefs.getString("song_artist", "") ?: ""
        val album = prefs.getString("song_album", "") ?: ""
        val artworkUrl = prefs.getString("song_artwork", "") ?: ""
        val isPlaying = prefs.getBoolean("is_playing", false)
        val duration = prefs.getInt("song_duration", 0)
        val position = prefs.getInt("song_position", 0)
        val backgroundOpacity = prefs.getInt("background_opacity", 50)
        val coverArtBackground = prefs.getBoolean("cover_art_background", true)

        val sizeCategory = getWidgetSizeCategory(
            widgetSize.width.value.toInt(),
            widgetSize.height.value.toInt()
        )

        var artworkBitmap by remember { mutableStateOf<Bitmap?>(null) }

        LaunchedEffect(artworkUrl) {
            artworkBitmap = loadBitmapFromUri(context, artworkUrl)
        }

        val useDynamicColors = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S

        val primaryTextColor = if (useDynamicColors) {
            ColorProvider(android.R.color.system_accent1_100)
        } else {
            ColorProvider(TextPrimaryColorFallback)
        }

        val secondaryTextColor = if (useDynamicColors) {
            ColorProvider(android.R.color.system_accent1_300)
        } else {
            ColorProvider(TextSecondaryColorFallback)
        }

        val progressFillColor = if (useDynamicColors) {
            ColorProvider(android.R.color.system_accent1_100)
        } else {
            ColorProvider(ProgressFillColorFallback)
        }

        val progressBgColor = if (useDynamicColors) {
            ColorProvider(android.R.color.system_accent1_300)
        } else {
            ColorProvider(ProgressBgColorFallback)
        }

        val overlayColor = ColorProvider(OverlayColorFallback)

        val backgroundAlpha = backgroundOpacity.toFloat() / 100f

        when (sizeCategory) {
            WidgetSizeCategory.LARGE -> LargeWidgetLayout(
                context = context,
                title = title,
                artist = artist,
                album = album,
                artworkBitmap = artworkBitmap,
                isPlaying = isPlaying,
                duration = duration,
                position = position,
                primaryTextColor = primaryTextColor,
                secondaryTextColor = secondaryTextColor,
                progressFillColor = progressFillColor,
                progressBgColor = progressBgColor,
                overlayColor = overlayColor,
                backgroundAlpha = backgroundAlpha,
                coverArtBackground = coverArtBackground
            )
            WidgetSizeCategory.MEDIUM -> MediumWidgetLayout(
                context = context,
                title = title,
                artist = artist,
                artworkBitmap = artworkBitmap,
                isPlaying = isPlaying,
                duration = duration,
                position = position,
                primaryTextColor = primaryTextColor,
                secondaryTextColor = secondaryTextColor,
                progressFillColor = progressFillColor,
                progressBgColor = progressBgColor,
                overlayColor = overlayColor,
                backgroundAlpha = backgroundAlpha,
                coverArtBackground = coverArtBackground
            )
            WidgetSizeCategory.SMALL -> SmallWidgetLayout(
                context = context,
                title = title,
                artist = artist,
                artworkBitmap = artworkBitmap,
                isPlaying = isPlaying,
                duration = duration,
                position = position,
                primaryTextColor = primaryTextColor,
                secondaryTextColor = secondaryTextColor,
                progressFillColor = progressFillColor,
                progressBgColor = progressBgColor,
                backgroundAlpha = backgroundAlpha,
                coverArtBackground = coverArtBackground
            )
        }
    }

    @Composable
    private fun SmallWidgetLayout(
        context: Context,
        title: String,
        artist: String,
        artworkBitmap: Bitmap?,
        isPlaying: Boolean,
        duration: Int,
        position: Int,
        primaryTextColor: ColorProvider,
        secondaryTextColor: ColorProvider,
        progressFillColor: ColorProvider,
        progressBgColor: ColorProvider,
        backgroundAlpha: Float,
        coverArtBackground: Boolean
    ) {
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .appWidgetBackground()
                .cornerRadius(16.dp)
                .clickable(actionSendBroadcast(Intent(context, AntiiqMusicGlanceWidgetReceiver::class.java).apply {
                    action = AntiiqMusicGlanceWidgetReceiver.ACTION_OPEN_APP
                }))
        ) {
            if (coverArtBackground && artworkBitmap != null) {
                Image(
                    provider = ImageProvider(artworkBitmap),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().background(Color.Black.copy(alpha = backgroundAlpha))
                )
            } else {
                Image(
                    provider = ImageProvider(R.drawable.widget_background),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().background(Color.Transparent)
                )
            }

            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(if (coverArtBackground) Color.Black.copy(alpha = (1f - backgroundAlpha)) else Color.Black.copy(alpha = backgroundAlpha))
            ) {}

            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (artworkBitmap != null) {
                        Image(
                            provider = ImageProvider(artworkBitmap),
                            contentDescription = "Album artwork",
                            modifier = GlanceModifier.size(48.dp).cornerRadius(8.dp)
                        )
                    } else {
                        Image(
                            provider = ImageProvider(R.drawable.default_artwork),
                            contentDescription = "Album artwork",
                            modifier = GlanceModifier.size(48.dp).cornerRadius(8.dp)
                        )
                    }

                    Column(
                        modifier = GlanceModifier
                            .padding(start = 12.dp)
                            .fillMaxWidth()
                    ) {
                        Text(
                            text = title,
                            style = TextStyle(
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                color = primaryTextColor
                            ),
                            maxLines = 1
                        )

                        if (artist.isNotEmpty()) {
                            Text(
                                text = artist,
                                style = TextStyle(
                                    fontSize = 12.sp,
                                    color = secondaryTextColor
                                ),
                                maxLines = 1
                            )
                        }

                        if (duration > 0) {
                            val progress = (position.toFloat() / duration.toFloat()).coerceIn(0f, 1f)
                            LinearProgressIndicator(
                                progress = progress,
                                modifier = GlanceModifier
                                    .fillMaxWidth()
                                    .height(3.dp)
                                    .padding(top = 4.dp),
                                color = progressFillColor,
                                backgroundColor = progressBgColor
                            )
                        }
                    }
                }

                Spacer(GlanceModifier.height(8.dp))

                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_previous),
                        contentDescription = "Previous",
                        modifier = GlanceModifier
                            .size(28.dp)
                            .clickable(
                                onClick = actionRunCallback<InteractiveAction>(
                                    parameters = actionParametersOf(ActionTypeKey to "previous")
                                )
                            )
                    )

                    Spacer(GlanceModifier.width(20.dp))

                    Box (GlanceModifier.background(secondaryTextColor).cornerRadius(24.dp)) {
                        Image(
                            provider = ImageProvider(if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play),
                            contentDescription = if (isPlaying) "Pause" else "Play",
                            modifier = GlanceModifier
                                .size(32.dp).padding(4.dp)
                                .clickable(
                                    onClick = actionRunCallback<InteractiveAction>(
                                        parameters = actionParametersOf(ActionTypeKey to "play_pause")
                                    )
                                )
                        )
                    }

                    Spacer(GlanceModifier.width(20.dp))

                    Image(
                        provider = ImageProvider(R.drawable.ic_next),
                        contentDescription = "Next",
                        modifier = GlanceModifier
                            .size(28.dp)
                            .clickable(
                                onClick = actionRunCallback<InteractiveAction>(
                                    parameters = actionParametersOf(ActionTypeKey to "next")
                                )
                            )
                    )
                }
            }
        }
    }

    @Composable
    private fun MediumWidgetLayout(
        context: Context,
        title: String,
        artist: String,
        artworkBitmap: Bitmap?,
        isPlaying: Boolean,
        duration: Int,
        position: Int,
        primaryTextColor: ColorProvider,
        secondaryTextColor: ColorProvider,
        progressFillColor: ColorProvider,
        progressBgColor: ColorProvider,
        overlayColor: ColorProvider,
        backgroundAlpha: Float,
        coverArtBackground: Boolean
    ) {
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .appWidgetBackground()
                .cornerRadius(16.dp)
                .clickable(actionSendBroadcast(Intent(context, AntiiqMusicGlanceWidgetReceiver::class.java).apply {
                    action = AntiiqMusicGlanceWidgetReceiver.ACTION_OPEN_APP
                }))
        ) {
            if (coverArtBackground && artworkBitmap != null) {
                Image(
                    provider = ImageProvider(artworkBitmap),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().background(Color.Black.copy(alpha = backgroundAlpha))
                )
            } else {
                Image(
                    provider = ImageProvider(R.drawable.widget_background),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().background(Color.Transparent)
                )
            }

            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(if (coverArtBackground) Color.Black.copy(alpha = (1f - backgroundAlpha)) else Color.Black.copy(alpha = backgroundAlpha))
            ) {}

            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth().defaultWeight(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    if (artworkBitmap != null) {
                        Image(
                            provider = ImageProvider(artworkBitmap),
                            contentDescription = "Album artwork",
                            modifier = GlanceModifier.size(64.dp).cornerRadius(10.dp)
                        )
                    } else {
                        Image(
                            provider = ImageProvider(R.drawable.default_artwork),
                            contentDescription = "Album artwork",
                            modifier = GlanceModifier.size(64.dp).cornerRadius(10.dp)
                        )
                    }

                    Column(
                        modifier = GlanceModifier
                            .padding(start = 16.dp)
                            .fillMaxWidth()
                    ) {
                        Text(
                            text = title,
                            style = TextStyle(
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = primaryTextColor
                            ),
                            maxLines = 1
                        )

                        if (artist.isNotEmpty()) {
                            Text(
                                text = artist,
                                style = TextStyle(
                                    fontSize = 14.sp,
                                    color = secondaryTextColor
                                ),
                                maxLines = 1
                            )
                        }
                    }
                }

                if (duration > 0) {
                    val progress = (position.toFloat() / duration.toFloat()).coerceIn(0f, 1f)

                    Spacer(GlanceModifier.height(8.dp))

                    LinearProgressIndicator(
                        progress = progress,
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .height(4.dp),
                        color = progressFillColor,
                        backgroundColor = progressBgColor
                    )

                    Row(
                        modifier = GlanceModifier.fillMaxWidth(),
                        horizontalAlignment = Alignment.Start
                    ) {
                        Text(
                            text = formatDuration(position),
                            style = TextStyle(
                                fontSize = 12.sp,
                                color = secondaryTextColor
                            )
                        )

                        Spacer(GlanceModifier.defaultWeight())

                        Text(
                            text = formatDuration(duration),
                            style = TextStyle(
                                fontSize = 12.sp,
                                color = secondaryTextColor
                            )
                        )
                    }
                }

                Spacer(GlanceModifier.height(16.dp))

                Row(
                    modifier = GlanceModifier.fillMaxWidth().defaultWeight(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_previous),
                        contentDescription = "Previous",
                        modifier = GlanceModifier
                            .size(36.dp)
                            .clickable(
                                onClick = actionRunCallback<InteractiveAction>(
                                    parameters = actionParametersOf(ActionTypeKey to "previous")
                                )
                            )
                    )

                    Spacer(GlanceModifier.width(24.dp))

                    Box (GlanceModifier.background(secondaryTextColor).cornerRadius(24.dp)) {
                        Image(
                            provider = ImageProvider(if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play),
                            contentDescription = if (isPlaying) "Pause" else "Play",
                            modifier = GlanceModifier
                                .size(44.dp).padding(4.dp)
                                .clickable(
                                    onClick = actionRunCallback<InteractiveAction>(
                                        parameters = actionParametersOf(ActionTypeKey to "play_pause")
                                    )
                                )
                        )
                    }

                    Spacer(GlanceModifier.width(24.dp))

                    Image(
                        provider = ImageProvider(R.drawable.ic_next),
                        contentDescription = "Next",
                        modifier = GlanceModifier
                            .size(36.dp)
                            .clickable(
                                onClick = actionRunCallback<InteractiveAction>(
                                    parameters = actionParametersOf(ActionTypeKey to "next")
                                )
                            )
                    )
                }
            }
        }
    }

    @Composable
    private fun LargeWidgetLayout(
        context: Context,
        title: String,
        artist: String,
        album: String,
        artworkBitmap: Bitmap?,
        isPlaying: Boolean,
        duration: Int,
        position: Int,
        primaryTextColor: ColorProvider,
        secondaryTextColor: ColorProvider,
        progressFillColor: ColorProvider,
        progressBgColor: ColorProvider,
        overlayColor: ColorProvider,
        backgroundAlpha: Float,
        coverArtBackground: Boolean
    ) {
        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .appWidgetBackground()
                .cornerRadius(16.dp)
                .clickable(actionSendBroadcast(Intent(context, AntiiqMusicGlanceWidgetReceiver::class.java).apply {
                    action = AntiiqMusicGlanceWidgetReceiver.ACTION_OPEN_APP
                }))
        ) {
            if (coverArtBackground && artworkBitmap != null) {
                Image(
                    provider = ImageProvider(artworkBitmap),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().background(Color.Black.copy(alpha = backgroundAlpha))
                )
            } else {
                Image(
                    provider = ImageProvider(R.drawable.widget_background),
                    contentDescription = null,
                    contentScale = ContentScale.Crop,
                    modifier = GlanceModifier.fillMaxSize().background(Color.Transparent)
                )
            }

            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(if (coverArtBackground) Color.Black.copy(alpha = (1f - backgroundAlpha)) else Color.Black.copy(alpha = backgroundAlpha))
            ) {}

            Column(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (artworkBitmap != null) {
                    Image(
                        provider = ImageProvider(artworkBitmap),
                        contentDescription = "Album artwork",
                        modifier = GlanceModifier
                            .size(100.dp)
                            .cornerRadius(12.dp)
                    )
                } else {
                    Image(
                        provider = ImageProvider(R.drawable.default_artwork),
                        contentDescription = "Album artwork",
                        modifier = GlanceModifier
                            .size(100.dp)
                            .cornerRadius(12.dp)
                    )
                }

                Spacer(GlanceModifier.height(16.dp))

                Text(
                    text = title,
                    style = TextStyle(
                        fontWeight = FontWeight.Bold,
                        fontSize = 20.sp,
                        color = primaryTextColor,
                        textAlign = TextAlign.Center
                    ),
                    maxLines = 1
                )

                if (artist.isNotEmpty()) {
                    Text(
                        text = artist,
                        style = TextStyle(
                            fontSize = 16.sp,
                            color = secondaryTextColor,
                            textAlign = TextAlign.Center
                        ),
                        maxLines = 1
                    )
                }

                if (album.isNotEmpty()) {
                    Text(
                        text = album,
                        style = TextStyle(
                            fontSize = 14.sp,
                            color = secondaryTextColor,
                            textAlign = TextAlign.Center
                        ),
                        maxLines = 1
                    )
                }

                Spacer(GlanceModifier.height(16.dp))

                if (duration > 0) {
                    val progress = (position.toFloat() / duration.toFloat()).coerceIn(0f, 1f)

                    LinearProgressIndicator(
                        progress = progress,
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .height(5.dp),
                        color = progressFillColor,
                        backgroundColor = progressBgColor
                    )

                    Row(
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .padding(top = 4.dp),
                        horizontalAlignment = Alignment.Start
                    ) {
                        Text(
                            text = formatDuration(position),
                            style = TextStyle(
                                fontSize = 12.sp,
                                color = secondaryTextColor
                            )
                        )

                        Spacer(GlanceModifier.defaultWeight())

                        Text(
                            text = formatDuration(duration),
                            style = TextStyle(
                                fontSize = 12.sp,
                                color = secondaryTextColor
                            )
                        )
                    }
                }

                Spacer(GlanceModifier.height(20.dp))

                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_previous),
                        contentDescription = "Previous",
                        modifier = GlanceModifier
                            .size(40.dp)
                            .clickable(
                                onClick = actionRunCallback<InteractiveAction>(
                                    parameters = actionParametersOf(ActionTypeKey to "previous")
                                )
                            )
                    )

                    Spacer(GlanceModifier.width(30.dp))

                    Box (GlanceModifier.background(secondaryTextColor).cornerRadius(24.dp)) {
                        Image(
                            provider = ImageProvider(if (isPlaying) R.drawable.ic_pause else R.drawable.ic_play),
                            contentDescription = if (isPlaying) "Pause" else "Play",
                            modifier = GlanceModifier
                                .size(52.dp).padding(4.dp)
                                .clickable(
                                    onClick = actionRunCallback<InteractiveAction>(
                                        parameters = actionParametersOf(ActionTypeKey to "play_pause")
                                    )
                                )
                        )
                    }

                    Spacer(GlanceModifier.width(30.dp))

                    Image(
                        provider = ImageProvider(R.drawable.ic_next),
                        contentDescription = "Next",
                        modifier = GlanceModifier
                            .size(40.dp)
                            .clickable(
                                onClick = actionRunCallback<InteractiveAction>(
                                    parameters = actionParametersOf(ActionTypeKey to "next")
                                )
                            )
                    )
                }
            }
        }
    }

    private fun formatDuration(milliseconds: Int): String {
        val totalSeconds = milliseconds / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        return "%d:%02d".format(minutes, seconds)
    }
}

enum class WidgetSizeCategory {
    SMALL,
    MEDIUM,
    LARGE
}

class InteractiveAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val actionType = parameters[ActionTypeKey]

        if (actionType != null) {
            Log.d("InteractiveAction", "Glance Action received with type: $actionType")

            val uri = "antiiqwidget://$actionType".toUri()

            val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context, uri)
            backgroundIntent.send()

            AntiiqMusicGlanceWidget().updateAll(context)
        } else {
            Log.e("InteractiveAction", "Error: ActionTypeKey parameter missing in Glance action.")
        }
    }
}