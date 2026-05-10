//Audio Service
import 'dart:io';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/file_handling/audio_metadata_bridge.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

playFromList(int index, List<MediaItem> listToPlay) async {
  await handleList(index, listToPlay);
  await globalAntiiqAudioHandler.play();
}

Future<void> handleList(int indexOfSong, List<MediaItem> listToPlay) async {
  queueToLoad = listToPlay; // Keep original list
  currentDefaultSong = listToPlay[indexOfSong];
  await loadQueue(queueToLoad, initialIndex: indexOfSong);
}

Future<void> loadQueue(List<MediaItem> queue, {int initialIndex = 0}) async {
  await globalAntiiqAudioHandler.updateQueue(queue, initialIndex: initialIndex);
}

resume() async {
  await globalAntiiqAudioHandler.play();
}

pause() async {
  await globalAntiiqAudioHandler.pause();
}

next() async {
  await globalAntiiqAudioHandler.skipToNext();
}

previous() async {
  await globalAntiiqAudioHandler.skipToPrevious();
}

forward() async {
  await globalAntiiqAudioHandler.fastForward();
}

rewind() async {
  await globalAntiiqAudioHandler.rewind();
}

playOnlyThis(MediaItem item) async {
  queueToLoad = [item];
  await loadQueue(queueToLoad);
  await globalAntiiqAudioHandler.play();
}

playTracks(List<Track> tracks) async {
  queueToLoad = tracks.map((track) => track.mediaItem!).toList();
  await loadQueue(queueToLoad);
  await globalAntiiqAudioHandler.play();
}

playTrackNext(MediaItem item) async {
  await globalAntiiqAudioHandler.playTrackNext(item);
}

addToQueue(item) async {
  await globalAntiiqAudioHandler.addQueueItem(item);
}

shuffleList(List<MediaItem> list) async {
  await antiiqState.audioSetup.preferences.updateShuffleMode(true);
  await loadQueue(list);
  await next();
  await resume();
}

shuffleTracks(List<Track> list) async {
  List<MediaItem> itemList = list.map((e) => e.mediaItem!).toList();
  await shuffleList(itemList);
}

playFromIntentLink(String link) async {
  try {
    final prepared = await AudioMetadataBridge.prepareIntentAudio(link);
    AudioMetadata? metadata;
    try {
      metadata = await AudioMetadataBridge.getMetadata(prepared.path);
    } catch (error) {
      debugPrint("Intent metadata fallback: $error");
    }

    Uint8List? artBytes;
    try {
      artBytes = await AudioMetadataBridge.extractArtwork(
        prepared.path,
        quality: 90,
      );
    } catch (error) {
      debugPrint("Intent artwork fallback: $error");
    }
    Uri artUri = defaultArtUri;

    if (artBytes != null) {
      final tempArtPath = "${antiiqDirectory.path}/coverarts/temp_intent.jpeg";
      File artFile = await File(tempArtPath).create(recursive: true);
      await artFile.writeAsBytes(artBytes, mode: FileMode.write);
      artUri = Uri.file(tempArtPath);
    }

    final fallbackTitle =
        prepared.displayName?.replaceFirst(RegExp(r'\.[^.]+$'), '').trim() ??
            "Intent Audio";
    final displayTitle =
        (metadata == null || metadata.title == "Unknown Title") &&
                fallbackTitle.isNotEmpty
            ? fallbackTitle
            : metadata?.title ?? fallbackTitle;

    final songItem = MediaItem(
      id: prepared.path,
      title: displayTitle,
      artist: metadata?.artist ?? "Unknown Artist",
      album: metadata?.album ?? "Unknown Album",
      artUri: artUri,
      duration: Duration(milliseconds: metadata?.duration ?? 0),
      extras: {
        "id": "no-id",
      },
    );

    await playOnlyThis(songItem);
  } catch (e) {
    debugPrint("Error playing from intent: $e");
  }
}
