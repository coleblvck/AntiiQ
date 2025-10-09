import 'dart:async';
import 'dart:io';

import 'package:antiiq/chaos/chaos_global_constants.dart';
import 'package:antiiq/chaos/chaos_ui/chaos_canvas.dart';
import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/chaos_ui/chaos_rotation.dart';
import 'package:antiiq/chaos/widgets/chaos/chaos_equalizer.dart';
import 'package:antiiq/chaos/widgets/chaos/albums_grid.dart';
import 'package:antiiq/chaos/widgets/chaos/artists_list.dart';
import 'package:antiiq/chaos/widgets/chaos/bottom_navigation.dart';
import 'package:antiiq/chaos/widgets/chaos/chaos_header.dart';
import 'package:antiiq/chaos/widgets/chaos/chaos_playlist_generator.dart';
import 'package:antiiq/chaos/widgets/chaos/genres_grid.dart';
import 'package:antiiq/chaos/widgets/chaos/chaos_mini_player.dart';
import 'package:antiiq/chaos/widgets/chaos/playlist.dart';
import 'package:antiiq/chaos/widgets/chaos/search.dart';
import 'package:antiiq/chaos/widgets/chaos/tracklist.dart';
import 'package:antiiq/chaos/widgets/chaos_queue.dart';
import 'package:antiiq/chaos/widgets/track_details_sheet.dart';
import 'package:antiiq/chaos/page_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';
import 'package:antiiq/player/utilities/audio_handler.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/file_handling/sort.dart';
import 'package:antiiq/player/widgets/cutom_switch.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';

class TypographyChaosDashboard extends StatefulWidget {
  const TypographyChaosDashboard({Key? key}) : super(key: key);

  @override
  State<TypographyChaosDashboard> createState() =>
      _TypographyChaosDashboardState();
}

class _TypographyChaosDashboardState extends State<TypographyChaosDashboard>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late ChaosPageManagerController _pageManagerController;
  late CanvasController _canvasController;
  bool _canvasInitialized = false;

  bool isPlayerExpanded = false;
  int selectedNavIndex = 0;

  ChaosMiniPlayerController? _playerController;
  BottomNavigationController? _navController;
  double _bottomNavHeight = 100.0;

  late Timer libraryLoadTimer;
  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _pageManagerController = ChaosPageManagerController();

    _canvasController = CanvasController(
      canvasSize: const Size(400, 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (antiiqState.permissions.has) {
        initData();
      }
    });
  }

  Future<void> _initializeCanvas() async {
    final screenSize = MediaQuery.of(context).size;
    final canvasSize = screenSize * 2.5;

    _canvasController.updateCanvasSize(canvasSize);

    final savedState = context.read<ChaosUIState>().canvasState;
    if (savedState != null) {
      _canvasController.fromJsonWithDefaults(savedState);
    } else {
      _canvasController.initializeDefault();

      final centerOffset = Offset(
        -(canvasSize.width - screenSize.width) / 2,
        -(canvasSize.height - screenSize.height) / 2,
      );
      _canvasController.setPanOffset(centerOffset);
    }

    _canvasController.addListener(_saveCanvasState);
  }

  Future<void> _saveCanvasState() async {
    final chaosState = context.read<ChaosUIState>();
    await chaosState.setCanvasState(_canvasController.toJson());
  }

  initData() async {
    showDialog(
      useSafeArea: true,
      barrierDismissible: false,
      context: context,
      builder: (context) {
        final chaosUIState = context.read<ChaosUIState>();
        final currentRadius = chaosUIState.chaosRadius;
        final innerRadius = chaosUIState.getAdjustedRadius(4);
        return StatefulBuilder(builder: (context, setState) {
          int loadProgress = libraryLoadProgress;
          int loadTotal = libraryLoadTotal;
          String message = loadingMessage;
          libraryLoadTimer =
              Timer.periodic(const Duration(seconds: 1), (timer) {
            if (context.mounted) {
              setState(() {});
            }
          });
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: AntiiQTheme.of(context).colorScheme.background,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(currentRadius),
                side: BorderSide(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(chaosBasePadding * 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.toUpperCase(),
                      style: TextStyle(
                        color: AntiiQTheme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(innerRadius),
                        child: Stack(
                          children: [
                            Container(
                              color: AntiiQTheme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.2),
                            ),
                            FractionallySizedBox(
                              widthFactor: loadProgress / loadTotal,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.5),
                                  border: Border(
                                    right: BorderSide(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .secondary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "PROCESSING FILES $loadProgress OF $loadTotal",
                      style: TextStyle(
                        color: AntiiQTheme.of(context)
                            .colorScheme
                            .onBackground
                            .withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
    await antiiqState.libraryInit();

    libraryLoadTimer.cancel();

    if (mounted) {
      stateSet();
      libraryLoadTotal = 1;
      libraryLoadProgress = 0;
      loadingMessage = "Loading Library";
      Navigator.of(context).pop();
    } else {
      return;
    }
  }

  stateSet() {
    setState(() {});
  }

  Future<bool> showChaosExitDialog() async {
    final chaosUIState = context.read<ChaosUIState>();
    final radius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);

    return await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.85),
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: AntiiQTheme.of(context).colorScheme.background,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
                side: BorderSide(
                  color: AntiiQTheme.of(context).colorScheme.error,
                  width: 2,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: -0.015,
                      child: Text(
                        'TERMINATE SESSION',
                        style: TextStyle(
                          color: AntiiQTheme.of(context).colorScheme.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .onBackground
                              .withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                      child: Transform.rotate(
                        angle: 0.008,
                        child: Text(
                          'EXIT APPLICATION?',
                          style: TextStyle(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .onBackground,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Transform.rotate(
                            angle: 0.01,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.of(context).pop(false);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(innerRadius),
                                ),
                                child: Center(
                                  child: Text(
                                    'CANCEL',
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Transform.rotate(
                            angle: -0.012,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.heavyImpact();
                                Navigator.of(context).pop(true);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color:
                                      AntiiQTheme.of(context).colorScheme.error,
                                  border: Border.all(
                                    color: AntiiQTheme.of(context)
                                        .colorScheme
                                        .error,
                                    width: 2,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(innerRadius),
                                ),
                                child: Center(
                                  child: Text(
                                    'EXIT',
                                    style: TextStyle(
                                      color: AntiiQTheme.of(context)
                                          .colorScheme
                                          .onError,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ) ??
        false;
  }

  Future<bool> chaosTapToQuit() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;

      HapticFeedback.mediumImpact();

      Fluttertoast.showToast(
        msg: "TAP AGAIN TO TERMINATE",
        backgroundColor:
            AntiiQTheme.of(context).colorScheme.primary.withValues(alpha: 0.95),
        textColor: AntiiQTheme.of(context).colorScheme.onPrimary,
        gravity: ToastGravity.BOTTOM,
      );

      return Future.value(false);
    } else {
      HapticFeedback.heavyImpact();
      return Future.value(true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setStatusBarColor();
    if (!_canvasInitialized) {
      _initializeCanvas();
      _canvasInitialized = true;
    }

    final newSize = MediaQuery.of(context).size;
    // Only respond to significant size changes, and preserve state
    if ((_canvasController.canvasSize.width - newSize.width).abs() > 50) {
      // TODO: Handle orientation change, maybe just adjust pan limits without recreating
    }
  }

  void _setStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness,
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pageManagerController.dispose();
    _canvasController.dispose();
    super.dispose();
  }

  void _handleTypographyElementTapped(CanvasElement element) {
    switch (element.id) {
      case 'songs':
        final ScrollController scrollController = ScrollController();
        _pageManagerController.push(
          StreamBuilder<List<Track>>(
            stream: antiiqState.music.tracks.flow.stream,
            builder: (context, snapshot) {
              final tracks = snapshot.data ?? antiiqState.music.tracks.list;
              return TrackList(
                tracks: tracks,
                accentColor: AntiiQTheme.of(context).colorScheme.primary,
                scrollController: scrollController,
              );
            },
          ),
          title: 'SONGS',
          scrollController: scrollController,
          listToCount: antiiqState.music.tracks.list,
          listToShuffle: antiiqState.music.tracks.list,
          sortList: "allTracks",
          availableSortTypes: trackListSortTypes,
          onPop: () {
            scrollController.dispose();
          },
        );
        break;
      case 'albums':
        final ScrollController scrollController = ScrollController();
        _pageManagerController.push(
          AlbumsGrid(
            scrollController: scrollController,
          ),
          title: 'ALBUMS',
          scrollController: scrollController,
          listToCount: antiiqState.music.albums.list,
          listToShuffle: const [],
          sortList: "allAlbums",
          availableSortTypes: albumListSortTypes,
          onPop: () {
            scrollController.dispose();
          },
        );
        break;
      case 'artists':
        final ScrollController scrollController = ScrollController();
        _pageManagerController.push(
          ArtistsList(
            scrollController: scrollController,
          ),
          title: 'ARTISTS',
          scrollController: scrollController,
          listToCount: antiiqState.music.artists.list,
          listToShuffle: const [],
          sortList: "allArtists",
          availableSortTypes: artistListSortTypes,
          onPop: () {
            scrollController.dispose();
          },
        );
        break;
      case 'genres':
        final ScrollController scrollController = ScrollController();
        _pageManagerController.push(
          GenresGrid(
            scrollController: scrollController,
          ),
          title: 'GENRES',
          scrollController: scrollController,
          listToCount: antiiqState.music.genres.list,
          listToShuffle: const [],
          sortList: "allGenres",
          availableSortTypes: genreListSortTypes,
          onPop: () {
            scrollController.dispose();
          },
        );
        break;
      case 'playlists':
        final ScrollController scrollController = ScrollController();
        _pageManagerController.push(
          ChaosPlaylistsGrid(
            scrollController: scrollController,
          ),
          title: 'PLAYLISTS',
          scrollController: scrollController,
          listToCount: antiiqState.music.playlists.list,
          onPop: () {
            scrollController.dispose();
          },
        );
        break;

      case 'smartmix':
        _pageManagerController.push(
          const ChaosPlaylistGenerator(),
          title: 'Smart Mix',
        );
        break;
      case 'favourites':
        final ScrollController scrollController = ScrollController();
        _pageManagerController.push(
          StreamBuilder<List<Track>>(
            stream: antiiqState.music.favourites.flow.stream,
            builder: (context, snapshot) {
              final tracks = snapshot.data ?? antiiqState.music.favourites.list;
              return TrackList(
                tracks: tracks,
                accentColor: AntiiQTheme.of(context).colorScheme.primary,
                scrollController: scrollController,
              );
            },
          ),
          title: 'Favourites',
          scrollController: scrollController,
          listToCount: antiiqState.music.favourites.list,
          listToShuffle: antiiqState.music.favourites.list,
          sortList: "none",
          availableSortTypes: [],
          onPop: () {
            scrollController.dispose();
          },
        );
        break;
      case 'history':
        final ScrollController scrollController = ScrollController();
        _pageManagerController.push(
          StreamBuilder<List<Track>>(
            stream: antiiqState.music.history.flow.stream,
            builder: (context, snapshot) {
              final List<Track> history = snapshot.data?.reversed.toList() ??
                  antiiqState.music.history.list.reversed.toList();
              return TrackList(
                tracks: history,
                accentColor: AntiiQTheme.of(context).colorScheme.primary,
                scrollController: scrollController,
              );
            },
          ),
          title: 'History',
          scrollController: scrollController,
          listToCount: antiiqState.music.history.list,
          listToShuffle: antiiqState.music.history.list,
          sortList: "none",
          availableSortTypes: [],
          onPop: () {
            scrollController.dispose();
          },
        );
        break;
      case 'selection':
        final ScrollController scrollController = ScrollController();
        _pageManagerController.push(
          StreamBuilder<List<Track>>(
            stream: antiiqState.music.selection.flow.stream,
            builder: (context, snapshot) {
              final List<Track> selection =
                  snapshot.data ?? antiiqState.music.selection.list;
              return TrackList(
                tracks: selection,
                accentColor: AntiiQTheme.of(context).colorScheme.primary,
                scrollController: scrollController,
              );
            },
          ),
          title: 'Selection',
          scrollController: scrollController,
          listToCount: antiiqState.music.selection.list,
          listToShuffle: antiiqState.music.selection.list,
          sortList: "none",
          availableSortTypes: [],
          onPop: () {
            scrollController.dispose();
          },
        );
        break;
      default:
        _pageManagerController.push(
            Center(
              child: Text(
                element.id.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            title: element.id.toUpperCase());
    }

    HapticFeedback.mediumImpact();
  }

  void _handleNavigationItemSelected(int index) {
    if (index >= 0) {
      final item = _navController?.selectedItem;

      switch (item?.id) {
        case 'dashboard':
          setState(() {
            _pageManagerController.clear();
          });
          break;
        case 'equalizer':
          _pageManagerController.openPage(
            const ChaosEqualizer(),
            title: 'EQUALIZER',
          );
          _consequentialMiniPlayerClose();
          break;
        case 'search':
          _pageManagerController.openPage(
            const ChaosSearch(),
            title: 'SEARCH',
            listToShuffle: [],
          );
          break;
      }
    }
  }

  void _consequentialMiniPlayerClose() {
    if (_playerController?.isExpanded == true) {
      _playerController?.collapse();
    }
  }

  void _openMiniPlayer() {
    if (_playerController?.isCollapsed == true) {
      _playerController?.expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (_playerController?.isExpanded == true) {
            _playerController?.collapse();
          } else {
            final userCanPop = _pageManagerController.isEmpty;
            if (userCanPop) {
              final bool shouldPop = currentQuitType == QuitType.dialog
                  ? await showChaosExitDialog()
                  : await chaosTapToQuit();

              if (context.mounted && shouldPop) {
                _saveCanvasState();
                globalAntiiqAudioHandler.stop();
                SystemNavigator.pop();
              }
            } else {
              _pageManagerController.pop();
              if (_pageManagerController.currentPage == null) {
                _navController?.selectItem(0);
              }
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Background image
            StreamBuilder<MediaItem?>(
              stream: currentPlaying(),
              builder: (context, snapshot) {
                MediaItem? currentTrack = snapshot.data ?? currentDefaultSong;
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: currentTrack.artUri != null
                          ? FileImage(File.fromUri(currentTrack.artUri!))
                          : const AssetImage('assets/placeholder.png')
                              as ImageProvider,
                      fit: BoxFit.cover,
                      opacity: 0.1,
                    ),
                  ),
                );
              },
            ),

            // Main content
            Stack(
              children: [
                // Typography canvas
                ChaosCanvas(
                  controller: _canvasController,
                  floatAnimation: _floatController,
                  onElementTapped: _handleTypographyElementTapped,
                  onCanvasTapped: _consequentialMiniPlayerClose,
                  canInteract: () {
                    return _pageManagerController.isEmpty;
                  },
                  overlays: [
                    CanvasOverlay(
                      anchor: CanvasOverlayAnchor.custom,
                      useSafeArea: false,
                      top: 24 + MediaQuery.of(context).padding.top,
                      left: 24,
                      right: 24,
                      child: ChaosHeader(
                        pageManagerController: _pageManagerController,
                      ),
                    ),
                  ],
                ),

                //TODO: Note: App header used to be here

                _buildMiniPlayerContainer(),

                // Bottom navigation
                CollapsibleBottomNavigation(
                  autoCollapseDuration: const Duration(seconds: 3),
                  navigationItems: const [
                    NavigationItem(
                      id: 'dashboard',
                      label: 'DASHBOARD',
                      metadata: {'page': 'dashboard'},
                    ),
                    NavigationItem(
                      id: 'equalizer',
                      label: 'EQUALIZER',
                      metadata: {'page': 'equalizer'},
                    ),
                    NavigationItem(
                      id: 'search',
                      label: 'SEARCH',
                      metadata: {'page': 'search'},
                    ),
                  ],
                  selectedIndex: 0,
                  onControllerReady: (controller) =>
                      _navController = controller,
                  onItemTapped: (index) {
                    setState(() {
                      selectedNavIndex = index;
                    });
                  },
                  onItemSelected: _handleNavigationItemSelected,
                  onStateChanged: (state, height) {
                    setState(() {
                      _bottomNavHeight =
                          height + MediaQuery.of(context).padding.bottom;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayerContainer() {
    return Positioned(
      bottom: (_bottomNavHeight + chaosBasePadding),
      left: chaosBasePadding,
      right: chaosBasePadding,
      height: MediaQuery.of(context).size.height -
          (_bottomNavHeight + chaosBasePadding) -
          MediaQuery.of(context).padding.vertical -
          chaosBasePadding,
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ChaosPageManager(
                      controller: _pageManagerController,
                      onClose: () {
                        setState(() {
                          _pageManagerController.clear();
                        });
                        _navController?.selectItem(0);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: chaosBasePadding),
              StreamBuilder<MediaItem?>(
                  stream: currentPlaying(),
                  builder: (context, snapshot) {
                    final currentTrack = snapshot.data ?? currentDefaultSong;
                    return ChaosMiniPlayer(
                      onControllerReady: (controller) {
                        _playerController = controller;
                      },
                      onHeightChanged: (height) {
                        if (mounted) {
                          setState(() {
                            _miniPlayerHeight = height;
                            if (_playerController?.expansionProgress != null) {
                              _miniPlayerExpandProgress =
                                  _playerController!.expansionProgress;
                            }
                          });
                        }
                      },
                      animationConfig: const ChaosMiniPlayerAnimationConfig(
                        expansionDuration: Duration(milliseconds: 100),
                        expansionCurve: Curves.easeOutQuart,
                        dragSnapBackDuration: Duration(milliseconds: 100),
                        dragSnapBackCurve: Curves.easeOutBack,
                        dragVisualDampening: 0.75,
                        horizontalThreshold: 30.0,
                        verticalThreshold: 20.0,
                        usePhysicsBasedDrag: true,
                        dragFriction: 0.01,
                        dragSpringStiffness: 100,
                      ),
                      onLeftDrag: (data) => next(),
                      onRightDrag: (data) => previous(),
                      onUpDrag: (data) => _openMiniPlayer(),
                      onDownDrag: (data) => _consequentialMiniPlayerClose(),
                      onLongPress: () {
                        findTrackAndOpenSheet(context, currentTrack,
                            pageManagerController: _pageManagerController);
                      },
                      onTrackInfoChanged: (item, playbackState) {},
                      onStateChanged: (playerState, progress) {},
                    );
                  }),
            ],
          ),
          _buildQueueButton()
        ],
      ),
    );
  }

  double _miniPlayerHeight = 72.0;
  double _miniPlayerExpandProgress = 0.0;

  Widget _buildQueueButton() {
    final chaosUIState = context.watch<ChaosUIState>();
    final antiiQState = context.read<AntiiqState>();
    final radius = chaosUIState.chaosRadius;
    final innerRadius = chaosUIState.getAdjustedRadius(2);
    final thumbRadius = chaosUIState.getAdjustedRadius(8);

    return StreamBuilder<List<MediaItem>>(
      stream: antiiqState.music.queue.flow.stream,
      builder: (context, snapshot) {
        final queue = snapshot.data ?? antiiqState.music.queue.state;

        return Positioned(
          bottom: _miniPlayerHeight +
              (chaosBasePadding / 2) -
              18, // Overlaps mini player
          left: chaosBasePadding,
          child: Row(
            children: [
              if (queue.isNotEmpty) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final ScrollController scrollController =
                        ScrollController();
                    _pageManagerController.push(
                      ChaosQueue(
                        scrollController: scrollController,
                      ),
                      title: 'QUEUE',
                      scrollController: scrollController,
                      onPop: () {
                        scrollController.dispose();
                      },
                    );
                  },
                  child: Transform.rotate(
                    angle: ChaosRotation.calculate(
                      index: hashCode % 1000,
                      style: ChaosRotationStyle.fibonacci,
                      maxAngle: 0.15,
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AntiiQTheme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: AntiiQTheme.of(context)
                              .colorScheme
                              .primary
                              .withValues(
                                  alpha:
                                      (0.3 + (0.2 * _miniPlayerExpandProgress))
                                          .clamp(0.0, 1.0)),
                          width: 1 + _miniPlayerExpandProgress,
                        ),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              RemixIcon.play_list,
                              color:
                                  AntiiQTheme.of(context).colorScheme.primary,
                              size: 16,
                            ),
                          ),
                          Positioned(
                            right: 3,
                            top: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: AntiiQTheme.of(context)
                                    .colorScheme
                                    .secondary,
                                borderRadius:
                                    BorderRadius.circular(innerRadius),
                              ),
                              constraints: const BoxConstraints(minWidth: 12),
                              child: Text(
                                '${queue.length}',
                                style: TextStyle(
                                  color: AntiiQTheme.of(context)
                                      .colorScheme
                                      .onSecondary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: chaosBasePadding,
                ),
              ],
              Consumer<AntiiqAudioHandler>(
                builder: (context, state, child) {
                  return CustomSwitch(
                    value: state.isEndlessPlayEnabled,
                    onChanged: (value) {
                      HapticFeedback.mediumImpact();
                      antiiQState.audioSetup.preferences.setEndlessPlayEnabled(
                        value,
                      );
                    },
                    width: 60,
                    height: 36,
                    thumbSize: 18,
                    activeIcon: RemixIcon.infinity,
                    activeIconColor:
                        AntiiQTheme.of(context).colorScheme.onPrimary,
                    inactiveIcon: RemixIcon.infinity,
                    inactiveIconColor:
                        AntiiQTheme.of(context).colorScheme.onSurface,
                    trackPadding: 10,
                    trackBorderWidth: 1 + _miniPlayerExpandProgress,
                    activeTrackBorderColor: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(
                            alpha: (0.3 + (0.2 * _miniPlayerExpandProgress))
                                .clamp(0.0, 1.0)),
                    inactiveTrackBorderColor: AntiiQTheme.of(context)
                        .colorScheme
                        .primary
                        .withValues(
                            alpha: (0.3 + (0.2 * _miniPlayerExpandProgress))
                                .clamp(0.0, 1.0)),
                    activeTrackColor:
                        AntiiQTheme.of(context).colorScheme.surface,
                    inactiveTrackColor:
                        AntiiQTheme.of(context).colorScheme.background,
                    activeThumbColor:
                        AntiiQTheme.of(context).colorScheme.primary,
                    inactiveThumbColor:
                        AntiiQTheme.of(context).colorScheme.surface,
                    trackBorderRadius: radius,
                    thumbBorderRadius: thumbRadius,
                    thumbElevation: 1,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
