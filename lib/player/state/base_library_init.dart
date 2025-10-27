import 'package:antiiq/player/state/base_library_fetch.dart';
import 'package:antiiq/player/state/music_state.dart';
import 'package:antiiq/player/utilities/file_handling/library_fetcher.dart';

class BaseLibraryInit {
  run(MusicState music) async {
    await _fetch.run(music);
  }

  final BaseLibraryFetch _fetch = BaseLibraryFetch();
  //final AntiiQLibraryFetcher _fetch = AntiiQLibraryFetcher();
}
