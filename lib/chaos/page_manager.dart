import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/utilities/alpha.dart';
import 'package:antiiq/chaos/utilities/angle.dart';
import 'package:chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class ChaosPageManagerController extends ChangeNotifier {
  final List<ChaosPageManagerPage> _stack = [];

  bool get isEmpty => _stack.isEmpty;
  bool get isNotEmpty => _stack.isNotEmpty;
  int get depth => _stack.length;
  ChaosPageManagerPage? get currentPage => _stack.isEmpty ? null : _stack.last;

  void openPage(
    Widget page, {
    String? title,
    ScrollController? scrollController,
    VoidCallback? onHeaderTap,
    VoidCallback? onPop,
    // List controls
    dynamic listToCount,
    List<Track>? listToShuffle,
    String? sortList,
    List<String>? availableSortTypes,
    Function? onSortChanged,
  }) {
    _stack.clear();
    _stack.add(ChaosPageManagerPage(
      widget: page,
      title: title,
      key: GlobalKey(),
      scrollController: scrollController,
      onHeaderTap: onHeaderTap,
      onPop: onPop,
      listToCount: listToCount,
      listToShuffle: listToShuffle,
      sortList: sortList,
      availableSortTypes: availableSortTypes,
      onSortChanged: onSortChanged,
    ));
    notifyListeners();
  }

  void push(
    Widget page, {
    String? title,
    ScrollController? scrollController,
    VoidCallback? onHeaderTap,
    VoidCallback? onPop,
    dynamic listToCount,
    List<Track>? listToShuffle,
    String? sortList,
    List<String>? availableSortTypes,
    Function? onSortChanged,
  }) {
    if (_stack.isNotEmpty && _stack.last.title == title && title != null) {
      return;
    }

    _stack.add(ChaosPageManagerPage(
      widget: page,
      title: title,
      key: GlobalKey(),
      scrollController: scrollController,
      onHeaderTap: onHeaderTap,
      onPop: onPop,
      listToCount: listToCount,
      listToShuffle: listToShuffle,
      sortList: sortList,
      availableSortTypes: availableSortTypes,
      onSortChanged: onSortChanged,
    ));
    notifyListeners();
  }

  bool pop() {
    if (_stack.isEmpty) return false;
    final removed = _stack.removeLast();
    removed.onPop?.call();
    notifyListeners();
    return _stack.isNotEmpty;
  }

  void clear() {
    for (final page in _stack) {
      page.onPop?.call();
    }
    _stack.clear();
    notifyListeners();
  }

  void replaceCurrent(Widget page, {String? title}) {
    if (_stack.isNotEmpty) {
      final removed = _stack.removeLast();
      removed.onPop?.call();
    }
    _stack.add(ChaosPageManagerPage(
      widget: page,
      title: title,
      key: GlobalKey(),
    ));
    notifyListeners();
  }
}

class ChaosPageManagerPage {
  final Widget widget;
  final String? title;
  final GlobalKey key;
  final ScrollController? scrollController;
  final VoidCallback? onHeaderTap;
  final VoidCallback? onPop;
  // List controls
  final dynamic listToCount;
  final List<Track>? listToShuffle;
  final String? sortList;
  final List<String>? availableSortTypes;
  final Function? onSortChanged;

  ChaosPageManagerPage({
    required this.widget,
    this.title,
    required this.key,
    this.scrollController,
    this.onHeaderTap,
    this.onPop,
    this.listToCount,
    this.listToShuffle,
    this.sortList,
    this.availableSortTypes,
    this.onSortChanged,
  });

  bool get hasControls =>
      listToCount != null ||
      listToShuffle != null ||
      sortList != null ||
      availableSortTypes != null;
}

class ChaosPageManager extends StatefulWidget {
  final ChaosPageManagerController controller;
  final VoidCallback onClose;

  const ChaosPageManager({
    Key? key,
    required this.controller,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ChaosPageManager> createState() => _ChaosPageManagerState();
}

class _ChaosPageManagerState extends State<ChaosPageManager>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _wasVisible = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutQuart,
    );

    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    final isVisible = widget.controller.isNotEmpty;

    if (isVisible != _wasVisible) {
      if (isVisible) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
      _wasVisible = isVisible;
    }

    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _scaleController.dispose();
    super.dispose();
  }

  void _handleBackPress() {
    HapticFeedback.mediumImpact();
    if (!widget.controller.pop()) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller.isEmpty) return const SizedBox.shrink();
    final chaosUIState = context.watch<ChaosUIState>();
    final radius = chaosUIState.chaosRadius;
    final chaosLevel = chaosUIState.chaosLevel;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.97 + (_scaleAnimation.value * 0.03),
          child: Container(
            decoration: BoxDecoration(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .background
                  .withValues(alpha: getAlphaPercentage(0.9, chaosLevel)),
              border: Border.all(
                color: AntiiQTheme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Column(
                children: [
                  _buildHeader(radius),
                  Expanded(
                    child: IndexedStack(
                      index: widget.controller.depth - 1,
                      sizing: StackFit.expand,
                      children: widget.controller._stack.map((page) {
                        return KeyedSubtree(
                          key: page.key,
                          child: ChaosPageManagerNavigator(
                            controller: widget.controller,
                            child: page.widget,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double radius) {
    final depth = widget.controller.depth;
    final page = widget.controller.currentPage!;
    final title = page.title ?? 'OVERLAY';
    final innerRadius = (radius - 2);
    final hasControls = page.hasControls;
    final chaosUIState = context.watch<ChaosUIState>();
    final chaosLevel = chaosUIState.chaosLevel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Back/Close button
              ChaosRotatedStatefulWidget(
                index: hashCode % 100,
                style: ChaosRotationStyle.random,
                maxAngle: getAnglePercentage(0.1, chaosLevel),
                child: GestureDetector(
                  onTap: _handleBackPress,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: depth > 1 ? 0.5 : 0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(innerRadius),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            depth > 1 ? Icons.arrow_back : Icons.close,
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        if (depth == 1)
                          Positioned(
                            left: 2,
                            top: 2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .error,
                                    width: 1,
                                  ),
                                  left: BorderSide(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .error,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: chaosBasePadding),

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (page.onHeaderTap != null) {
                      HapticFeedback.selectionClick();
                      page.onHeaderTap!();
                    } else if (page.scrollController != null) {
                      HapticFeedback.selectionClick();
                      page.scrollController!.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutQuart,
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: ChaosRotatedStatefulWidget(
                          index: hashCode % 200,
                          style: ChaosRotationStyle.random,
                          maxAngle: getAnglePercentage(0.1, chaosLevel),
                          child: Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (page.listToCount != null) ...[
                        const SizedBox(width: chaosBasePadding),
                        ChaosRotatedStatefulWidget(
                          index: hashCode % 300,
                          style: ChaosRotationStyle.random,
                          maxAngle: getAnglePercentage(0.1, chaosLevel),
                          child: Text(
                            '${page.listToCount.length}',
                            style: TextStyle(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .onBackground
                                  .withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (hasControls) _buildControls(page, innerRadius),

              // Depth indicator
              /*
              if (depth > 1 && !hasControls) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                  child: Text(
                    '$depth',
                    style: TextStyle(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              */
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ChaosPageManagerPage page, double radius) {
    final chaosUIState = context.watch<ChaosUIState>();
    final chaosLevel = chaosUIState.chaosLevel;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selection actions
        StreamBuilder<List<Track>>(
          stream: antiiqState.music.selection.flow.stream,
          builder: (context, snapshot) {
            final selection = snapshot.data ?? antiiqState.music.selection.list;
            if (selection.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: ChaosRotatedStatefulWidget(
                index: hashCode % 400,
                style: ChaosRotationStyle.random,
                maxAngle: getAnglePercentage(0.1, chaosLevel),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showTrackDetailsSheet(context, selection,
                        thisGlobalSelection: true,
                        pageManagerController: widget.controller);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.5),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Icon(
                      RemixIcon.list_check_3,
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Shuffle
        if (page.listToShuffle != null && page.listToShuffle!.length > 1)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ChaosRotatedStatefulWidget(
              index: hashCode % 500,
              style: ChaosRotationStyle.random,
              maxAngle: getAnglePercentage(0.1, chaosLevel),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  shuffleTracks(page.listToShuffle!);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Icon(
                    RemixIcon.shuffle,
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),

        // Sort
        if (page.sortList != null &&
            page.availableSortTypes != null &&
            page.availableSortTypes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: ChaosRotatedStatefulWidget(
              index: hashCode % 600,
              style: ChaosRotationStyle.random,
              maxAngle: getAnglePercentage(0.1, chaosLevel),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showSortModal(context, page);
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AntiiQTheme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: Icon(
                    RemixIcon.sort_asc,
                    color: AntiiQTheme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showSortModal(BuildContext context, ChaosPageManagerPage page) {
    final radius = context.read<ChaosUIState>().chaosRadius;
    final innerRadius = (radius - 2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AntiiQTheme.of(context).colorScheme.background,
          border: Border.all(
            color: AntiiQTheme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: _SortModalContent(
          page: page,
          radius: radius,
          innerRadius: innerRadius,
        ),
      ),
    );
  }
}

class _SortModalContent extends StatefulWidget {
  final ChaosPageManagerPage page;
  final double radius;
  final double innerRadius;

  const _SortModalContent({
    required this.page,
    required this.radius,
    required this.innerRadius,
  });

  @override
  State<_SortModalContent> createState() => _SortModalContentState();
}

class _SortModalContentState extends State<_SortModalContent> {
  late String currentDirection;
  late String currentSortType;

  @override
  void initState() {
    super.initState();
    _loadCurrentSort();
  }

  void _loadCurrentSort() {
    final sortList = widget.page.sortList!;
    if (sortList == "allTracks") {
      currentDirection = antiiqState.music.tracks.sort.currentDirection;
      currentSortType = antiiqState.music.tracks.sort.currentSort;
    } else if (sortList == "allAlbums") {
      currentDirection = antiiqState.music.albums.sort.currentDirection;
      currentSortType = antiiqState.music.albums.sort.currentSort;
    } else if (sortList == "allArtists") {
      currentDirection = antiiqState.music.artists.sort.currentDirection;
      currentSortType = antiiqState.music.artists.sort.currentSort;
    } else if (sortList == "allGenres") {
      currentDirection = antiiqState.music.genres.sort.currentDirection;
      currentSortType = antiiqState.music.genres.sort.currentSort;
    } else if (sortList == "allAlbumTracks") {
      currentDirection = antiiqState.music.albums.tracksSort.currentDirection;
      currentSortType = antiiqState.music.albums.tracksSort.currentSort;
    } else if (sortList == "allArtistTracks") {
      currentDirection = antiiqState.music.artists.tracksSort.currentDirection;
      currentSortType = antiiqState.music.artists.tracksSort.currentSort;
    } else if (sortList == "allGenreTracks") {
      currentDirection = antiiqState.music.genres.tracksSort.currentDirection;
      currentSortType = antiiqState.music.genres.tracksSort.currentSort;
    }
  }

  void _commenceSort(String sortType, String sortDirection) {
    final sortList = widget.page.sortList!;
    if (sortList == "allTracks") {
      beginSort(sortType, sortDirection, allTracks: true);
    } else if (sortList == "allAlbums") {
      beginSort(sortType, sortDirection, allAlbums: true);
    } else if (sortList == "allArtists") {
      beginSort(sortType, sortDirection, allArtists: true);
    } else if (sortList == "allGenres") {
      beginSort(sortType, sortDirection, allGenres: true);
    } else if (sortList == "allAlbumTracks") {
      beginSort(sortType, sortDirection, allAlbumTracks: true);
      widget.page.onSortChanged?.call();
    } else if (sortList == "allArtistTracks") {
      beginSort(sortType, sortDirection, allArtistTracks: true);
      widget.page.onSortChanged?.call();
    } else if (sortList == "allGenreTracks") {
      beginSort(sortType, sortDirection, allGenreTracks: true);
      widget.page.onSortChanged?.call();
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SORT BY',
            style: TextStyle(
              color: AntiiQTheme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          for (String sortType in widget.page.availableSortTypes!)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _commenceSort(sortType, currentDirection);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentSortType == sortType
                        ? AntiiQTheme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: currentSortType == sortType
                          ? AntiiQTheme.of(context).colorScheme.primary
                          : AntiiQTheme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(widget.innerRadius),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        sortType.toUpperCase(),
                        style: TextStyle(
                          color: currentSortType == sortType
                              ? AntiiQTheme.of(context).colorScheme.primary
                              : AntiiQTheme.of(context)
                                  .colorScheme
                                  .onBackground,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      if (currentSortType == sortType)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AntiiQTheme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Icon(
                            Icons.check,
                            color:
                                AntiiQTheme.of(context).colorScheme.onPrimary,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'DIRECTION',
            style: TextStyle(
              color: AntiiQTheme.of(context)
                  .colorScheme
                  .onBackground
                  .withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (String dir in sortDirections.keys) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (currentDirection != dir) {
                        HapticFeedback.selectionClick();
                        _commenceSort(currentSortType, dir);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: currentDirection == dir
                            ? AntiiQTheme.of(context)
                                .colorScheme
                                .secondary
                                .withValues(alpha: 0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: currentDirection == dir
                              ? AntiiQTheme.of(context).colorScheme.secondary
                              : AntiiQTheme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(widget.innerRadius),
                      ),
                      child: Center(
                        child: Text(
                          dir.toUpperCase(),
                          style: TextStyle(
                            color: currentDirection == dir
                                ? AntiiQTheme.of(context).colorScheme.secondary
                                : AntiiQTheme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (dir != sortDirections.keys.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ChaosPageManagerNavigator extends InheritedWidget {
  final ChaosPageManagerController controller;

  const ChaosPageManagerNavigator({
    Key? key,
    required this.controller,
    required Widget child,
  }) : super(key: key, child: child);

  static ChaosPageManagerController? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ChaosPageManagerNavigator>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(ChaosPageManagerNavigator oldWidget) {
    return controller != oldWidget.controller;
  }
}
