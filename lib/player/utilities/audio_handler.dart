//Dart Packages
import 'dart:async';

//Audio Handler
import 'package:antiiq/player/utilities/queue_state.dart';
import 'package:audio_service/audio_service.dart';

//Just Audio
import 'package:just_audio/just_audio.dart';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/file_handling/lists.dart';
import 'package:antiiq/player/utilities/audio_preferences.dart';

//Audio Handler
class AntiiqAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  AntiiqAudioHandler() {
    initialize();
  }

  //Audio Player Definition And Variable Declarations
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

  //Initial Setup
  initialize() {
    // Broadcast that we're connecting, and what controls are available.
    eventSubscription = audioPlayer.playbackEventStream.listen(
      (event) {
        broadcastState();
      },
    );
    audioPlayer.currentIndexStream.listen(
      (index) {
        if (index != null) {
          mediaItem.add(antiiqQueue[index]);
          indexOfQueue = index;
          if (addToQueueIndex == index) {
            addToQueueIndex = -1;
          }
        }
      },
    );

    audioPlayer.processingStateStream.listen(
      (state) {
        switch (state) {
          case ProcessingState.completed:
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
    activeQueue = antiiqQueue.sublist(getNowPlayingQueueIndex());
    if (activeQueue.isNotEmpty && activeQueue != queueState) {
      queueState = activeQueue;
      await saveQueueState();
    }
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
      default:
        throw Exception("Invalid state: ${audioPlayer.processingState}");
    }
  }

  //Class Methods (and some non- Class Methods, arranged according to their functions)
  @override
  Future<void> play() async {
    if (antiiqQueue.isEmpty) {
      if (queueState.isEmpty) {
        await updateQueue(
            currentTrackListSort.map((e) => e.mediaItem!).toList());
      } else {
        await updateQueue(queueState);
      }
    }
    audioPlayer.play();

    if (!bandsSet) {
      await setBands();
    }
  }

  @override
  Future<void> pause() async {
    audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    // Stop playing audio.
    audioPlayer.stop();
    eventSubscription.cancel();
    await broadcastState();
    // Broadcast that we've stopped.
    playbackState.add(PlaybackState(
        controls: [],
        playing: false,
        processingState: AudioProcessingState.completed));
    // Shut down this background task
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
    if (antiiqQueue.length > 1) {
      antiiqQueue.removeRange(
          getNowPlayingQueueIndex(), antiiqQueue.length);
      source.removeRange(getNowPlayingQueueIndex(), antiiqQueue.length);
      broadcastState();
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
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    antiiqQueue = newQueue;
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
}
