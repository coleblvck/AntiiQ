//Audio Service
import 'dart:io';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/audio_preferences.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audiotags/audiotags.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart';
import 'package:uri_to_file/uri_to_file.dart';


playFromList(int index, List<MediaItem> listToPlay) async {
  await handleList(index, listToPlay);
  await audioHandler.play();
}

Future<void> handleList(
    int indexOfSong, List<MediaItem> listToPlay) async {
  queueToLoad =
      listToPlay.sublist(indexOfSong) + listToPlay.sublist(0, indexOfSong);
  currentDefaultSong = queueToLoad[0];
  if (queueToLoad[0].duration == const Duration(milliseconds: 0)) {
    queueToLoad.removeAt(0);
  }
  await loadQueue(queueToLoad);
}

Future<void> loadQueue(List<MediaItem> queue) async {
  await audioHandler.updateQueue(queue);
}

resume() async {
  await audioHandler.play();
}

pause() async {
  await audioHandler.pause();
}

next() async {
  await audioHandler.skipToNext();
}

previous() async {
  await audioHandler.skipToPrevious();
}

forward() async {
  await audioHandler.fastForward();
}

rewind() async {
  await audioHandler.rewind();
}

playOnlyThis(MediaItem item) async {
  queueToLoad = [item];
  await loadQueue(queueToLoad);
  await audioHandler.play();
}

playTracks(List<Track> tracks) async {
  queueToLoad = tracks.map((track) => track.mediaItem!).toList();
  await loadQueue(queueToLoad);
  await audioHandler.play();
}

playTrackNext(MediaItem item) async {
  if (audioHandler.antiiqQueue.isNotEmpty) {
    await audioHandler.insertQueueItem(1, item);
  } else {
    await playOnlyThis(item);
  }
}

addToQueue(item) async {
  if (audioHandler.antiiqQueue.isNotEmpty) {
    await audioHandler.addQueueItem(item);
  } else {
    await playOnlyThis(item);
  }
}

shuffleList(List<MediaItem> list) async {
  await updateShuffleMode(true);
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
