import 'dart:async';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/antiiq_audio/queue_handler.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:antiiq/player/utilities/playlist_generator/playlist_generator.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

// Import your custom queue handler
// import 'antiiq_queue_handler.dart';

class AntiiqAudioHandler extends BaseAudioHandler
    with AntiiqQueueHandler, SeekHandler, ChangeNotifier {
  AntiiqAudioHandler() {
    initialize();
  }

  @override
  late final AudioPlayer audioPlayer = AudioPlayer(
    handleInterruptions: true,
    androidApplyAudioAttributes: true,
    handleAudioSessionActivation: true,
    audioPipeline: AudioPipeline(androidAudioEffects: [
      equalizer,
      loudnessEnhancer,
    ]),
  );

  final AndroidEqualizer equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer loudnessEnhancer = AndroidLoudnessEnhancer();

  late StreamSubscription<PlaybackEvent> eventSubscription;
  int clicks = 0;

  // Endless Play Properties
  bool _endlessPlayEnabled = false;
  bool _isGeneratingQueue = false;
  PlaylistType? _currentPlaylistContext;
  String? _currentFilterValue;
  final Set<String> _recentlyPlayedIds = {};
  final int _maxRecentTracking = 100;
  int _bufferThreshold = 8;
  int _generateBatchSize = 20;

  void initialize() {
    // Listen to playback events
    eventSubscription = audioPlayer.playbackEventStream.listen(
      (event) {
        broadcastState();
      },
    );

    // Listen to processing state for auto-advance
    audioPlayer.processingStateStream.listen(
      (state) {
        switch (state) {
          case ProcessingState.completed:
            _handleTrackCompleted();
            break;
          case ProcessingState.ready:
            break;
          default:
            break;
        }
      },
    );

    // Track played items for history
    mediaItem.stream.listen((currentItem) {
      if (currentItem != null) {
        _addToAntiiqHistory(currentItem);
      }
    });
  }

  // ============================================================================
  // QUEUE HANDLER IMPLEMENTATION (Required by AntiiqQueueHandler)
  // ============================================================================

  @override
  Future<void> loadAndPlayItem(MediaItem item) async {
    // Create a single-item audio source
    final audioSource = AudioSource.uri(Uri.parse(item.id));

    // Set it in the player
    await audioPlayer.setAudioSource(audioSource, preload: false);

    // Auto-play if player was playing
    if (playbackState.value.playing) {
      await audioPlayer.play();
    }

    // Update media item
    mediaItem.add(item);
    _onTrackStarted(item);
  }

  void _onTrackStarted(MediaItem item) {}

  @override
  Future<void> stopPlayer() async {
    await audioPlayer.stop();
    await audioPlayer.seek(Duration.zero);
  }

  // ============================================================================
  // PLAYBACK CONTROLS
  // ============================================================================

  @override
  Future<void> play() async {
    // If nothing is loaded (no current item and no queue)
    if (currentItem == null && isQueueEmpty) {
      // Initialize with default queue
      final defaultQueue = antiiqState.music.queue.initialState.isEmpty
          ? antiiqState.music.tracks.list.map((e) => e.mediaItem!).toList()
          : antiiqState.music.queue.initialState;

      if (defaultQueue.isNotEmpty) {
        await updateQueue(defaultQueue, initialIndex: 0);
        await audioPlayer.play();
        // updateQueue already loads and plays the first item (MY BAD; IT DOES NOT)
      }
    } else if (currentItem != null) {
      // We have a current item, just resume playback
      await audioPlayer.play();
    } else if (!isQueueEmpty) {
      // We have queue but no current item, play first from queue
      await playNext();
    }

    if (!antiiqState.audioSetup.preferences.bandsSet) {
      await antiiqState.audioSetup.preferences.setBands();
    }
  }

  @override
  Future<void> pause() async {
    await audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await stopPlayer();
    eventSubscription.cancel();
    await broadcastState();
    playbackState.add(PlaybackState(
      controls: [],
      playing: false,
      processingState: AudioProcessingState.completed,
    ));
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
  }

  // ============================================================================
  // TRACK COMPLETION HANDLING
  // ============================================================================

  Future<void> _handleTrackCompleted() async {
    // playNext() handles repeat modes internally
    await playNext();

    // Check if we need to extend queue for endless play
    if (_endlessPlayEnabled &&
        queueLength < _bufferThreshold &&
        !_isGeneratingQueue) {
      await _extendQueueForEndlessPlay();
    }
  }

  // ============================================================================
  // STATE BROADCASTING
  // ============================================================================

  Timer? _broadcastDebounce;

  Future<void> broadcastState() async {
    _broadcastDebounce?.cancel();
    _broadcastDebounce = Timer(const Duration(milliseconds: 16), () {
      playbackState.add(
        PlaybackState(
          controls: [
            MediaControl.rewind,
            MediaControl.skipToPrevious,
            if (audioPlayer.playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
            MediaControl.fastForward,
          ],
          systemActions: {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [1, 2, 3],
          processingState: getProcessingState(),
          playing: audioPlayer.playing,
          updatePosition: audioPlayer.position,
          bufferedPosition: audioPlayer.bufferedPosition,
          speed: audioPlayer.speed,
          repeatMode: playbackState.value.repeatMode,
          shuffleMode: playbackState.value.shuffleMode,
        ),
      );
    });
  }

  AudioProcessingState getProcessingState() {
    switch (audioPlayer.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // ============================================================================
  // HEADSET BUTTON HANDLING
  // ============================================================================

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.next:
        await skipToNext();
        break;
      case MediaButton.previous:
        await skipToPrevious();
        break;
      case MediaButton.media:
        clicks += 1;
        if (clicks == 1) {
          Timer(
            const Duration(milliseconds: 500),
            () async {
              switch (clicks) {
                case 1:
                  if (audioPlayer.playing) {
                    await pause();
                  } else {
                    await play();
                  }
                  clicks = 0;
                  break;
                case 2:
                  await skipToNext();
                  clicks = 0;
                  break;
                case 3:
                  await skipToPrevious();
                  clicks = 0;
                  break;
                default:
                  clicks = 0;
                  break;
              }
            },
          );
        }
        break;
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  // ============================================================================
  // HISTORY MANAGEMENT (Antiiq-specific)
  // ============================================================================

  void _addToAntiiqHistory(MediaItem item) {
    if (antiiqState.music.history.list.isNotEmpty &&
        antiiqState.music.history.list.last.trackData?.trackId ==
            item.extras?["id"]) {
      return;
    }

    final track = antiiqState.music.tracks.list
        .where((trk) => trk.trackData?.trackId == item.extras?["id"])
        .firstOrNull;

    if (track != null) {
      antiiqState.music.history.add(track);
    }
  }

  // ============================================================================
  // ENDLESS PLAY FUNCTIONALITY
  // ============================================================================

  void setEndlessPlay(bool enabled,
      {PlaylistType? context, String? filterValue}) {
    _endlessPlayEnabled = enabled;
    _currentPlaylistContext = context;
    _currentFilterValue = filterValue;
    notifyListeners();

    if (enabled) {
      _recentlyPlayedIds.clear();
      // Check if we need to extend immediately
      if (queueLength < _bufferThreshold) {
        _extendQueueForEndlessPlay();
      }
    } else {
      _isGeneratingQueue = false;
    }
  }

  /// Configure endless play parameters
  void configureEndlessPlay({
    int? bufferThreshold,
    int? generateBatchSize,
  }) {
    if (bufferThreshold != null) _bufferThreshold = bufferThreshold;
    if (generateBatchSize != null) _generateBatchSize = generateBatchSize;
  }

  Future<void> _extendQueueForEndlessPlay() async {
    if (!_endlessPlayEnabled || _isGeneratingQueue) return;

    _isGeneratingQueue = true;

    try {
      // Get recent tracks for context
      final recentTracks = getRecentHistory(count: 5);

      // Generate new tracks
      final newMediaItems = await _generateContextualTracks(
        seedTracks: recentTracks
            .map((mi) => antiiqState.music.tracks.list.firstWhere(
                (t) => t.mediaItem?.id == mi.id,
                orElse: () => throw Exception('Track not found')))
            .toList(),
        count: _generateBatchSize,
      );

      if (newMediaItems != null && newMediaItems.isNotEmpty) {
        // Filter out recently played tracks
        final filtered = newMediaItems
            .where((item) => !_recentlyPlayedIds.contains(item.id))
            .toList();

        if (filtered.isNotEmpty) {
          await addQueueItems(filtered);

          // Track these items
          for (final item in filtered) {
            _recentlyPlayedIds.add(item.id);
            if (_recentlyPlayedIds.length > _maxRecentTracking) {
              _recentlyPlayedIds.remove(_recentlyPlayedIds.first);
            }
          }
        }
      }
    } catch (e) {
      print('Error extending queue: $e');
    } finally {
      _isGeneratingQueue = false;
    }
  }

  /// Generate tracks based on current context
  Future<List<MediaItem>?> _generateContextualTracks({
    required List<Track> seedTracks,
    required int count,
  }) async {
    // If we have a specific playlist context, use that
    if (_currentPlaylistContext != null) {
      return await _generateFromContext(
        seedTracks: seedTracks,
        count: count,
      );
    }

    // Otherwise, use smart generation based on history
    return await _generateFromHistory(
      seedTracks: seedTracks,
      count: count,
    );
  }

  /// Generate tracks from specific playlist context
  Future<List<MediaItem>?> _generateFromContext({
    required List<Track> seedTracks,
    required int count,
  }) async {
    final generator = AntiiqPlaylistGenerator();

    try {
      switch (_currentPlaylistContext!) {
        case PlaylistType.genre:
        case PlaylistType.artist:
        case PlaylistType.album:
        case PlaylistType.year:
          // Continue with same filter
          return await generator.generatePlaylist(
            type: _currentPlaylistContext!,
            filterValue: _currentFilterValue,
            maxTracks: count,
            autoPlay: false,
          );

        case PlaylistType.similarToTrack:
          // Use most recent track as seed
          if (seedTracks.isNotEmpty) {
            return await generator.generatePlaylist(
              type: PlaylistType.similarToTrack,
              seedTrack: seedTracks.first,
              maxTracks: count,
              autoPlay: false,
            );
          }
          break;

        case PlaylistType.mood:
        case PlaylistType.tempo:
          // Continue with same mood/tempo
          return await generator.generatePlaylist(
            type: _currentPlaylistContext!,
            filterValue: _currentFilterValue,
            maxTracks: count,
            autoPlay: false,
          );

        default:
          // Fall back to history-based generation
          return await _generateFromHistory(
            seedTracks: seedTracks,
            count: count,
          );
      }
    } catch (e) {
      print('Error generating from context: $e');
    }

    return null;
  }

  /// Generate tracks from listening history
  Future<List<MediaItem>?> _generateFromHistory({
    required List<Track> seedTracks,
    required int count,
  }) async {
    final generator = AntiiqPlaylistGenerator();

    try {
      // If we have recent history, use it
      if (seedTracks.isNotEmpty) {
        final playHistory = antiiqState.music.history.list;

        return await generator.generatePlaylist(
          type: PlaylistType.fromHistory,
          playHistory: playHistory.isEmpty ? seedTracks : playHistory,
          maxTracks: count,
          autoPlay: false,
        );
      }

      // If we have a current track, base on similarity
      final currentItem = mediaItem.value;
      if (currentItem != null) {
        final currentTrack = antiiqState.music.tracks.list
            .where((t) => t.mediaItem?.id == currentItem.id)
            .firstOrNull;

        if (currentTrack != null) {
          return await generator.generatePlaylist(
            type: PlaylistType.similarToTrack,
            seedTrack: currentTrack,
            maxTracks: count,
            autoPlay: false,
          );
        }
      }

      // Last resort: shuffle all
      return await generator.generatePlaylist(
        type: PlaylistType.shuffleAll,
        maxTracks: count,
        autoPlay: false,
      );
    } catch (e) {
      print('Error generating from history: $e');
    }

    return null;
  }

  /// Get endless play status
  bool get isEndlessPlayEnabled => _endlessPlayEnabled;

  /// Get current generation status
  bool get isGeneratingQueue => _isGeneratingQueue;

  /// Get remaining tracks count
  int get remainingTracksCount {
    return upcomingQueue.length;
  }

  /// Manually trigger queue extension (useful for testing or user request)
  Future<void> manualExtendQueue() async {
    await _extendQueueForEndlessPlay();
  }

  /// Clear endless play tracking data
  void clearEndlessPlayData() {
    _recentlyPlayedIds.clear();
    _currentPlaylistContext = null;
    _currentFilterValue = null;
  }

  // ============================================================================
  // CONVENIENCE METHODS
  // ============================================================================

  /// Play a track immediately (add to front of queue and skip to it)
  Future<void> playTrackNow(MediaItem item) async {
    await insertQueueItem(0, item);
    await skipToQueueItem(0);
  }

  /// Add track to play next (after current track)
  Future<void> playTrackNext(MediaItem item) async {
    await insertQueueItem(0, item);
  }

  /// Replace queue and start playing from beginning
  Future<void> playNewQueue(List<MediaItem> items) async {
    await updateQueue(items, initialIndex: 0);
    await play();
  }

  /// Get debug information
  void printQueueDebugInfo() {
    final info = getQueueDebugInfo();
    print('=== Queue Debug Info ===');
    info.forEach((key, value) {
      print('$key: $value');
    });
  }

  // ============================================================================
  // FALLBACKS
  // ============================================================================

  MediaItem blankMediaItem = MediaItem(
    id: "",
    title: "",
    album: "",
    artist: "",
    artUri: defaultArtUri,
    duration: const Duration(seconds: 100),
    extras: {"id": 1},
  );
}
