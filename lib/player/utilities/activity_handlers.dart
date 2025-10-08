//Audio Service
import 'dart:io';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';
import 'package:uri_to_file/uri_to_file.dart';

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
  File? file;
  AudioPlayer thisAudioLoader = AudioPlayer(
    handleInterruptions: false,
    androidApplyAudioAttributes: false,
    handleAudioSessionActivation: false,
  );
  try {
    file = await toFile(link);
    Tag? tag = await AudioTags.read(file.path);
    final songItem = MediaItem(
        id: link,
        title: tag?.title ?? basename(file.path),
        artist: tag?.trackArtist ?? "Unknown Artist",
        album: tag?.album ?? "Unknown Album",
        artUri: defaultArtUri,
        duration: tag?.duration != null
            ? Duration(seconds: tag!.duration!)
            : await thisAudioLoader.setUrl(link),
        extras: {
          "id": "no-id",
        });
    playOnlyThis(songItem);
  } catch (e) {
    null;
  }
  if (file != null) {
    file.delete();
  }
  thisAudioLoader.dispose();
}
