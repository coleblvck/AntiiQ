import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:antiiq/chaos/widgets/chaos/chaos_header.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';

class ChaosDashboardItemData {
  final String id;
  final String title;
  final IconData icon;

  ChaosDashboardItemData({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class ChaosDashboardGrid extends StatefulWidget {
  final List<ChaosDashboardItemData> items;
  final Function(String id) onItemTap;
  final ChaosHeader header;
  final double bottomSpacing;
  final bool isEditMode;
  final VoidCallback onEditModeChanged;
  final void Function()? onDashboardTap;

  const ChaosDashboardGrid({
    Key? key,
    required this.items,
    required this.onItemTap,
    required this.header,
    required this.bottomSpacing,
    required this.isEditMode,
    required this.onEditModeChanged,
    this.onDashboardTap,
  }) : super(key: key);

  @override
  State<ChaosDashboardGrid> createState() => _ChaosDashboardGridState();
}

class _ChaosDashboardGridState extends State<ChaosDashboardGrid> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridViewKey = GlobalKey();
  String? _pressedItemId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ({List<ChaosDashboardItemData> visible, List<ChaosDashboardItemData> hidden})
      _getOrderedItems(List<String> dashboardOrder) {
    final visibleItems = <ChaosDashboardItemData>[];
    final hiddenItems = <ChaosDashboardItemData>[];
    final itemsMap = {for (var item in widget.items) item.id: item};

    for (var id in dashboardOrder) {
      if (itemsMap.containsKey(id)) {
        visibleItems.add(itemsMap[id]!);
      }
    }

    for (var item in widget.items) {
      if (!dashboardOrder.contains(item.id)) {
        hiddenItems.add(item);
      }
    }

    return (visible: visibleItems, hidden: hiddenItems);
  }

  void _handleReorder(List<Widget> Function(List<Widget>) reorderFunction) {
    final chaosUIState = context.read<ChaosUIState>();
    final currentOrder = chaosUIState.dashboardOrder;

    final currentWidgets = currentOrder.map((id) {
      return GestureDetector(
        key: ValueKey(id),
        child: Container(),
      );
    }).toList();

    final reorderedWidgets = reorderFunction(currentWidgets);

    final newOrder = reorderedWidgets.map<String>((widget) {
      return (widget.key as ValueKey).value as String;
    }).toList();

    chaosUIState.setDashboardOrder(newOrder);
    HapticFeedback.mediumImpact();
  }

  void _toggleItemVisibility(String id) {
    final chaosUIState = context.read<ChaosUIState>();
    final currentOrder = List<String>.from(chaosUIState.dashboardOrder);

    if (currentOrder.contains(id)) {
      currentOrder.remove(id);
    } else {
      currentOrder.add(id);
    }

    chaosUIState.setDashboardOrder(currentOrder);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final chaosUIState = context.watch<ChaosUIState>();
    final currentRadius = chaosUIState.chaosRadius;
    final headerTop =
        ChaosHeader.topPadding + MediaQuery.of(context).padding.top;
    final totalHeaderHeight = headerTop + ChaosHeader.height + chaosBasePadding;

    return GestureDetector(
      onTap: widget.onDashboardTap,
      child: Stack(
        children: [
          Consumer<ChaosUIState>(
            builder: (context, chaosUIState, _) {
              final items = _getOrderedItems(chaosUIState.dashboardOrder);

              if (items.visible.isEmpty && !widget.isEditMode) {
                return CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "NO DASHBOARD ITEMS CONFIGURED",
                              style: TextStyle(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Positioned.fill(
                top: totalHeaderHeight,
                bottom: widget.bottomSpacing,
                left: chaosBasePadding,
                right: chaosBasePadding,
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: Container(
                    constraints: const BoxConstraints.expand(),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(currentRadius),
                      border: Border(
                        top: BorderSide(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.5),
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(chaosBasePadding),
                          sliver: SliverToBoxAdapter(
                            child: ReorderableBuilder(
                              key: Key(_gridViewKey.toString()),
                              onReorder: _handleReorder,
                              children: items.visible.map((item) {
                                if (widget.isEditMode) {
                                  return ReorderableDragStartListener(
                                    key: ValueKey(item.id),
                                    index: items.visible.indexOf(item),
                                    child: GestureDetector(
                                      onTap: () =>
                                          _toggleItemVisibility(item.id),
                                      behavior: HitTestBehavior.opaque,
                                      child: _ChaosDashboardCard(
                                        item: item,
                                        isVisible: true,
                                        isEditMode: widget.isEditMode,
                                        chaosUIState: chaosUIState,
                                        isPressed: _pressedItemId == item.id,
                                        onPressedChanged: (pressed) {
                                          setState(() {
                                            _pressedItemId =
                                                pressed ? item.id : null;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  return GestureDetector(
                                    key: ValueKey(item.id),
                                    onTapDown: (_) {
                                      setState(() => _pressedItemId = item.id);
                                    },
                                    onTapUp: (_) {
                                      setState(() => _pressedItemId = null);
                                      HapticFeedback.mediumImpact();
                                      widget.onItemTap(item.id);
                                    },
                                    onTapCancel: () {
                                      setState(() => _pressedItemId = null);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: _ChaosDashboardCard(
                                      item: item,
                                      isVisible: true,
                                      isEditMode: widget.isEditMode,
                                      chaosUIState: chaosUIState,
                                      isPressed: _pressedItemId == item.id,
                                      onPressedChanged: (_) {},
                                    ),
                                  );
                                }
                              }).toList(),
                              builder: (List<Widget> children) {
                                return GridView.builder(
                                  key: _gridViewKey,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 3.5,
                                    crossAxisSpacing: chaosBasePadding,
                                    mainAxisSpacing: chaosBasePadding,
                                  ),
                                  itemCount: children.length,
                                  itemBuilder: (context, index) =>
                                      children[index],
                                );
                              },
                            ),
                          ),
                        ),
                        if (widget.isEditMode)
                          _buildEditModeSection(items.hidden, chaosUIState),
                        SliverToBoxAdapter(
                          child: SizedBox(height: widget.bottomSpacing),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: headerTop,
            left: ChaosHeader.leftPadding,
            right: ChaosHeader.rightPadding,
            child: widget.header,
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeSection(
      List<ChaosDashboardItemData> hiddenItems, ChaosUIState chaosUIState) {
    // Calculate how many rows we need
    final rows = (hiddenItems.length / 2).ceil();
    // Calculate grid height based on aspect ratio 3.5
    // Each row needs: (screenWidth / 2 - padding) / 3.5 + spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - chaosBasePadding * 3) / 2; // 2 columns
    final itemHeight = itemWidth / 3.5;
    final totalHeight = hiddenItems.isEmpty
        ? 80.0
        : (rows * itemHeight) + ((rows - 1) * chaosBasePadding);

    return SliverToBoxAdapter(
      child: Column(
        children: [
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(
              horizontal: chaosBasePadding,
              vertical: chaosBasePadding / 2,
            ),
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: chaosBasePadding),
            child: Text(
              "TAP ITEMS BELOW TO MAKE VISIBLE",
              style: TextStyle(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          Container(
            height: totalHeight,
            padding: const EdgeInsets.symmetric(horizontal: chaosBasePadding),
            child: hiddenItems.isEmpty
                ? Center(
                    child: Text(
                      "NO HIDDEN ITEMS",
                      style: TextStyle(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                  )
                : GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 3.5,
                      crossAxisSpacing: chaosBasePadding,
                      mainAxisSpacing: chaosBasePadding,
                    ),
                    itemCount: hiddenItems.length,
                    itemBuilder: (context, index) {
                      final item = hiddenItems[index];
                      return GestureDetector(
                        onTap: () => _toggleItemVisibility(item.id),
                        behavior: HitTestBehavior.opaque,
                        child: _ChaosDashboardCard(
                          item: item,
                          isVisible: false,
                          isEditMode: widget.isEditMode,
                          chaosUIState: chaosUIState,
                          isPressed: false,
                          onPressedChanged: (_) {},
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: chaosBasePadding),
        ],
      ),
    );
  }
}

class _ChaosDashboardCard extends StatelessWidget {
  final ChaosDashboardItemData item;
  final bool isVisible;
  final bool isEditMode;
  final ChaosUIState chaosUIState;
  final bool isPressed;
  final Function(bool) onPressedChanged;

  const _ChaosDashboardCard({
    required this.item,
    required this.isVisible,
    required this.isEditMode,
    required this.chaosUIState,
    required this.isPressed,
    required this.onPressedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final itemIndex = item.id.hashCode % 2000;
    final radius = chaosUIState.getAdjustedRadius(4);

    return ChaosRotatedStatefulWidget(
      index: itemIndex,
      style: ChaosRotationStyle.fibonacci,
      maxAngle: getAnglePercentage(0.15, chaosUIState.chaosLevel),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(isPressed ? 0.97 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: isVisible
                  ? AntiiQTheme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: isPressed ? 0.9 : 0.85)
                  : AntiiQTheme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.2),
              border: Border.all(
                color: isVisible
                    ? AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: isPressed ? 0.7 : 0.3)
                    : AntiiQTheme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.15),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: chaosBasePadding,
                    vertical: chaosBasePadding * 0.8,
                  ),
                  child: Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon container
                        ChaosRotatedStatefulWidget(
                          angle: getAnglePercentage(
                              -0.02, chaosUIState.chaosLevel),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isVisible
                                  ? AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1)
                                  : AntiiQTheme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.05),
                              border: Border.all(
                                color: isVisible
                                    ? AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3)
                                    : AntiiQTheme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.15),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(radius * 0.6),
                            ),
                            child: Icon(
                              item.icon,
                              color: isVisible
                                  ? AntiiQTheme.of(context).colorScheme.primary
                                  : AntiiQTheme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: chaosBasePadding * 0.75),
                        // Text content
                        Expanded(
                          child: ChaosRotatedStatefulWidget(
                            angle: getAnglePercentage(
                                0.015, chaosUIState.chaosLevel),
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isVisible
                                    ? AntiiQTheme.of(context)
                                        .colorScheme
                                        .onSurface
                                    : AntiiQTheme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.35),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Drag indicator
                if (isEditMode && isVisible)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: ChaosRotatedStatefulWidget(
                      angle: getAnglePercentage(0.025, chaosUIState.chaosLevel),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(radius * 0.4),
                          border: Border.all(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          RemixIcon.draggable,
                          size: 10,
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
