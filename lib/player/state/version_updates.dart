import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VersionUpdates extends ChangeNotifier {
  late Box _store;

  static const String _keyLastSeenVersion = 'last_seen_update_version';
  static const String _keyDismissedVersions = 'dismissed_update_versions';

  VersionUpdates.init(Box store) {
    _store = store;
    loadLastSeenUpdateVersion();
  }

  String? _lastSeenUpdateVersion;
  List<String> _dismissedVersions = [];

  String? get lastSeenUpdateVersion => _lastSeenUpdateVersion;

  List<String> get dismissedVersions => List.unmodifiable(_dismissedVersions);

  Future<void> setLastSeenUpdateVersion(String version) async {
    _lastSeenUpdateVersion = version;
    await _store.put(_keyLastSeenVersion, version);

    if (!_dismissedVersions.contains(version)) {
      _dismissedVersions.add(version);
      await _store.put(_keyDismissedVersions, _dismissedVersions);
    }

    notifyListeners();
  }

  Future<void> loadLastSeenUpdateVersion() async {
    _lastSeenUpdateVersion = _store.get(_keyLastSeenVersion);

    // Load dismissed versions list
    final dismissed = _store.get(_keyDismissedVersions);
    if (dismissed != null && dismissed is List) {
      _dismissedVersions = List<String>.from(dismissed);
    }

    notifyListeners();
  }

  bool hasSeenVersion(String version) {
    return _dismissedVersions.contains(version);
  }

  bool shouldShowUpdate(String version) {
    return !hasSeenVersion(version);
  }

  Future<void> markVersionAsSeen(String version) async {
    if (!_dismissedVersions.contains(version)) {
      _dismissedVersions.add(version);
      await _store.put(_keyDismissedVersions, _dismissedVersions);

      if (_lastSeenUpdateVersion == null ||
          _compareVersions(version, _lastSeenUpdateVersion!) > 0) {
        _lastSeenUpdateVersion = version;
        await _store.put(_keyLastSeenVersion, version);
      }

      notifyListeners();
    }
  }

  Future<void> clearVersionHistory() async {
    _lastSeenUpdateVersion = null;
    _dismissedVersions = [];
    await _store.delete(_keyLastSeenVersion);
    await _store.delete(_keyDismissedVersions);
    notifyListeners();
  }

  Future<void> resetToVersion(String version) async {
    _lastSeenUpdateVersion = version;
    _dismissedVersions = _dismissedVersions
        .where((v) => _compareVersions(v, version) <= 0)
        .toList();

    await _store.put(_keyLastSeenVersion, version);
    await _store.put(_keyDismissedVersions, _dismissedVersions);
    notifyListeners();
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLength =
        parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }

    return 0;
  }
}
