import 'package:antiiq/chaos/antiiq_updates.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dashboard configuration', () {
    test('new collection entries are visible by default', () {
      expect(
        ChaosUIState.defaultDashboardOrder,
        containsAllInOrder(['artists', 'albumArtists', 'folders', 'genres']),
      );
    });

    test('saved order is sanitized without restoring hidden items', () {
      expect(
        ChaosUIState.normalizeDashboardOrder(
          ['albums', 'stale', 'songs', 'albums'],
        ),
        ['albums', 'songs'],
      );
    });

    test('old layouts gain the two new collections exactly once', () {
      expect(
        ChaosUIState.migrateDashboardOrder(
          ['songs', 'artists', 'genres', 'favourites'],
          fromVersion: 1,
        ),
        [
          'songs',
          'artists',
          'albumArtists',
          'folders',
          'genres',
          'favourites',
        ],
      );
    });
  });

  group('update notice targeting', () {
    test('returns the notice only for its exact app version', () {
      expect(antiiqUpdateForVersion('2.0.0')?.version, '2.0.0');
      expect(antiiqUpdateForVersion('2.0.1'), isNull);
      expect(antiiqUpdateForVersion('3.0.0'), isNull);
    });
  });
}
