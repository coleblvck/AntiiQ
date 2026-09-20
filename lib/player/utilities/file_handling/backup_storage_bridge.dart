import 'package:flutter/services.dart';

class BackupDirectory {
  const BackupDirectory({required this.uri, required this.name});

  final String uri;
  final String name;
}

class BackupStorageBridge {
  static const _channel = MethodChannel('com.coleblvck.antiiq/backup_storage');

  static Future<BackupDirectory?> pickDirectory() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'pickDirectory',
    );
    final uri = result?['uri'] as String?;
    if (uri == null || uri.isEmpty) return null;
    return BackupDirectory(
      uri: uri,
      name: result?['name'] as String? ?? 'Selected folder',
    );
  }

  static Future<void> exportBackup({
    required String directoryUri,
    required Map<String, String> files,
  }) async {
    await _channel.invokeMethod<void>('exportBackup', {
      'directoryUri': directoryUri,
      'files': files,
    });
  }

  static Future<void> importBackup({
    required String directoryUri,
    required Map<String, String> files,
  }) async {
    await _channel.invokeMethod<void>('importBackup', {
      'directoryUri': directoryUri,
      'files': files,
    });
  }
}
