/*

Name says it all

*/

//Flutter Packages
import 'dart:async';
import 'dart:io';

import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';

//On Audio Query
import 'package:on_audio_query/on_audio_query.dart';

//Audio Service
import 'package:audio_service/audio_service.dart';

//Hive
import 'package:hive_flutter/hive_flutter.dart';

//Antiiq Packages
import 'package:antiiq/player/utilities/audio_handler.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';

late AntiiqAudioHandler audioHandler;
PageController mainPageController = PageController();

//App Directory
late Directory antiiqDirectory;

//Cache
late Box antiiqStore;
late Box<List<int>> playlistStore;
late Box<String> playlistNameStore;

late bool dataIsInitialized;

//Page Indexes Object
var mainPageIndexes = {
  "dashboard": 0,
  "equalizer": 1,
  "search": 2,
  "songs": 3,
  "albums": 4,
  "artists": 5,
  "genres": 6,
  "playlists": 7,
  "favourites": 8,
  "selection": 9,
};

Velocity defaultTextScrollvelocity =
    const Velocity(pixelsPerSecond: Offset(50, 0));
Duration delayBeforeScroll = const Duration(seconds: 2);

List<MediaItem> queueToLoad = [];
List<MediaItem> activeQueue = [];

late Uri defaultArtUri;

MediaItem currentDefaultSong = MediaItem(
    id: "",
    title: "",
    album: "",
    artist: "",
    artUri: defaultArtUri,
    duration: const Duration(seconds: 100),
    extras: {"id": 1});

Stream<MediaItem?> currentPlaying() =>
    audioHandler.mediaItem.asBroadcastStream();
Stream<Duration> currentPosition() => AudioService.position.asBroadcastStream();

Stream<PlaybackState> currentPlaybackState() =>
    audioHandler.playbackState.asBroadcastStream();

Stream<List<MediaItem>> currentQueueStream() =>
    audioHandler.queue.asBroadcastStream().distinct();

final OnAudioQuery audioQuery = OnAudioQuery();
// Indicate if application has permission to the library.
bool hasPermissions = false;
bool furtherPermissionPermanentlyDenied = false;
bool furtherPermissionGranted = false;

//Variables to show library load progress
int libraryLoadTotal = 1;
int libraryLoadProgress = 0;
String loadingMessage = "Loading Library";

String placeholderAssetImage = "assets/placeholder.png";
String logoImage = "assets/AntiiQ.png";

RoundedRectangleBorder bottomSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(generalRadius),
    topRight: Radius.circular(generalRadius),
  ),
);

List<Track> globalSelection = [];
StreamController<List<Track>> globalSelectionStream =
    StreamController.broadcast();

List<Track> favourites = [];
StreamController<List<Track>> favouritesStream = StreamController.broadcast();

//User Settings Related Variables
List<MediaItem> queueState = [];

late bool interactiveMiniPlayerSeekbar;

StreamController<bool> interactiveSeekbarStream = StreamController.broadcast();

late bool showTrackDuration;

StreamController<bool> trackDurationDisplayStream = StreamController.broadcast();

late Timer runtimeAutoScanTimer;

late Duration runtimeAutoScanInterval;

late bool runtimeAutoScanEnabled;

late int minimumTrackLength;

List<String> specificPathsToQuery = [];

late String currentTheme;
StreamController<AntiiQColorScheme> themeStream = StreamController.broadcast();

late bool previousRestart;

late bool swipeGestures;
