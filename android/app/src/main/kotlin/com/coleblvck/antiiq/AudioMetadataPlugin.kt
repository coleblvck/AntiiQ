package com.coleblvck.antiiq

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import androidx.core.net.toUri

class AudioMetadataPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    companion object {
        private const val CHANNEL_NAME = "com.coleblvck.antiiq/audio_metadata"
        private val AUDIO_EXTENSIONS = setOf(
            "mp3", "m4a", "aac", "ogg", "oga", "opus",
            "flac", "wav", "wma", "wv", "ape", "mka"
        )
        private val VIDEO_EXTENSIONS = setOf(
            "mp4", "3gp", "mkv", "avi", "mov", "wmv", "flv", "webm"
        )
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
            "getAllAudioFilesWithMetadata" -> {
                scope.launch {
                    try {
                        val files = getAllAudioFilesWithMetadataFromMediaStore()
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

            "getAudioFilesWithMetadataFromPaths" -> {
                val paths = call.argument<List<String>>("paths")
                if (paths != null) {
                    scope.launch {
                        try {
                            val files = getAudioFilesWithMetadataFromPaths(paths)
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
                    result.error("INVALID_ARGUMENT", "Paths are required", null)
                }
            }

            "scanDirectoryWithMetadata" -> {
                val path = call.argument<String>("path")
                val recursive = call.argument<Boolean>("recursive") ?: true
                if (path != null) {
                    scope.launch {
                        try {
                            val files = scanDirectoryWithMetadata(path, recursive)
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

            "scanDirectory" -> {
                val path = call.argument<String>("path")
                val recursive = call.argument<Boolean>("recursive") ?: true
                if (path != null) {
                    scope.launch {
                        try {
                            val files = scanDirectory(path, recursive)
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

            "getAllAudioFiles" -> {
                scope.launch {
                    try {
                        val files = getAllAudioFilesFromMediaStore()
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

            "getMediaStoreArtwork" -> {
                val albumId = call.argument<Long>("albumId")
                val quality = call.argument<Int>("quality") ?: 90
                if (albumId != null) {
                    scope.launch {
                        try {
                            val artwork = getMediaStoreArtwork(albumId, quality)
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
                    result.error("INVALID_ARGUMENT", "Album ID is required", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun getAllAudioFilesWithMetadataFromMediaStore(): List<Map<String, Any?>> {
        val startTime = System.currentTimeMillis()
        val audioFiles = mutableListOf<Map<String, Any?>>()

        val projection = arrayOf(
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ARTIST,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.COMPOSER,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.ALBUM_ID
        )

        //TODO: ADD ARGUMENT FOR SELECTION FILTER FROM DART
        //val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        try {
            val queryStart = System.currentTimeMillis()
            context.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                null
            )?.use { cursor ->
                val queryEnd = System.currentTimeMillis()
                println("MediaStore query took: ${queryEnd - queryStart}ms")

                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                val albumColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                val albumArtistColumn = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM_ARTIST)
                val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                val trackColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
                val yearColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)
                val genreColumn = cursor.getColumnIndex(MediaStore.Audio.Media.GENRE)
                val composerColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.COMPOSER)
                val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)
                val albumIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

                val iterationStart = System.currentTimeMillis()
                while (cursor.moveToNext()) {
                    val path = cursor.getString(dataColumn)

                    val artist = cursor.getString(artistColumn) ?: "Unknown Artist"
                    val albumArtist = if (albumArtistColumn != -1) {
                        cursor.getString(albumArtistColumn)
                    } else null
                    val trackNumber = cursor.getInt(trackColumn)
                    val genre = if (genreColumn != -1) {
                        cursor.getString(genreColumn)
                    } else null

                    audioFiles.add(
                        mapOf(
                            "path" to path,
                            "title" to (cursor.getString(titleColumn)
                                ?: File(path).nameWithoutExtension),
                            "artist" to artist,
                            "album" to (cursor.getString(albumColumn) ?: "Unknown Album"),
                            "albumArtist" to (albumArtist ?: artist),
                            "genre" to (genre ?: "Unknown Genre"),
                            "year" to cursor.getInt(yearColumn).let { if (it == 0) null else it },
                            "trackNumber" to (trackNumber % 1000),
                            "composer" to cursor.getString(composerColumn),
                            "writer" to null,
                            "duration" to cursor.getLong(durationColumn),
                            "bitrate" to null,
                            "mimeType" to cursor.getString(mimeTypeColumn),
                            "fileExtension" to File(path).extension,
                            "mediaStoreAlbumId" to cursor.getLong(albumIdColumn)
                        )
                    )
                }
                val iterationEnd = System.currentTimeMillis()
                println("MediaStore iteration took: ${iterationEnd - iterationStart}ms")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        val endTime = System.currentTimeMillis()
        println("Total MediaStore operation took: ${endTime - startTime}ms")
        return audioFiles
    }

    private fun getAudioFilesWithMetadataFromPaths(paths: List<String>): List<Map<String, Any?>> {
        val startTime = System.currentTimeMillis()
        val audioFiles = mutableListOf<Map<String, Any?>>()

        val projection = arrayOf(
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ARTIST,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.COMPOSER,
            MediaStore.Audio.Media.MIME_TYPE,
            MediaStore.Audio.Media.ALBUM_ID
        )

        val selectionParts = mutableListOf<String>()
        val selectionArgs = mutableListOf<String>()

        paths.forEach { path ->
            selectionParts.add("${MediaStore.Audio.Media.DATA} LIKE ?")
            selectionArgs.add("$path/%")
        }

        val selection =
            "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND (${selectionParts.joinToString(" OR ")})"

        try {
            val queryStart = System.currentTimeMillis()
            context.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                selectionArgs.toTypedArray(),
                null
            )?.use { cursor ->
                val queryEnd = System.currentTimeMillis()
                println("MediaStore path query took: ${queryEnd - queryStart}ms")

                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                val titleColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
                val artistColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
                val albumColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
                val albumArtistColumn = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM_ARTIST)
                val durationColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
                val trackColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
                val yearColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)
                val genreColumn = cursor.getColumnIndex(MediaStore.Audio.Media.GENRE)
                val composerColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.COMPOSER)
                val mimeTypeColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)
                val albumIdColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM_ID)

                while (cursor.moveToNext()) {
                    val path = cursor.getString(dataColumn)
                    val artist = cursor.getString(artistColumn) ?: "Unknown Artist"
                    val albumArtist = if (albumArtistColumn != -1) {
                        cursor.getString(albumArtistColumn)
                    } else null
                    val trackNumber = cursor.getInt(trackColumn)
                    val genre = if (genreColumn != -1) {
                        cursor.getString(genreColumn)
                    } else null

                    audioFiles.add(
                        mapOf(
                            "path" to path,
                            "title" to (cursor.getString(titleColumn)
                                ?: File(path).nameWithoutExtension),
                            "artist" to artist,
                            "album" to (cursor.getString(albumColumn) ?: "Unknown Album"),
                            "albumArtist" to (albumArtist ?: artist),
                            "genre" to (genre ?: "Unknown Genre"),
                            "year" to cursor.getInt(yearColumn).let { if (it == 0) null else it },
                            "trackNumber" to (trackNumber % 1000),
                            "composer" to cursor.getString(composerColumn),
                            "writer" to null,
                            "duration" to cursor.getLong(durationColumn),
                            "bitrate" to null,
                            "mimeType" to cursor.getString(mimeTypeColumn),
                            "fileExtension" to File(path).extension,
                            "mediaStoreAlbumId" to cursor.getLong(albumIdColumn)
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        val endTime = System.currentTimeMillis()
        println("Total MediaStore path operation took: ${endTime - startTime}ms, found ${audioFiles.size} files")
        return audioFiles
    }

    private fun scanDirectoryWithMetadata(
        path: String,
        recursive: Boolean
    ): List<Map<String, Any?>> {
        val audioFiles = mutableListOf<Map<String, Any?>>()
        val directory = File(path)

        if (!directory.exists() || !directory.isDirectory) {
            return audioFiles
        }

        try {
            val files = if (recursive) {
                directory.walkTopDown()
                    .onEnter { dir ->
                        !dir.name.startsWith(".") &&
                                dir.name != "Android" &&
                                dir.canRead()
                    }
                    .filter { it.isFile && it.canRead() }
            } else {
                directory.listFiles()?.asSequence()?.filter { it.isFile && it.canRead() }
                    ?: emptySequence()
            }

            files.forEach { file ->
                if (isAudioFile(file)) {
                    try {
                        val metadata = getMetadataFromFile(file.absolutePath)
                        audioFiles.add(metadata)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return audioFiles
    }

    private fun scanDirectory(path: String, recursive: Boolean): List<Map<String, Any?>> {
        val audioFiles = mutableListOf<Map<String, Any?>>()
        val directory = File(path)

        if (!directory.exists() || !directory.isDirectory) {
            return audioFiles
        }

        try {
            val files = if (recursive) {
                directory.walkTopDown()
                    .onEnter { dir ->
                        !dir.name.startsWith(".") &&
                                dir.name != "Android" &&
                                dir.canRead()
                    }
                    .filter { it.isFile && it.canRead() }
            } else {
                directory.listFiles()?.asSequence()?.filter { it.isFile && it.canRead() }
                    ?: emptySequence()
            }

            files.forEach { file ->
                if (isAudioFile(file)) {
                    audioFiles.add(
                        mapOf(
                            "path" to file.absolutePath,
                            "size" to file.length(),
                            "lastModified" to file.lastModified()
                        )
                    )
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return audioFiles
    }

    private fun isAudioFile(file: File): Boolean {
        val extension = file.extension.lowercase()
        return AUDIO_EXTENSIONS.contains(extension) && !VIDEO_EXTENSIONS.contains(extension)
    }

    private fun getAllAudioFilesFromMediaStore(): List<Map<String, Any?>> {
        val audioFiles = mutableListOf<Map<String, Any?>>()

        val projection = arrayOf(
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_MODIFIED
        )

        //TODO: ADD ARGUMENT FOR SELECTION FILTER FROM DART
        //val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"

        try {
            context.contentResolver.query(
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                projection,
                null,
                null,
                null
            )?.use { cursor ->
                val dataColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
                val sizeColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
                val dateColumn = cursor.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)

                while (cursor.moveToNext()) {
                    val path = cursor.getString(dataColumn)
                    val file = File(path)

                    if (file.exists() && isAudioFile(file)) {
                        audioFiles.add(
                            mapOf(
                                "path" to path,
                                "size" to cursor.getLong(sizeColumn),
                                "lastModified" to cursor.getLong(dateColumn) * 1000
                            )
                        )
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return audioFiles
    }

    private fun getMetadataFromFile(path: String): Map<String, Any?> {
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
                "fileExtension" to File(path).extension,
                "mediaStoreAlbumId" to null
            )
        } finally {
            retriever.release()
        }
    }

    private fun extractArtwork(path: String, quality: Int): ByteArray? {
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

    private fun getMediaStoreArtwork(albumId: Long, quality: Int): ByteArray? {
        try {
            val uri = "content://media/external/audio/albumart".toUri()
            val albumArtUri = Uri.withAppendedPath(uri, albumId.toString())

            context.contentResolver.openInputStream(albumArtUri)?.use { inputStream ->
                val rawArt = inputStream.readBytes()

                if (quality < 100) {
                    val bitmap = BitmapFactory.decodeByteArray(rawArt, 0, rawArt.size)
                    val outputStream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
                    return outputStream.toByteArray()
                }

                return rawArt
            }
        } catch (e: Exception) {
            return null
        }

        return null
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
                "fileExtension" to getFileExtensionFromMimeType(mimeType),
                "mediaStoreAlbumId" to null
            )
        } finally {
            retriever.release()
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