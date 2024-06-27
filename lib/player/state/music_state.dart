import 'package:antiiq/player/state/list_states/albums_state.dart';
import 'package:antiiq/player/state/list_states/artists_state.dart';
import 'package:antiiq/player/state/list_states/favourites_state.dart';
import 'package:antiiq/player/state/list_states/genres_state.dart';
import 'package:antiiq/player/state/list_states/queue_state.dart';
import 'package:antiiq/player/state/list_states/selection_state.dart';
import 'package:antiiq/player/state/list_states/tracks_state.dart';
import 'package:antiiq/player/state/music_init.dart';

class MusicState {
  final TracksState tracks = TracksState();
  final AlbumsState albums = AlbumsState();
  final ArtistsState artists = ArtistsState();
  final GenresState genres = GenresState();
  final QueueState queue = QueueState();
  final SelectionState selection = SelectionState();
  final FavouritesState favourites = FavouritesState();
  final MusicInit _musicInit = MusicInit();

  init() async {
    await _musicInit.run(this);
  }
}
