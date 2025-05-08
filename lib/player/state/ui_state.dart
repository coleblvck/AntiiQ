import 'package:antiiq/player/screens/dashboard/generate_dashboard_items.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/settings/user_settings.dart';

class UIState extends InheritedWidget {
  const UIState({
    super.key,
    required super.child,
    required this.dashboardTheme,
  });

  final DashboardTheme dashboardTheme;

  static UIState? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UIState>();
  }

  static UIState of(BuildContext context) {
    final UIState? result = maybeOf(context);
    assert(result != null, 'No UIState found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(UIState oldWidget) {
    return oldWidget.dashboardTheme != dashboardTheme;
  }
}

class DashboardTheme {
  static Future<DashboardTheme> create() async {
    final instance = DashboardTheme();
    await instance.init();
    return instance;
  }

  List<String> get viewOrder => _viewOrder;
  List<String> _viewOrder = [];
  StreamController<List<String>> get viewOrderFlow => _viewOrderFlow;
  final StreamController<List<String>> _viewOrderFlow =
      StreamController.broadcast();

  Future<void> updateViewOrder(List<String> order) async {
    await _updateViewOrderInternal(order);
  }

  _updateViewOrderInternal(List<String> order, {bool save = true}) async {
    _viewOrder = order;
    if (!_viewOrderFlow.isClosed) {
      _viewOrderFlow.add(order);
    }
    if (save) {
      await _save();
    }
  }

  _save() async {
    try {
      await antiiqState.store.put(MainBoxKeys.dashboardViewOrder, _viewOrder);
    } catch (e) {
      null;
    }
  }

  Future<void> init() async {
    await _load();
    if (!_viewOrderFlow.isClosed && _viewOrder.isNotEmpty) {
      _viewOrderFlow.add(_viewOrder);
    }
  }

  _load() async {
    try {
      final loadedOrder = await antiiqState.store.get(
          MainBoxKeys.dashboardViewOrder,
          defaultValue: generateDashboardItemData().map((item) => item.key).toList());
      if (loadedOrder is List) {
        final stringList = loadedOrder.map((item) => item.toString()).toList();
        _updateViewOrderInternal(stringList, save: false);
      } else {
        _updateViewOrderInternal([], save: false);
      }
    } catch (e) {
      _updateViewOrderInternal([], save: false);
    }
  }

  void dispose() {
    if (!_viewOrderFlow.isClosed) {
      _viewOrderFlow.close();
    }
  }
}

class UIStateInitializer extends StatefulWidget {
  final Widget child;

  const UIStateInitializer({super.key, required this.child});

  @override
  State<UIStateInitializer> createState() => _UIStateInitializerState();
}

class _UIStateInitializerState extends State<UIStateInitializer> {
  DashboardTheme? _dashboardTheme;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initializeDashboardTheme();
  }

  Future<void> _initializeDashboardTheme() async {
    try {
      final theme = await DashboardTheme.create();
      setState(() {
        _dashboardTheme = theme;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dashboardTheme?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CustomInfiniteProgressIndicator(),
      );
    } else if (_error != null) {
      return ErrorWidget(_error!);
    } else {
      return UIState(
        dashboardTheme: _dashboardTheme!,
        child: widget.child,
      );
    }
  }
}
