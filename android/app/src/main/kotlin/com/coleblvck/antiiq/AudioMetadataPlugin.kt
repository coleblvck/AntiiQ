package com.coleblvck.antiiq

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.provider.OpenableColumns
import android.os.Handler
import android.os.Environment
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import androidx.core.net.toUri

class AudioMetadataPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val mainHandler = Handler(Looper.getMainLooper())

    private external fun extractNativeMetadata(path: String): Map<String, Any?>?
    private external fun extractNativeArtwork(path: String): ByteArray?

    companion object {
        private const val CHANNEL_NAME = "com.coleblvck.antiiq/audio_metadata"
        private val AUDIO_EXTENSIONS = setOf(
            "mp3", "mp2", "mp1", "m4a", "aac", "flac", "alac", "ape",
            "wv", "tta", "tak", "ogg", "oga", "opus", "spx", "wav",
            "aiff", "aif", "aifc", "wma", "mpc", "mp+", "mpp"
        )
        private val VIDEO_EXTENSIONS = setOf(
            "mka", "webm", "mp4", "mkv", "avi", "mov", "flv"
        )
    private val SYSTEM_EXCLUDED_PATHS = setOf(
        ".thumbnails",
        ".cache",
        ".trash",
        "android/data",
        "android/obb",
        ".recycle_bin",
        ".android_secure",
        "lost.dir",
        "notifications",
        "ringtones",
        "alarms",
        "podcasts",
        "recordings",
        "voice recorder",
        "voice recordings",
        "call recordings",
        "whatsapp/Media/WhatsApp Voice Notes".lowercase(),
        "whatsapp business/Media/WhatsApp Business Voice Notes".lowercase(),
        "telegram/telegram audio"
    )

        @Volatile
        private var nativeLibrariesLoaded = false

        private fun ensureNativeLibrariesLoaded() {
            if (nativeLibrariesLoaded) return
            synchronized(this) {
                if (nativeLibrariesLoaded) return
                loadNativeLibrary("avutil")
                loadNativeLibrary("swresample")
                loadNativeLibrary("avcodec")
                loadNativeLibrary("avformat")
                loadNativeLibrary("SoundTouch")
                loadNativeLibrary("antiiq-lite")
                nativeLibrariesLoaded = true
            }
        }

        private fun loadNativeLibrary(name: String) {
            try {
                System.loadLibrary(name)
            } catch (e: UnsatisfiedLinkError) {
                println("Could not load native library $name: ${e.message}")
            }
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "scanAllStorageWithMetadata" -> {
                val knownPaths = call.argument<List<String>>("knownPaths") ?: emptyList()
                scope.launch {
                    try {
                        val files = scanAllStorageWithMetadata(knownPaths)
                        withContext(Dispatchers.Main) {
                            result.success(files)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("SCAN_ERROR", e.message, null)
                        }
                    }
                }
            }

            "scanDirectoryWithMetadata" -> {
                val path = call.argument<String>("path")
                val recursive = call.argument<Boolean>("recursive") ?: true
                val knownPaths = call.argument<List<String>>("knownPaths") ?: emptyList()
                if (path != null) {
                    scope.launch {
                        try {
                            val files = scanDirectoryWithMetadata(path, recursive, knownPaths)
                            withContext(Dispatchers.Main) {
                                result.success(files)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("SCAN_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Path is required", null)
                }
            }

            "getMetadata" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    scope.launch {
                        try {
                            val metadata = getMetadataFromFile(path)
                            withContext(Dispatchers.Main) {
                                result.success(metadata)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("METADATA_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Path is required", null)
                }
            }

            "getMetadataFromContentUri" -> {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    scope.launch {
                        try {
                            val metadata = getMetadataFromContentUri(uriString)
                            withContext(Dispatchers.Main) {
                                result.success(metadata)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("METADATA_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "URI is required", null)
                }
            }

            "prepareIntentAudio" -> {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    scope.launch {
                        try {
                            val prepared = prepareIntentAudio(uriString)
                            withContext(Dispatchers.Main) {
                                result.success(prepared)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("INTENT_AUDIO_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "URI is required", null)
                }
            }

            "extractArtwork" -> {
                val path = call.argument<String>("path")
                val quality = call.argument<Int>("quality") ?: 90
                if (path != null) {
                    scope.launch {
                        try {
                            val artwork = extractArtwork(path, quality)
                            withContext(Dispatchers.Main) {
                                result.success(artwork)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("ARTWORK_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Path is required", null)
                }
            }

            "extractArtworkFromContentUri" -> {
                val uriString = call.argument<String>("uri")
                val quality = call.argument<Int>("quality") ?: 90
                if (uriString != null) {
                    scope.launch {
                        try {
                            val artwork = extractArtworkFromContentUri(uriString, quality)
                            withContext(Dispatchers.Main) {
                                result.success(artwork)
                            }
                        } catch (e: Exception) {
                            withContext(Dispatchers.Main) {
                                result.error("ARTWORK_ERROR", e.message, null)
                            }
                        }
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "URI is required", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private suspend fun scanDirectoryWithMetadata(
        path: String,
        recursive: Boolean,
        knownPaths: List<String> = emptyList(),
    ): List<Map<String, Any?>> {
        val audioFiles = mutableListOf<Map<String, Any?>>()
        val directory = File(path)
        val knownPathSet = knownPaths.map { normalizePath(it) }.toSet()

        if (!directory.exists() || !directory.isDirectory) {
            return audioFiles
        }

        val files = if (recursive) {
            scanAudioFiles(listOf(directory), "Scanning Selected Folders")
        } else {
            directory.listFiles()
                ?.filter { it.isFile && it.canRead() && isAudioFile(it) }
                ?: emptyList()
        }

        files.forEachIndexed { index, file ->
            if (normalizePath(file.absolutePath) in knownPathSet) return@forEachIndexed
            if (index == 0 || (index + 1) % 25 == 0 || index == files.lastIndex) {
                emitProgress("metadata", index + 1, files.size, "Reading Metadata")
            }
            try {
                audioFiles.add(getMetadataFromFile(file.absolutePath))
                if (audioFiles.size % 20 == 0) {
                    emitMetadataBatch(audioFiles.takeLast(20))
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        emitMetadataBatch(audioFiles.takeLast(audioFiles.size % 20))

        return audioFiles
    }

    private suspend fun scanAllStorageWithMetadata(knownPaths: List<String> = emptyList()): List<Map<String, Any?>> {
        val audioFiles = mutableListOf<Map<String, Any?>>()
        addFilesystemAudioWithMetadata(audioFiles, knownPaths = knownPaths)
        return audioFiles
    }

    private suspend fun addFilesystemAudioWithMetadata(
        audioFiles: MutableList<Map<String, Any?>>,
        roots: List<String>? = null,
        knownPaths: List<String> = emptyList(),
    ) {
        val seenPaths = audioFiles.mapNotNull { it["path"] as? String }
            .map { normalizePath(it) }
            .toMutableSet()
        val knownPathSet = knownPaths.map { normalizePath(it) }.toSet()

        val scanRoots = roots
            ?.map { File(it) }
            ?.filter { it.exists() && it.isDirectory && it.canRead() }
            ?: getStorageRoots()

        val files = scanAudioFiles(scanRoots, "Scanning Storage")
        files.forEachIndexed { index, file ->
            val key = normalizePath(file.absolutePath)
            if (!seenPaths.add(key)) return@forEachIndexed
            if (key in knownPathSet) return@forEachIndexed

            if (index == 0 || (index + 1) % 25 == 0 || index == files.lastIndex) {
                emitProgress("metadata", index + 1, files.size, "Reading Metadata")
            }
            try {
                audioFiles.add(getMetadataFromFile(file.absolutePath))
                if (audioFiles.size % 20 == 0) {
                    emitMetadataBatch(audioFiles.takeLast(20))
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        emitMetadataBatch(audioFiles.takeLast(audioFiles.size % 20))
    }

    private suspend fun scanAudioFiles(roots: List<File>, message: String): List<File> = coroutineScope {
        val results = ConcurrentHashMap.newKeySet<File>()
        val workQueue = ArrayDeque<File>()
        val filesFound = AtomicInteger(0)
        emitProgress("scanning", 0, 0, message)

        roots.filter { it.exists() && it.canRead() }.forEach {
            synchronized(workQueue) { workQueue.add(it) }
        }

        val workers = List(Runtime.getRuntime().availableProcessors().coerceAtLeast(2)) {
            async(Dispatchers.IO) {
                var localCount = 0
                while (true) {
                    val dir = synchronized(workQueue) { workQueue.removeFirstOrNull() } ?: break
                    val normalizedPath = dir.absolutePath.lowercase()
                    if (SYSTEM_EXCLUDED_PATHS.any {
                            normalizedPath.contains("/$it") || normalizedPath.endsWith("/$it")
                        }) {
                        continue
                    }
                    if (dir.name.startsWith(".")) continue

                    try {
                        val entries = dir.listFiles() ?: continue
                        val newDirs = mutableListOf<File>()
                        for (entry in entries) {
                            when {
                                entry.isDirectory && entry.canRead() -> newDirs.add(entry)
                                entry.isFile && isAudioFile(entry) -> {
                                    results.add(entry)
                                    localCount++
                                    val found = filesFound.incrementAndGet()
                                    if (found == 1 || found % 50 == 0) {
                                        emitProgress("scanning", found, 0, message)
                                    }
                                }
                            }
                        }
                        if (newDirs.isNotEmpty()) {
                            synchronized(workQueue) { workQueue.addAll(newDirs) }
                        }
                    } catch (e: SecurityException) {
                        Log.w("AudioMetadataPlugin", "Cannot access: ${dir.absolutePath}")
                    }
                }
            }
        }

        workers.awaitAll()
        emitProgress("scanning", results.size, results.size, message)
        results.toList()
    }

    private fun getStorageRoots(): List<File> {
        val roots = mutableListOf<File>()
        addPrimaryStorage(roots)
        addStorageDirectVolumes(roots)
        addExternalFilesVolumes(roots)
        return roots.distinctBy { it.absolutePath }
            .filter { it.exists() && it.isDirectory && it.canRead() }
    }

    private fun addPrimaryStorage(roots: MutableList<File>) {
        Environment.getExternalStorageDirectory()?.let { dir ->
            if (dir.exists() && dir.canRead()) roots.add(dir)
        }
    }

    private fun addStorageDirectVolumes(roots: MutableList<File>) {
        try {
            File("/storage").listFiles()?.forEach { volume ->
                if (volume.isDirectory &&
                    volume.name != "emulated" &&
                    volume.name != "self" &&
                    volume.canRead() &&
                    volume !in roots
                ) {
                    roots.add(volume)
                }
            }
        } catch (e: Exception) {
            Log.w("AudioMetadataPlugin", "Failed to scan /storage", e)
        }
    }

    private fun addExternalFilesVolumes(roots: MutableList<File>) {
        try {
            context.getExternalFilesDirs(null).filterNotNull().forEach { appDir ->
                val storageRoot = walkUpToStorageRoot(appDir)
                if (storageRoot != null && storageRoot.canRead() && storageRoot !in roots) {
                    roots.add(storageRoot)
                }
            }
        } catch (e: Exception) {
            Log.e("AudioMetadataPlugin", "getExternalFilesDirs error", e)
        }
    }

    private fun walkUpToStorageRoot(appDir: File): File? {
        var current = appDir
        var depth = 0

        while (current.parentFile != null && depth < 20) {
            current = current.parentFile!!
            depth++

            val name = current.name
            if ((name.matches(Regex("[0-9A-F]{4}-[0-9A-F]{4}")) || name == "emulated" || name == "0") && current.canRead()) {
                return if (name == "emulated" || name == "0") {
                    current.parentFile ?: current
                } else {
                    current
                }
            }
        }

        return null
    }

    private fun normalizePath(path: String): String {
        return try {
            File(path).canonicalPath
        } catch (e: Exception) {
            File(path).absolutePath
        }
    }

    private fun isAudioFile(file: File): Boolean {
        val extension = file.extension.lowercase()
        return AUDIO_EXTENSIONS.contains(extension) && !VIDEO_EXTENSIONS.contains(extension)
    }

    private fun emitProgress(stage: String, progress: Int, total: Int, message: String) {
        if (!::channel.isInitialized) return
        mainHandler.post {
            channel.invokeMethod(
                "scanProgress",
                mapOf(
                    "stage" to stage,
                    "progress" to progress,
                    "total" to total,
                    "message" to message
                )
            )
        }
    }

    private fun emitMetadataBatch(batch: List<Map<String, Any?>>) {
        if (!::channel.isInitialized || batch.isEmpty()) return
        mainHandler.post {
            channel.invokeMethod("scanMetadataBatch", batch)
        }
    }

    private fun getMetadataFromFile(path: String): Map<String, Any?> {
        val native = try {
            ensureNativeLibrariesLoaded()
            extractNativeMetadata(path)
        } catch (e: UnsatisfiedLinkError) {
            null
        } catch (e: Exception) {
            null
        }

        if (native != null) {
            val artist = native["artist"] as? String ?: "Unknown Artist"
            return mapOf(
                "path" to path,
                "title" to (native["title"] as? String ?: File(path).nameWithoutExtension),
                "artist" to artist,
                "album" to (native["album"] as? String ?: "Unknown Album"),
                "albumArtist" to (native["albumArtist"] as? String ?: artist),
                "genre" to (native["genre"] as? String ?: "Unknown Genre"),
                "year" to native["year"],
                "trackNumber" to (native["trackNumber"] ?: 0),
                "composer" to native["composer"],
                "writer" to native["writer"],
                "duration" to (native["duration"] ?: 0L),
                "bitrate" to native["bitrate"],
                "mimeType" to native["mimeType"],
                "fileExtension" to File(path).extension
            )
        }

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)

            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull() ?: 0L
            val title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
                ?: File(path).nameWithoutExtension
            val artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
                ?: "Unknown Artist"
            val album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)
                ?: "Unknown Album"
            val albumArtist =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST)
                    ?: artist
            val genre = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_GENRE)
                ?: "Unknown Genre"
            val year =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_YEAR)?.toIntOrNull()
            val trackNumber =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER)
            val composer = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COMPOSER)
            val writer = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_WRITER)
            val bitrate = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)
                ?.toIntOrNull()
            val mimeType = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)

            val trackNum = trackNumber?.split("/")?.firstOrNull()?.toIntOrNull() ?: 0

            return mapOf(
                "path" to path,
                "title" to title,
                "artist" to artist,
                "album" to album,
                "albumArtist" to albumArtist,
                "genre" to genre,
                "year" to year,
                "trackNumber" to trackNum,
                "composer" to composer,
                "writer" to writer,
                "duration" to duration,
                "bitrate" to bitrate,
                "mimeType" to mimeType,
                "fileExtension" to File(path).extension
            )
        } finally {
            retriever.release()
        }
    }

    private fun extractArtwork(path: String, quality: Int): ByteArray? {
        val nativeArt = try {
            ensureNativeLibrariesLoaded()
            extractNativeArtwork(path)
        } catch (e: UnsatisfiedLinkError) {
            null
        } catch (e: Exception) {
            null
        }

        if (nativeArt != null) {
            if (quality < 100) {
                val bitmap = BitmapFactory.decodeByteArray(nativeArt, 0, nativeArt.size)
                val outputStream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                return outputStream.toByteArray()
            }
            return nativeArt
        }

        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val rawArt = retriever.embeddedPicture

            if (rawArt != null && quality < 100) {
                val bitmap = BitmapFactory.decodeByteArray(rawArt, 0, rawArt.size)
                val outputStream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                return outputStream.toByteArray()
            }

            return rawArt
        } finally {
            retriever.release()
        }
    }

    private fun getMetadataFromContentUri(uriString: String): Map<String, Any?> {
        val uri = uriString.toUri()
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(context, uri)

            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
                ?.toLongOrNull() ?: 0L
            val title = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE)
                ?: "Unknown Title"
            val artist = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST)
                ?: "Unknown Artist"
            val album = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM)
                ?: "Unknown Album"
            val albumArtist =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST)
                    ?: artist
            val genre = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_GENRE)
                ?: "Unknown Genre"
            val year =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_YEAR)?.toIntOrNull()
            val trackNumber =
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER)
            val composer = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_COMPOSER)
            val writer = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_WRITER)
            val bitrate = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_BITRATE)
                ?.toIntOrNull()
            val mimeType = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_MIMETYPE)

            val trackNum = trackNumber?.split("/")?.firstOrNull()?.toIntOrNull() ?: 0

            return mapOf(
                "path" to uriString,
                "title" to title,
                "artist" to artist,
                "album" to album,
                "albumArtist" to albumArtist,
                "genre" to genre,
                "year" to year,
                "trackNumber" to trackNum,
                "composer" to composer,
                "writer" to writer,
                "duration" to duration,
                "bitrate" to bitrate,
                "mimeType" to mimeType,
                "fileExtension" to getFileExtensionFromMimeType(mimeType)
            )
        } finally {
            retriever.release()
        }
    }

    private fun prepareIntentAudio(uriString: String): Map<String, Any?> {
        val uri = uriString.toUri()
        if (uri.scheme == "file") {
            val path = uri.path ?: uriString.removePrefix("file://")
            return mapOf(
                "path" to path,
                "displayName" to File(path).name,
                "mimeType" to context.contentResolver.getType(uri)
            )
        }

        if (uri.scheme != "content") {
            return mapOf(
                "path" to uriString,
                "displayName" to File(uriString).name,
                "mimeType" to null
            )
        }

        val displayName = queryDisplayName(uri) ?: "intent_audio_${System.currentTimeMillis()}"
        val extension = displayName.substringAfterLast('.', "")
            .ifBlank { extensionFromMime(context.contentResolver.getType(uri)) }
            .ifBlank { "audio" }
        val safeBaseName = displayName
            .substringBeforeLast('.', displayName)
            .replace(Regex("[^A-Za-z0-9._-]+"), "_")
            .trim('_')
            .ifBlank { "intent_audio" }
        val cacheDir = File(context.cacheDir, "intent_audio").apply {
            mkdirs()
        }
        cacheDir.listFiles()?.forEach { file ->
            if (System.currentTimeMillis() - file.lastModified() > 24L * 60L * 60L * 1000L) {
                file.delete()
            }
        }
        val target = File(cacheDir, "${safeBaseName}_${System.currentTimeMillis()}.$extension")

        context.contentResolver.openInputStream(uri).use { input ->
            if (input == null) {
                throw IllegalArgumentException("Unable to open intent audio stream")
            }
            FileOutputStream(target).use { output ->
                input.copyTo(output)
            }
        }

        return mapOf(
            "path" to target.absolutePath,
            "displayName" to displayName,
            "mimeType" to context.contentResolver.getType(uri)
        )
    }

    private fun queryDisplayName(uri: android.net.Uri): String? {
        context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0) return cursor.getString(index)
                }
            }
        return null
    }

    private fun extensionFromMime(mimeType: String?): String {
        return when (mimeType) {
            "audio/mpeg" -> "mp3"
            "audio/mp4", "audio/m4a", "audio/x-m4a" -> "m4a"
            "audio/flac", "audio/x-flac" -> "flac"
            "audio/ogg" -> "ogg"
            "audio/wav", "audio/x-wav" -> "wav"
            "audio/aac" -> "aac"
            "audio/opus" -> "opus"
            "audio/x-ms-wma" -> "wma"
            else -> ""
        }
    }

    private fun extractArtworkFromContentUri(uriString: String, quality: Int): ByteArray? {
        val uri = uriString.toUri()
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(context, uri)
            val rawArt = retriever.embeddedPicture

            if (rawArt != null && quality < 100) {
                val bitmap = BitmapFactory.decodeByteArray(rawArt, 0, rawArt.size)
                val outputStream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                return outputStream.toByteArray()
            }

            return rawArt
        } finally {
            retriever.release()
        }
    }

    private fun getFileExtensionFromMimeType(mimeType: String?): String {
        return when (mimeType) {
            "audio/mpeg" -> "mp3"
            "audio/mp4", "audio/m4a" -> "m4a"
            "audio/flac" -> "flac"
            "audio/ogg" -> "ogg"
            "audio/wav", "audio/x-wav" -> "wav"
            "audio/aac" -> "aac"
            "audio/opus" -> "opus"
            else -> "mp3"
        }
    }
}
