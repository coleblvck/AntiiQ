//Audio Service
import 'dart:io';
import 'dart:typed_data';

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
    // Use AudioMetadataBridge for content URIs
    final AudioMetadata metadata =
        await AudioMetadataBridge.getMetadataFromContentUri(link);

    // Try to get artwork
    Uint8List? artBytes =
        await AudioMetadataBridge.extractArtworkFromContentUri(link,
            quality: 90);
    Uri artUri = defaultArtUri;

    if (artBytes != null) {
      // Save temp artwork
      final tempArtPath = "${antiiqDirectory.path}/coverarts/temp_intent.jpeg";
      File artFile = await File(tempArtPath).create(recursive: true);
      await artFile.writeAsBytes(artBytes, mode: FileMode.write);
      artUri = Uri.file(tempArtPath);
    }

    final songItem = MediaItem(
      id: link,
      title: metadata.title,
      artist: metadata.artist,
      album: metadata.album,
      artUri: artUri,
      duration: Duration(milliseconds: metadata.duration),
      extras: {
        "id": "no-id",
      },
    );

    playOnlyThis(songItem);
  } catch (e) {
    debugPrint("Error playing from intent: $e");
  }
}
