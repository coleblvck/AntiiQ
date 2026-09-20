import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:flutter/widgets.dart';

@immutable
class DashboardLayoutMetrics {
  const DashboardLayoutMetrics({
    required this.systemPadding,
    required this.navigationHeight,
    required this.miniPlayerHeight,
  });

  final EdgeInsets systemPadding;
  final double navigationHeight;
  final double miniPlayerHeight;

  double get headerTop => systemPadding.top + chaosDashboardHeaderTopPadding;
  double get navigationBottom => systemPadding.bottom;

  double get miniPlayerBottom =>
      navigationBottom + navigationHeight + chaosBasePadding;

  double get dashboardContentBottom =>
      miniPlayerBottom + miniPlayerHeight + chaosBasePadding;
}
