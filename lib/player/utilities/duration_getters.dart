import 'package:antiiq/player/utilities/file_handling/metadata.dart';

String totalDuration(List<Track> tracks) {
  int totalMilliseconds = 0;
  for (Track track in tracks) {
    totalMilliseconds += track.trackData!.trackDuration!;
  }
  Duration totalDuration = Duration(milliseconds: totalMilliseconds);
  String totalTime =
      "${totalDuration.inHours.toString().padLeft(2, "0")}:${totalDuration.inMinutes.remainder(60).toString().padLeft(2, "0")}:${totalDuration.inSeconds.remainder(60).toString().padLeft(2, "0")}";

  return totalTime;
}
