import 'package:antiiq/player/screens/dashboard/dashboard_item_data.dart';

class DashboardItemManager {
  List<DashboardItemData> _items = [];

  DashboardItemManager({required List<DashboardItemData> initialItems}) {
    _items = List.from(initialItems);
  }

  List<DashboardItemData> get items => _items;

  List<DashboardItemData> get visibleItems =>
      _items.where((item) => item.isVisible).toList();

  List<DashboardItemData> get hiddenItems =>
      _items.where((item) => !item.isVisible).toList();

  void reorderItemsBasedOnKeys(List<String> newOrderKeys) {
    final itemMap = {for (var item in _items) item.key: item};

    final reorderedItems = <DashboardItemData>[];

    for (final key in newOrderKeys) {
      if (itemMap.containsKey(key)) {
        reorderedItems.add(itemMap[key]!);
        itemMap.remove(key);
      }
    }

    reorderedItems.addAll(itemMap.values);

    _items = reorderedItems;
  }

  void toggleVisibility(String key) {
    final index = _items.indexWhere((item) => item.key == key);
    if (index != -1) {
      _items[index].isVisible = !_items[index].isVisible;

      final item = _items.removeAt(index);

      if (item.isVisible) {
        final lastVisibleIndex =
            _items.lastIndexWhere((element) => element.isVisible);
        if (lastVisibleIndex >= 0) {
          _items.insert(lastVisibleIndex + 1, item);
        } else {
          _items.insert(0, item);
        }
      } else {
        final firstHiddenIndex =
            _items.indexWhere((element) => !element.isVisible);
        if (firstHiddenIndex >= 0) {
          _items.insert(firstHiddenIndex, item);
        } else {
          _items.add(item);
        }
      }
    }
  }

  List<String> getVisibleItemKeys() {
    return visibleItems.map((item) => item.key).toList();
  }

  void setVisibilityFromKeys(List<String> visibleKeys) {
    for (var item in _items) {
      item.isVisible = visibleKeys.contains(item.key);
    }
  }
}
