import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/list_states/albums_state.dart';
import 'package:antiiq/player/state/list_states/artists_state.dart';
import 'package:antiiq/player/state/list_states/favourites_state.dart';
import 'package:antiiq/player/state/list_states/genres_state.dart';
import 'package:antiiq/player/state/list_states/history_state.dart';
import 'package:antiiq/player/state/list_states/playlists_state.dart';
import 'package:antiiq/player/state/list_states/queue_state.dart';
import 'package:antiiq/player/state/list_states/selection_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/state/music_init.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:audio_service/audio_service.dart';

class MusicState {
  final TracksState tracks = TracksState();
  final AlbumsState albums = AlbumsState();
  final ArtistsState artists = ArtistsState();
  final GenresState genres = GenresState();
  final PlaylistsState playlists = PlaylistsState();
  final QueueState queue = QueueState();
  final SelectionState selection = SelectionState();
  final HistoryState history = HistoryState();
  final FavouritesState favourites = FavouritesState();
  final MusicInit _musicInit = MusicInit();

  init(AntiiqState state) async {
    if (state.permissions.has) {
      await _musicInit.run(this);
      state.dataIsInitialized = true;
      await state.store.put("dataInit", true);
    }
  }
}

List<MediaItem> tracksToMediaItems(List<Track> tracks) {
  return tracks
      .where((trk) => trk.mediaItem != null)
      .map((track) => track.mediaItem!)
      .toList();
}
