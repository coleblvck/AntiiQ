import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/widgets/chaos/chaos_animation_manager.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class NavigationItem {
  final String id;
  final String label;
  final bool enabled;
  final Map<String, dynamic>? metadata;

  const NavigationItem({
    required this.id,
    required this.label,
    this.enabled = true,
    this.metadata,
  });
}

enum NavigationState {
  collapsed,
  expanding,
  expanded,
  collapsing,
}

class BottomNavigationController extends ChangeNotifier {
  _CollapsibleBottomNavigationState? _state;
  Timer? _autoCollapseTimer;

  void _attach(_CollapsibleBottomNavigationState state) => _state = state;
  void _detach() {
    _autoCollapseTimer?.cancel();
    _state = null;
  }

  /// Exposing internal methods and stuff
  void expand() => _state?._expand();

  void collapse() => _state?._collapse();

  void toggle() => _state?._toggle();

  double get currentHeight => _state?._currentHeight ?? 0.0;

  double get maxHeight => _state?.widget.maxHeight ?? 100.0;

  double get handleHeight => _state?.widget.handleHeight ?? 20.0;

  NavigationState get currentState =>
      _state?._currentState ?? NavigationState.collapsed;

  bool get isExpanded => currentState == NavigationState.expanded;

  bool get isCollapsed => currentState == NavigationState.collapsed;

  void resetAutoCollapse() => _state?._resetAutoCollapseTimer();

  void cancelAutoCollapse() => _state?._cancelAutoCollapseTimer();

  int get selectedIndex => _state?._selectedIndex ?? -1;

  NavigationItem? get selectedItem {
    final index = selectedIndex;
    if (index < 0 || index >= (_state?.widget.navigationItems.length ?? 0)) {
      return null;
    }
    return _state?.widget.navigationItems[index];
  }

  void selectItem(int index) {
    _state?._selectItem(index);
  }

  void selectItemById(String id) {
    _state?._selectItemById(id);
  }

  void clearSelection() {
    _state?._clearSelection();
  }
}

class CollapsibleBottomNavigation extends StatefulWidget {
  final Duration animationDuration;
  final Duration? autoCollapseDuration;
  final double maxHeight;
  final double handleHeight;
  final Function(NavigationState state, double height)? onStateChanged;
  final Function(BottomNavigationController controller)? onControllerReady;
  final ChaosAnimationManager? chaosAnimationManager;

  final List<NavigationItem> navigationItems;
  final int selectedIndex;
  final Function(int index)? onItemTapped;
  final Function(int index)? onItemSelected;
  final bool allowDeselection;
  final int activeIndex;

  const CollapsibleBottomNavigation({
    Key? key,
    this.animationDuration = const Duration(milliseconds: 400),
    this.autoCollapseDuration,
    this.maxHeight = 100.0,
    this.handleHeight = 20.0,
    this.onStateChanged,
    this.onControllerReady,
    this.chaosAnimationManager,
    this.navigationItems = const [
      NavigationItem(
        id: 'dashboard',
        label: 'DASHBOARD',
      ),
      NavigationItem(
        id: 'equalizer',
        label: 'EQUALIZER',
      ),
      NavigationItem(
        id: 'search',
        label: 'SEARCH',
      ),
    ],
    this.selectedIndex = 0,
    this.onItemTapped,
    this.onItemSelected,
    this.allowDeselection = false,
    this.activeIndex = 0,
  }) : super(key: key);

  @override
  State<CollapsibleBottomNavigation> createState() =>
      _CollapsibleBottomNavigationState();
}

class _CollapsibleBottomNavigationState
    extends State<CollapsibleBottomNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late BottomNavigationController _controller;
  NavigationState _currentState = NavigationState.expanded; // Start expanded
  Timer? _autoCollapseTimer;

  bool get _isExpanded => _currentState == NavigationState.expanded;
  double get _currentHeight =>
      widget.handleHeight +
      (_expandController.value * (widget.maxHeight - widget.handleHeight));
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _selectedIndex = widget.selectedIndex;

    _controller = BottomNavigationController();
    _controller._attach(this);

    _expandController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: 1.0, // Start expanded
    );

    _expandController.addStatusListener((status) {
      final newState = switch (status) {
        AnimationStatus.forward => NavigationState.expanding,
        AnimationStatus.completed => NavigationState.expanded,
        AnimationStatus.reverse => NavigationState.collapsing,
        AnimationStatus.dismissed => NavigationState.collapsed,
      };

      if (newState != _currentState) {
        setState(() => _currentState = newState);
        widget.onStateChanged?.call(newState, _currentHeight);

        // Start auto-collapse timer when expanded
        if (newState == NavigationState.expanded) {
          _startAutoCollapseTimer();
        }
      }
    });

    _expandController.addListener(() {
      widget.onStateChanged?.call(_currentState, _currentHeight);
    });

    // Start initial auto-collapse timer
    _startAutoCollapseTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(_controller);
    });
  }

  @override
  void didUpdateWidget(CollapsibleBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      setState(() => _selectedIndex = widget.selectedIndex);
    }
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _controller._detach();
    _expandController.dispose();
    super.dispose();
  }

  void _selectItem(int index) {
    if (index >= 0 && index < widget.navigationItems.length) {
      _onNavItemTap(index);
    }
  }

  void _selectItemById(String id) {
    final index = widget.navigationItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _selectItem(index);
    }
  }

  void _clearSelection() {
    if (widget.allowDeselection) {
      setState(() => _selectedIndex = -1);
      widget.onItemSelected?.call(-1);
    }
  }

  void _startAutoCollapseTimer() {
    if (widget.autoCollapseDuration == null || !_isExpanded) return;

    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(widget.autoCollapseDuration!, () {
      if (mounted && _isExpanded) {
        _collapse();
      }
    });
  }

  void _resetAutoCollapseTimer() {
    if (widget.autoCollapseDuration == null) return;
    _startAutoCollapseTimer();
  }

  void _cancelAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
  }

  // Internal control methods
  void _expand() => _expandController.forward();
  void _collapse() => _expandController.reverse();
  void _toggle() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _onNavItemTap(int index) {
    _resetAutoCollapseTimer();
    widget.chaosAnimationManager?.triggerGlitch();
    HapticFeedback.selectionClick();

    final item = widget.navigationItems[index];
    if (!item.enabled) return;

    if (widget.allowDeselection && _selectedIndex == index) {
      setState(() => _selectedIndex = -1);
      widget.onItemSelected?.call(-1);
      return;
    }

    setState(() => _selectedIndex = index);
    widget.onItemTapped?.call(index);
    widget.onItemSelected?.call(index);
  }

  void _onHandleTap() {
    _toggle();
    HapticFeedback.mediumImpact();
    widget.chaosAnimationManager?.triggerGlitch();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _expandController,
        builder: (context, child) {
          return GestureDetector(
            onPanUpdate: (details) {
              _resetAutoCollapseTimer();
            },
            onTap: _resetAutoCollapseTimer,
            child: Container(
              height: _currentHeight,
              decoration: BoxDecoration(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .background
                    .withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: AntiiQTheme.of(context)
                        .colorScheme
                        .onBackground
                        .withValues(
                            alpha: 0.1 + (_expandController.value * 0.1)),
                    width: 1 + _expandController.value,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  if (_expandController.value > 0.1)
                    Positioned(
                      top: _isExpanded ? 0 : widget.handleHeight,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Opacity(
                        opacity: (_expandController.value).clamp(0.0, 1.0),
                        child: _buildNavigationContent(),
                      ),
                    ),

                  // Handle - always on top
                  if (!_isExpanded ||
                      _currentState == NavigationState.collapsing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: widget.handleHeight,
                      child: _buildHandle(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle() {
    return GestureDetector(
      onTap: _onHandleTap,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: widget.chaosAnimationManager?.glitchController ??
              const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            final glitchOffset =
                widget.chaosAnimationManager?.getSubtleGlitchOffset() ??
                    Offset.zero;

            return Transform.translate(
              offset: glitchOffset,
              child: Container(
                height: widget.handleHeight,
                width: double.infinity,
                color: Colors.transparent,
                child: Stack(
                  children: [
                    // Corner brackets
                    Positioned(
                      left: chaosBasePadding,
                      top: 4,
                      child: Container(
                        width: 12,
                        height: 8,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                              width: 2,
                            ),
                            top: BorderSide(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: chaosBasePadding,
                      top: 4,
                      child: Container(
                        width: 12,
                        height: 8,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                              width: 2,
                            ),
                            top: BorderSide(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.6),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Center line
                    Positioned(
                      top: 8,
                      left: MediaQuery.of(context).size.width * 0.35,
                      right: MediaQuery.of(context).size.width * 0.35,
                      child: Transform.rotate(
                        angle: -0.008,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavigationContent() {
    return Padding(
      padding: const EdgeInsets.all(chaosBasePadding * 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: widget.navigationItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = index == _selectedIndex;

          return _buildNavText(item.label, isActive, index);
        }).toList(),
      ),
    );
  }

  Widget _buildNavText(String text, bool isActive, int index) {
    return GestureDetector(
      onTap: () => _onNavItemTap(index),
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: widget.chaosAnimationManager?.glitchController ??
              const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            // Only applying glitch to active items
            final glitchOffset = isActive
                ? (widget.chaosAnimationManager?.getGlitchOffset(2.0, 1.0) ??
                    Offset.zero)
                : Offset.zero;

            return Transform.translate(
              offset: glitchOffset,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isActive
                          ? AntiiQTheme.of(context).colorScheme.primary
                          : AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withValues(alpha: 0.6),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w300,
                      letterSpacing: 2,
                      shadows: isActive
                          ? [
                              Shadow(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 0),
                              )
                            ]
                          : null,
                    ),
                  ),
                  if (isActive)
                    Positioned(
                      left: -8,
                      right: -8,
                      top: 7,
                      child: Container(
                        height: 1,
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
