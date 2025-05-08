import 'package:antiiq/player/screens/dashboard/dashboard_item_data.dart';
import 'package:antiiq/player/screens/dashboard/dashboard_item_manager.dart';
import 'package:antiiq/player/screens/dashboard/generate_dashboard_items.dart';
import 'package:antiiq/player/state/ui_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _scrollController = ScrollController();
  final GlobalKey _gridViewKey = GlobalKey();
  bool _isEditMode = false;
  List<DashboardItemData> _allItems = [];

  @override
  void initState() {
    super.initState();
    _allItems = generateDashboardItemData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveDashboardConfig(List<String> visibleKeys) async {
    try {
      await UIState.of(context).dashboardTheme.updateViewOrder(visibleKeys);
    } catch (e) {
      null;
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardTheme = UIState.of(context).dashboardTheme;

    return StreamBuilder<List<String>>(
      stream: dashboardTheme.viewOrderFlow.stream,
      initialData: dashboardTheme.viewOrder,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final viewOrder = snapshot.data ?? [];

        if (viewOrder.isEmpty && !_isEditMode) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "No dashboard items configured",
                  style: AntiiQTheme.of(context).textStyles.secondaryText,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  function: _toggleEditMode,
                  style: AntiiQTheme.of(context).buttonStyles.style2,
                  child: const Text('Configure Dashboard'),
                ),
              ],
            ),
          );
        }

        final itemManager = _createItemManager(viewOrder);
        final visibleItems = itemManager.visibleItems;
        final hiddenItems =
            itemManager.items.where((item) => !item.isVisible).toList();

        return Column(
          children: [
            Expanded(
              child: ReorderableBuilder(
                dragChildBoxDecoration: BoxDecoration(
                  boxShadow: const [],
                  border: Border.all(
                    color: AntiiQTheme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                ),
                key: Key(_gridViewKey.toString()),
                onReorder: _handleReorder,
                scrollController: _scrollController,
                children: visibleItems.map((item) {
                  return GestureDetector(
                    key: ValueKey(item.key),
                    onTap: _isEditMode
                        ? () => _toggleItemVisibility(item.key, viewOrder)
                        : item.function,
                    child: _buildItemCard(item, true),
                  );
                }).toList(),
                builder: (List<Widget> children) {
                  return GridView.builder(
                    key: _gridViewKey,
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: children.length,
                    itemBuilder: (context, index) {
                      return children[index];
                    },
                  );
                },
              ),
            ),
            if (_isEditMode) _buildEditModeSection(hiddenItems, viewOrder),
            if (!_isEditMode)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  onPressed: _toggleEditMode,
                  style: AntiiQTheme.of(context).buttonStyles.style4.copyWith(
                      backgroundColor:
                          const WidgetStatePropertyAll(Colors.transparent)),
                  icon: Icon(
                    RemixIcon.pencil,
                    color: AntiiQTheme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _handleReorder(List<Widget> Function(List<Widget>) reorderFunction) {
    final dashboardTheme = UIState.of(context).dashboardTheme;

    final currentViewOrder = dashboardTheme.viewOrder;

    final currentWidgets = currentViewOrder.map((key) {
      return GestureDetector(
        key: ValueKey(key),
        child: Container(),
      );
    }).toList();

    final reorderedWidgets = reorderFunction(currentWidgets);

    final newOrderKeys = reorderedWidgets.map<String>((widget) {
      return (widget.key as ValueKey).value as String;
    }).toList();

    _saveDashboardConfig(newOrderKeys);
  }

  DashboardItemManager _createItemManager(List<String> viewOrder) {
    final items = List<DashboardItemData>.from(_allItems);

    for (var item in items) {
      item.isVisible = viewOrder.contains(item.key);
    }

    final manager = DashboardItemManager(initialItems: items);
    manager.reorderItemsBasedOnKeys(viewOrder);
    return manager;
  }

  void _toggleItemVisibility(String key, List<String> currentViewOrder) {
    List<String> updatedViewOrder = List.from(currentViewOrder);

    if (updatedViewOrder.contains(key)) {
      updatedViewOrder.remove(key);
    } else {
      updatedViewOrder.add(key);
    }

    _saveDashboardConfig(updatedViewOrder);
  }

  Widget _buildItemCard(DashboardItemData item, bool isVisible) {
    return CustomCard(
      theme: isVisible
          ? AntiiQTheme.of(context).cardThemes.background
          : AntiiQTheme.of(context)
              .cardThemes
              .secondary
              .copyWith(margin: EdgeInsets.zero),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Icon(
                item.icon,
                color: isVisible
                    ? AntiiQTheme.of(context).colorScheme.primary
                    : AntiiQTheme.of(context).colorScheme.onSecondary,
              ),
            ),
            Expanded(
              child: Text(
                item.title,
                style: isVisible
                    ? AntiiQTheme.of(context).textStyles.primaryText.copyWith(
                          overflow: TextOverflow.ellipsis,
                        )
                    : AntiiQTheme.of(context)
                        .textStyles
                        .onSecondaryText
                        .copyWith(
                          overflow: TextOverflow.ellipsis,
                        ),
              ),
            ),
            if (_isEditMode && isVisible)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.drag_indicator,
                  color: AntiiQTheme.of(context).colorScheme.secondary,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditModeSection(
      List<DashboardItemData> hiddenItems, List<String> viewOrder) {
    return Column(
      children: [
        Divider(
          color: AntiiQTheme.of(context).colorScheme.primary,
          thickness: 2,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Tap items below to make them visible",
            style: AntiiQTheme.of(context).textStyles.secondaryText,
          ),
        ),
        SizedBox(
          height: 120,
          child: hiddenItems.isEmpty
              ? Center(
                  child: Text(
                    "No hidden items",
                    style: AntiiQTheme.of(context).textStyles.secondaryText,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: hiddenItems.length,
                      itemBuilder: (context, index) {
                        final item = hiddenItems[index];
                        return GestureDetector(
                          onTap: () =>
                              _toggleItemVisibility(item.key, viewOrder),
                          child: _buildItemCard(item, false),
                        );
                      },
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
          child: CustomButton(
            function: _toggleEditMode,
            style: AntiiQTheme.of(context).buttonStyles.style2,
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}
