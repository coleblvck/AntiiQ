import 'dart:async';
import 'dart:math';

import 'package:antiiq/player/global_variables.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// A cleaner queue management system for AntiiQ.
///
/// Key principles:
/// - Queue contains ONLY upcoming tracks (NOT current track)
/// - Only one item in audio source at a time (the currently playing track)
/// - Current track is completely separate from queue
/// - Queue manipulations never affect the currently playing source
/// - Next track is always queue[0], which gets removed when played
mixin AntiiqQueueHandler on BaseAudioHandler {
  // ============================================================================
  // PRIVATE STATE
  // ============================================================================

  /// The upcoming queue (does NOT include currently playing item)
  final List<MediaItem> _upcomingQueue = [];

  /// History of played items (most recent last)
  final List<MediaItem> _playHistory = [];

  /// Session-specific history (cleared on new queue)
  final List<MediaItem> _sessionHistory = [];

  /// Currently playing item (null if nothing is playing)
  MediaItem? _currentItem;

  /// Original queue order before shuffle (for un-shuffling)
  List<MediaItem>? _originalQueueOrder;

  /// Current shuffle mode
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;

  /// Current repeat mode
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;

  /// Maximum history size to prevent unbounded growth
  final int _maxHistorySize = 100;

  /// Random number generator for shuffle
  final Random _random = Random();

  // ============================================================================
  // PUBLIC ACCESSORS
  // ============================================================================

  /// Get only the upcoming queue (for broadcast and display)
  /// This should be what's shown in the UI
  List<MediaItem> get upcomingQueue => List.from(_upcomingQueue);

  /// Get play history (most recent first)
  List<MediaItem> get playHistory => _playHistory.reversed.toList();

  /// Add an item to session history
  void _addToSessionHistory(MediaItem item) {
    _sessionHistory.add(item);
    if (_sessionHistory.length > 20) {
      // smaller than main history
      _sessionHistory.removeAt(0);
    }
  }

  /// Get currently playing item
  MediaItem? get currentItem => _currentItem;

  /// Check if queue is empty (no upcoming tracks)
  bool get isQueueEmpty => _upcomingQueue.isEmpty;

  /// Get number of upcoming tracks
  int get queueLength => _upcomingQueue.length;

  /// Check if shuffle is enabled
  bool get isShuffleEnabled => _shuffleMode != AudioServiceShuffleMode.none;

  /// Get current shuffle mode
  AudioServiceShuffleMode get shuffleMode => _shuffleMode;

  /// Get current repeat mode
  AudioServiceRepeatMode get repeatMode => _repeatMode;

  // ============================================================================
  // ABSTRACT METHODS (must be implemented by the handler)
  // ============================================================================

  /// Load and play the given media item in the audio player
  /// This should set up a single-item audio source
  Future<void> loadAndPlayItem(MediaItem item);

  /// Stop the current audio player
  Future<void> stopPlayer();

  /// Get the current audio player instance
  AudioPlayer get audioPlayer;

  // ============================================================================
  // QUEUE MANIPULATION
  // ============================================================================

  /// Replace the entire queue and optionally start playing
  /// If initialIndex is 3 with items [0,1,2,3,4,5], queue becomes [3,4,5,0,1,2]
  /// and item 3 starts playing (removed from queue)
  @override
  Future<void> updateQueue(List<MediaItem> newQueue,
      {int initialIndex = 0}) async {
    _sessionHistory.clear();
    if (newQueue.isEmpty) {
      _upcomingQueue.clear();
      _originalQueueOrder = null;
      _currentItem = null;
      _broadcastQueue();
      return;
    }

    // Validate initial index
    if (initialIndex < 0 || initialIndex >= newQueue.length) {
      initialIndex = 0;
    }

    // Clear existing state
    _upcomingQueue.clear();
    _originalQueueOrder = null;

    // Reorder: [initialIndex...end, 0...initialIndex-1]
    final reorderedQueue = [
      ...newQueue.sublist(initialIndex),
      if (initialIndex > 0) ...newQueue.sublist(0, initialIndex),
    ];

    // First item becomes current (removed from queue)
    _currentItem = reorderedQueue.first;

    // Rest go to upcoming queue
    if (reorderedQueue.length > 1) {
      _upcomingQueue.addAll(reorderedQueue.sublist(1));
    }

    // *** ADD THIS: Apply shuffle if it's already enabled ***
    if (_shuffleMode != AudioServiceShuffleMode.none &&
        _upcomingQueue.isNotEmpty) {
      _originalQueueOrder = List.from(_upcomingQueue);
      _upcomingQueue.shuffle(_random);
    }

    // Load and play the current item
    await loadAndPlayItem(_currentItem!);

    // Broadcast only the upcoming queue
    _broadcastQueue();
  }

  /// Add a single item to the end of the queue
  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    _upcomingQueue.add(mediaItem);

    // Update original order if we're shuffled
    if (_originalQueueOrder != null) {
      _originalQueueOrder!.add(mediaItem);
    }

    _broadcastQueue();
  }

  /// Add multiple items to the end of the queue
  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    if (mediaItems.isEmpty) return;

    _upcomingQueue.addAll(mediaItems);

    // Update original order if we're shuffled
    if (_originalQueueOrder != null) {
      _originalQueueOrder!.addAll(mediaItems);
    }

    _broadcastQueue();
  }

  /// Insert an item at a specific position in the upcoming queue
  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    final clampedIndex = index.clamp(0, _upcomingQueue.length);
    _upcomingQueue.insert(clampedIndex, mediaItem);

    // Update original order if we're shuffled
    if (_originalQueueOrder != null) {
      _originalQueueOrder!.insert(clampedIndex, mediaItem);
    }

    _broadcastQueue();
  }

  /// Remove an item from the queue by value
  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    _upcomingQueue.remove(mediaItem);

    // Update original order if we're shuffled
    if (_originalQueueOrder != null) {
      _originalQueueOrder!.remove(mediaItem);
    }

    _broadcastQueue();
  }

  /// Remove an item from the queue by index
  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index >= 0 && index < _upcomingQueue.length) {
      final item = _upcomingQueue.removeAt(index);

      // Update original order if we're shuffled
      if (_originalQueueOrder != null) {
        _originalQueueOrder!.remove(item);
      }

      _broadcastQueue();
    }
  }

  /// Clear all upcoming items from the queue
  Future<void> clearQueue() async {
    _upcomingQueue.clear();
    _originalQueueOrder = null;
    _broadcastQueue();
  }

  /// Play a specific item from the queue immediately
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _upcomingQueue.length) return;

    // Add current item to history
    if (_currentItem != null) {
      _addToHistory(_currentItem!);
    }

    // Remove items before target from queue and add to history
    for (int i = 0; i < index; i++) {
      _addToHistory(_upcomingQueue.removeAt(0));
    }

    // Now queue[0] is our target, play it via _playNext
    await _playNext();
  }

  /// Move a queue item from one position to another
  Future<void> moveQueueItem(int fromIndex, int toIndex) async {
    if (fromIndex < 0 || fromIndex >= _upcomingQueue.length) return;
    if (toIndex < 0 || toIndex >= _upcomingQueue.length) return;
    if (fromIndex == toIndex) return;

    final item = _upcomingQueue.removeAt(fromIndex);
    final insertIndex = toIndex > fromIndex ? toIndex : toIndex;
    _upcomingQueue.insert(insertIndex, item);

    _broadcastQueue();
  }

  // ============================================================================
  // PLAYBACK NAVIGATION
  // ============================================================================

  /// Skip to the next item in the queue
  @override
  Future<void> skipToNext() async {
    await playNext();
  }

  /// Skip to the previous item from history
  @override
  Future<void> skipToPrevious() async {
    //TODO REMOVE GLOBAL VARIABLE FROM HERE
    if (previousRestart) {
      if (audioPlayer.position > const Duration(seconds: 5)) {
        await audioPlayer.seek(Duration.zero);
      } else {
        await _playPrevious();
      }
    } else {
      await _playPrevious();
    }
  }

  /// Play the next item from queue
  /// This is the main method for advancing playback
  /// Call this when track completes or user skips next
  Future<void> playNext() async {
    await _playNext();
  }

  /// Internal method to play the next item
  /// This is called when track completes or user skips
  Future<void> _playNext() async {
    // Handle repeat one - just replay current
    if (_repeatMode == AudioServiceRepeatMode.one && _currentItem != null) {
      await audioPlayer.seek(Duration.zero);
      await audioPlayer.play();
      return;
    }

    // Add current item to history and session history if it exists
    if (_currentItem != null) {
      _addToHistory(_currentItem!);
      _addToSessionHistory(_currentItem!);
    }

    // Check if there's a next item in queue
    if (_upcomingQueue.isEmpty) {
      // Handle repeat all - reload queue from history
      if (_repeatMode == AudioServiceRepeatMode.all &&
          _playHistory.isNotEmpty) {
        // Get all tracks that were played
        final allTracks = List<MediaItem>.from(_playHistory);

        // Clear history since we're starting over
        _playHistory.clear();

        // Set first as current
        _currentItem = allTracks.first;

        // Rest go to queue
        if (allTracks.length > 1) {
          _upcomingQueue.addAll(allTracks.sublist(1));
        }

        // Re-apply shuffle if needed
        if (_shuffleMode != AudioServiceShuffleMode.none) {
          _originalQueueOrder = List.from(_upcomingQueue);
          _upcomingQueue.shuffle(_random);
        }

        // Load and play
        await loadAndPlayItem(_currentItem!);
        _broadcastQueue();
        return;
      }

      // No more items and no repeat - stop
      _currentItem = null;
      await stopPlayer();
      _broadcastQueue();
      return;
    }

    // Get next item from queue[0] and remove it
    _currentItem = _upcomingQueue.removeAt(0);

    // Remove from original order if we're shuffled
    if (_originalQueueOrder != null) {
      _originalQueueOrder!.remove(_currentItem);
    }

    // Load and play
    await loadAndPlayItem(_currentItem!);

    _broadcastQueue();
  }

  /// Internal method to play the previous item
  Future<void> _playPrevious() async {
    // Check if there's a previous item in session history
    if (_sessionHistory.isEmpty) {
      if (_currentItem != null) {
        await audioPlayer.seek(Duration.zero);
      }
      return;
    }

    // Add current item back to the front of the queue
    if (_currentItem != null) {
      _upcomingQueue.insert(0, _currentItem!);

      // Update original order if we're shuffled
      if (_originalQueueOrder != null) {
        _originalQueueOrder!.insert(0, _currentItem!);
      }
    }

    // Get previous item from session history
    _currentItem = _sessionHistory.removeLast();

    // Load and play
    await loadAndPlayItem(_currentItem!);

    _broadcastQueue();
  }

  // ============================================================================
  // SHUFFLE & REPEAT
  // ============================================================================

  /// Set shuffle mode
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    if (mode == _shuffleMode) return;

    final wasShuffled = _shuffleMode != AudioServiceShuffleMode.none;
    final willShuffle = mode != AudioServiceShuffleMode.none;

    _shuffleMode = mode;

    if (!wasShuffled && willShuffle) {
      await _enableShuffle();
    } else if (wasShuffled && !willShuffle) {
      await _disableShuffle();
    }

    // Update playback state
    playbackState.add(playbackState.value.copyWith(
      shuffleMode: mode,
    ));
  }

  /// Enable shuffle - randomize the upcoming queue
  Future<void> _enableShuffle() async {
    if (_upcomingQueue.isEmpty) return;

    // Save original order
    _originalQueueOrder = List.from(_upcomingQueue);

    // Shuffle the queue in place
    _upcomingQueue.shuffle(_random);

    _broadcastQueue();
  }

  /// Disable shuffle - restore original order
  Future<void> _disableShuffle() async {
    if (_originalQueueOrder == null || _originalQueueOrder!.isEmpty) {
      _originalQueueOrder = null;
      return;
    }

    // Find items still in current queue
    final remainingItems = _upcomingQueue.toSet();

    // Restore original order, keeping only items that weren't removed
    _upcomingQueue.clear();
    _upcomingQueue.addAll(
        _originalQueueOrder!.where((item) => remainingItems.contains(item)));

    _originalQueueOrder = null;

    _broadcastQueue();
  }

  /// Set repeat mode
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    _repeatMode = mode;

    // Update playback state
    playbackState.add(playbackState.value.copyWith(
      repeatMode: mode,
    ));
  }

  // ============================================================================
  // HISTORY MANAGEMENT
  // ============================================================================

  /// Add an item to play history
  void _addToHistory(MediaItem item) {
    _playHistory.add(item);

    // Trim history if it exceeds max size
    if (_playHistory.length > _maxHistorySize) {
      _playHistory.removeAt(0);
    }
  }

  /// Clear play history
  Future<void> clearHistory() async {
    _playHistory.clear();
  }

  /// Get a specific number of recent items from history
  List<MediaItem> getRecentHistory({int count = 10}) {
    if (_playHistory.isEmpty) return [];

    final startIndex =
        (_playHistory.length - count).clamp(0, _playHistory.length);
    return _playHistory.sublist(startIndex).reversed.toList();
  }

  // ============================================================================
  // QUEUE QUERIES
  // ============================================================================

  /// Check if a specific item is in the queue (not including current)
  bool isInQueue(MediaItem item) {
    return _upcomingQueue.contains(item);
  }

  /// Check if item is currently playing
  bool isCurrentlyPlaying(MediaItem item) {
    return _currentItem == item;
  }

  /// Get the position of an item in the queue (-1 if not found)
  int getItemPosition(MediaItem item) {
    return _upcomingQueue.indexOf(item);
  }

  /// Get the next N items that will play
  List<MediaItem> getUpcomingItems({int count = 5}) {
    return _upcomingQueue.take(count).toList();
  }

  // ============================================================================
  // INTERNAL HELPERS
  // ============================================================================

  /// Broadcast the current queue state
  /// Queue stream should only contain upcoming tracks, NOT current
  void _broadcastQueue() {
    // Broadcast ONLY upcoming queue (not current item)
    queue.add(upcomingQueue);

    // Update media item separately
    if (_currentItem != null) {
      mediaItem.add(_currentItem);
    }
  }

  /// Get debug information about queue state
  Map<String, dynamic> getQueueDebugInfo() {
    return {
      'currentItem': _currentItem?.title ?? 'null',
      'upcomingCount': _upcomingQueue.length,
      'historyCount': _playHistory.length,
      'shuffleMode': _shuffleMode.toString(),
      'repeatMode': _repeatMode.toString(),
      'hasOriginalOrder': _originalQueueOrder != null,
      'upcomingTitles': _upcomingQueue.map((e) => e.title).take(5).toList(),
    };
  }

  // ============================================================================
  // CONVENIENCE METHODS
  // ============================================================================

  /// Play a track immediately (add to front of queue and play it)
  Future<void> playTrackNow(MediaItem item) async {
    // Add current item to history
    if (_currentItem != null) {
      _addToHistory(_currentItem!);
    }

    // Set as current and play
    _currentItem = item;
    await loadAndPlayItem(_currentItem!);

    _broadcastQueue();
  }

  /// Add track to play next (at front of queue)
  Future<void> playTrackNext(MediaItem item) async {
    await insertQueueItem(0, item);
  }

  /// Replace queue and start playing from beginning
  Future<void> playNewQueue(List<MediaItem> items) async {
    await updateQueue(items, initialIndex: 0);
  }
}
