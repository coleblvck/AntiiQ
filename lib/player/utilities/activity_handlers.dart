//Audio Service
import 'package:audio_service/audio_service.dart';

//Antiiq Packages
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/files/lists.dart';
import 'package:antiiq/player/utilities/files/metadata.dart';

playTrack(int index, String list, {albumToPlay}) {
  if (list == "songs") {
    playFromSongs(index);
  }
  if (list == "queue") {
    playFromQueue(index);
  }

  if (list == "album") {
    playFromAlbum(index, albumToPlay);
  }
}

playFromSongs(int index) async {
  await goToAudioService(index, currentTrackListSort.map((e) => e.mediaItem!).toList());
  await audioHandler.play();
}

playFromQueue(int index) async {
  await goToAudioService(index, activeQueue);
  await audioHandler.play();
}

playFromAlbum(int index, List<MediaItem> album) async {
  await goToAudioService(index, album);
  await audioHandler.play();
}

Future<void> goToAudioService(
    int indexOfSong, List<MediaItem> listToPlay) async {
  queueToLoad =
      listToPlay.sublist(indexOfSong) + listToPlay.sublist(0, indexOfSong);
  currentDefaultSong = queueToLoad[0];
  if (queueToLoad[0].duration == const Duration(milliseconds: 0)) {
    queueToLoad.removeAt(0);
  }
  await loadQueue(queueToLoad);
}

Future<void> loadQueue(queue) async {
  await audioHandler.updateQueue(queue);
}

resume() async {
  audioHandler.play();
}

pause() {
  audioHandler.pause();
}

next() {
  audioHandler.skipToNext();
}

previous() {
  audioHandler.skipToPrevious();
}

forward() {
  audioHandler.fastForward();
}

rewind() {
  audioHandler.rewind();
}

playOnlyThis(MediaItem item) {
  queueToLoad = [item];
  loadQueue(queueToLoad);
  audioHandler.play();
}

playTrackNext(MediaItem item) {
  audioHandler.insertQueueItem(1, item);
}

addToQueue(item) {
  audioHandler.addQueueItem(item);
}

shuffleList(List<MediaItem> list) async {
  await audioHandler.audioPlayer.setShuffleModeEnabled(true);
  loadQueue(list);
  resume();
}

shuffleTracks(List<Track> list) {
  List<MediaItem> itemList = list.map((e) => e.mediaItem!).toList();
  shuffleList(itemList);
}