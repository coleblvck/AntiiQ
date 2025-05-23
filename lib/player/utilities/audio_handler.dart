import 'dart:async';

import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AntiiqAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AntiiqAudioHandler() {
    initialize();
  }

  late final AudioPlayer audioPlayer = AudioPlayer(
      handleInterruptions: true,
      androidApplyAudioAttributes: true,
      handleAudioSessionActivation: true,
      audioPipeline: AudioPipeline(androidAudioEffects: [
        equalizer,
        loudnessEnhancer,
      ]));

  final AndroidEqualizer equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer loudnessEnhancer = AndroidLoudnessEnhancer();

  List<MediaItem> antiiqQueue = [];
  int indexOfQueue = 0;
  int addToQueueIndex = -1;
  AudioProcessingState? skipState;
  late StreamSubscription<PlaybackEvent> eventSubscription;
  late ConcatenatingAudioSource source;
  int clicks = 0;
  
  initialize() {
    eventSubscription = audioPlayer.playbackEventStream.listen(
      (event) {
        broadcastState();
      },
    );
    audioPlayer.currentIndexStream.listen(
      (index) {
        if (index != null) {
          final currentItem = antiiqQueue[index];
          mediaItem.add(currentItem);
          indexOfQueue = index;
          
          if (addToQueueIndex == index) {
            addToQueueIndex = -1;
          }
        }
      },
    );

    mediaItem.stream.listen((currentItem) {
      if (currentItem != null) {
          _addToHistory(currentItem);
      }
    });

    audioPlayer.processingStateStream.listen(
      (state) {
        switch (state) {
          case ProcessingState.completed:
            audioPlayer.stop();
            audioPlayer.seek(Duration.zero);
            break;
          case ProcessingState.ready:
            skipState = null;
            break;
          default:
            break;
        }
      },
    );
  }

  Future<void> broadcastState() async {
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
        processingState: getProcessingState()!,
        playing: audioPlayer.playing,
        updatePosition: audioPlayer.position,
        bufferedPosition: audioPlayer.bufferedPosition,
        speed: audioPlayer.speed,
      ),
    );
    queue.add(
      antiiqQueue.sublist(getNowPlayingQueueIndex()),
    );
  }

  int getNowPlayingQueueIndex() {
    int? queueIndex = audioPlayer.currentIndex;
    if (queueIndex != null) {
      queueIndex = queueIndex + 1;
    } else {
      queueIndex = 0;
    }

    return queueIndex;
  }

  AudioProcessingState? getProcessingState() {
    if (skipState != null) return skipState;
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

  @override
  Future<void> play() async {
    if (antiiqQueue.isEmpty) {
      if (antiiqState.music.queue.initialState.isEmpty) {
        await updateQueue(
            antiiqState.music.tracks.list.map((e) => e.mediaItem!).toList());
      } else {
        await updateQueue(antiiqState.music.queue.initialState);
      }
    }
    audioPlayer.play();

    if (!antiiqState.audioSetup.preferences.bandsSet) {
      await antiiqState.audioSetup.preferences.setBands();
    }
  }

  @override
  Future<void> pause() async {
    audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    audioPlayer.stop();
    eventSubscription.cancel();
    await broadcastState();
    playbackState.add(PlaybackState(
        controls: [],
        playing: false,
        processingState: AudioProcessingState.completed));
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
  }

  @override
  Future<void> skipToPrevious() async {
    if (previousRestart) {
      if (audioPlayer.position > const Duration(seconds: 5)) {
        await audioPlayer.seek(const Duration(seconds: 0));
      } else {
        await audioPlayer.seekToPrevious();
      }
    } else {
      await audioPlayer.seekToPrevious();
    }
  }

  @override
  Future<void> skipToNext() async {
    await audioPlayer.seekToNext();
  }

  @override
  Future<void> rewind() async {
    if (audioPlayer.position > const Duration(seconds: 5)) {
      await audioPlayer.seek(audioPlayer.position - const Duration(seconds: 5));
    } else {
      await audioPlayer.seek(const Duration(seconds: 0));
    }
  }

  @override
  Future<void> fastForward() async {
    if (audioPlayer.position <
        audioPlayer.duration! - const Duration(seconds: 5)) {
      await audioPlayer.seek(audioPlayer.position + const Duration(seconds: 5));
    } else {
      await audioHandler.skipToNext();
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

/* Issues to be figured out
  Future<void> clearQueue() async {
    final currentIndex = audioPlayer.currentIndex;
    if (currentIndex != null && antiiqQueue.length > 1) {
      // Remove all items after the current one
      if (currentIndex < antiiqQueue.length - 1) {
        antiiqQueue.removeRange(currentIndex + 1, antiiqQueue.length);
        await source.removeRange(currentIndex + 1, source.length);
      }
      
      // Remove all items before the current one
      if (currentIndex > 0) {
        antiiqQueue.removeRange(0, currentIndex);
        await source.removeRange(0, currentIndex);
      }
      
      // Reset index tracking
      indexOfQueue = 0;
      addToQueueIndex = -1;
      
      await broadcastState();
    }
  }
  */

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    antiiqQueue.add(mediaItem);
    source.add(AudioSource.uri(Uri.parse(mediaItem.id)));
    broadcastState();
  }

  @override
  Future<void> insertQueueItem(int index, MediaItem mediaItem) async {
    antiiqQueue.insert(index + getNowPlayingQueueIndex() - 1, mediaItem);
    source.insert(index + getNowPlayingQueueIndex() - 1,
        AudioSource.uri(Uri.parse(mediaItem.id)));
    broadcastState();
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    antiiqQueue = queue;
    source = ConcatenatingAudioSource(
      children: antiiqQueue
          .map((item) => AudioSource.uri(Uri.parse(item.id)))
          .toList(),
    );
    await audioPlayer.setAudioSource(source, preload: false, initialIndex: 0);
    mediaItem.add(antiiqQueue[0]);
    addToQueueIndex = -1;
  }

  @override
  Future<void> click([MediaButton button = MediaButton.media]) async {
    switch (button) {
      case MediaButton.next:
        skipToNext();
        break;
      case MediaButton.previous:
        skipToPrevious();
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
                    audioPlayer.pause();
                  } else {
                    audioHandler.play();
                  }
                  clicks = 0;
                  break;
                case 2:
                  audioHandler.skipToNext();
                  clicks = 0;
                  break;
                case 3:
                  audioHandler.skipToPrevious();
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


  void _addToHistory(MediaItem item) {
    if (antiiqState.music.history.list.isNotEmpty && antiiqState.music.history.list.last.trackData?.trackId == item.extras?["id"]) {
      print(true);
      return;
    }
    print(false);
    final Track track = antiiqState.music.tracks.list.where((trk) => trk.trackData?.trackId == item.extras?["id"]).toList()[0];
    antiiqState.music.history.add(track);
  }
  
  // Method to manually add a track to history
  Future<void> addTrackToHistory(MediaItem item) async {
    _addToHistory(item);
  }
  

  List<MediaItem> getListenHistory() {
    return List.from(antiiqState.music.history.list.reversed);
  }
  
  Future<void> clearHistory() async {
    antiiqState.music.history.clear();
  }
}