package com.coleblvck.antiiq

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

class BackupStorageBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var pendingPickerResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> pickDirectory(result)
            "exportBackup" -> runFileOperation(call, result, ::exportBackup)
            "importBackup" -> runFileOperation(call, result, ::importBackup)
            else -> result.notImplemented()
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_DIRECTORY_REQUEST) return false

        val result = pendingPickerResult ?: return true
        pendingPickerResult = null
        if (resultCode != Activity.RESULT_OK) {
            result.success(null)
            return true
        }

        val treeUri = data?.data
        if (treeUri == null) {
            result.error("DIRECTORY_PICK_FAILED", "No directory was returned.", null)
            return true
        }

        val requestedFlags = (data?.flags ?: 0) and
            (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        try {
            activity.contentResolver.takePersistableUriPermission(treeUri, requestedFlags)
            result.success(
                mapOf(
                    "uri" to treeUri.toString(),
                    "name" to directoryName(treeUri),
                ),
            )
        } catch (error: Exception) {
            result.error("DIRECTORY_PERMISSION_FAILED", error.message, null)
        }
        return true
    }

    fun dispose() {
        pendingPickerResult?.error(
            "ACTIVITY_DETACHED",
            "The directory picker was interrupted.",
            null,
        )
        pendingPickerResult = null
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    private fun pickDirectory(result: MethodChannel.Result) {
        if (pendingPickerResult != null) {
            result.error("PICKER_ACTIVE", "A directory picker is already open.", null)
            return
        }

        pendingPickerResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        activity.startActivityForResult(intent, PICK_DIRECTORY_REQUEST)
    }

    private fun runFileOperation(
        call: MethodCall,
        result: MethodChannel.Result,
        operation: (Uri, Map<String, String>) -> Unit,
    ) {
        val directory = call.argument<String>("directoryUri")
        val files = call.argument<Map<String, String>>("files")
        if (directory == null || files == null || files.isEmpty()) {
            result.error("INVALID_ARGUMENT", "Directory and files are required.", null)
            return
        }

        scope.launch {
            try {
                operation(Uri.parse(directory), files)
                withContext(Dispatchers.Main) { result.success(null) }
            } catch (error: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("BACKUP_STORAGE_FAILED", error.message, null)
                }
            }
        }
    }

    private fun exportBackup(treeUri: Uri, files: Map<String, String>) {
        for ((name, sourcePath) in files) {
            val destination = findChild(treeUri, name)
                ?: DocumentsContract.createDocument(
                    activity.contentResolver,
                    rootDocumentUri(treeUri),
                    "application/octet-stream",
                    name,
                )
                ?: error("Could not create $name in the selected directory.")

            File(sourcePath).inputStream().use { input ->
                activity.contentResolver.openOutputStream(destination, "wt")?.use { output ->
                    input.copyTo(output)
                } ?: error("Could not open $name for writing.")
            }
        }
    }

    private fun importBackup(treeUri: Uri, files: Map<String, String>) {
        val missing = files.keys.filter { findChild(treeUri, it) == null }
        if (missing.isNotEmpty()) {
            error("The selected directory is missing: ${missing.joinToString()}.")
        }

        for ((name, destinationPath) in files) {
            val source = findChild(treeUri, name)
                ?: error("The selected directory is missing $name.")
            activity.contentResolver.openInputStream(source)?.use { input ->
                File(destinationPath).outputStream().use { output ->
                    input.copyTo(output)
                }
            } ?: error("Could not open $name for reading.")
        }
    }

    private fun rootDocumentUri(treeUri: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )

    private fun findChild(treeUri: Uri, displayName: String): Uri? {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        )
        activity.contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            val idColumn = cursor.getColumnIndexOrThrow(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            )
            val nameColumn = cursor.getColumnIndexOrThrow(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            )
            while (cursor.moveToNext()) {
                if (cursor.getString(nameColumn) == displayName) {
                    return DocumentsContract.buildDocumentUriUsingTree(
                        treeUri,
                        cursor.getString(idColumn),
                    )
                }
            }
        }
        return null
    }

    private fun directoryName(treeUri: Uri): String {
        val documentUri = rootDocumentUri(treeUri)
        activity.contentResolver.query(
            documentUri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getString(0)
            }
        }
        return DocumentsContract.getTreeDocumentId(treeUri).substringAfterLast(':')
    }

    companion object {
        private const val CHANNEL_NAME = "com.coleblvck.antiiq/backup_storage"
        private const val PICK_DIRECTORY_REQUEST = 7401
    }
}
