import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/dashboard_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardLayoutMetrics', () {
    test('uses live system insets without changing internal spacing', () {
      const layout = DashboardLayoutMetrics(
        systemPadding: EdgeInsets.fromLTRB(0, 24, 0, 28),
        navigationHeight: 100,
        miniPlayerHeight: 72,
      );

      expect(layout.headerTop, 48);
      expect(layout.navigationBottom, 28);
      expect(layout.miniPlayerBottom, 136);
      expect(layout.dashboardContentBottom, 216);
      expect(
        layout.miniPlayerBottom -
            layout.navigationBottom -
            layout.navigationHeight,
        chaosBasePadding,
      );
    });

    test('immersive mode removes only the system-bar clearance', () {
      const layout = DashboardLayoutMetrics(
        systemPadding: EdgeInsets.zero,
        navigationHeight: 100,
        miniPlayerHeight: 72,
      );

      expect(layout.headerTop, 24);
      expect(layout.navigationBottom, 0);
      expect(layout.miniPlayerBottom, 108);
      expect(layout.dashboardContentBottom, 188);
      expect(
        layout.miniPlayerBottom -
            layout.navigationBottom -
            layout.navigationHeight,
        chaosBasePadding,
      );
    });
  });
}
