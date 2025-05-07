import 'dart:async';
import 'dart:io';

import 'package:antiiq/player/global_variables.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class HomeWidgetManager {
  static const String appGroupId = 'group.com.yourapp.antiiq';
  static const String iOSWidgetName = 'AntiiqMusicWidget';
  static const String androidWidgetName = 'AntiiqMusicGlanceWidgetReceiver';

  static const String keyTitle = 'song_title';
  static const String keyArtist = 'song_artist';
  static const String keyAlbum = 'song_album';
  static const String keyArtwork = 'song_artwork';
  static const String keyIsPlaying = 'is_playing';
  static const String keyDuration = 'song_duration';
  static const String keyPosition = 'song_position';
  static const String keyBackgroundOpacity = 'background_opacity';
  static const String keyCoverArtBackground = 'cover_art_background';

  static StreamSubscription? _positionSubscription;
  static bool _updatingPosition = false;
  static DateTime _lastPositionUpdate = DateTime.now();

  static Future<void> initialize() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(appGroupId);
    }

    HomeWidget.widgetClicked.listen(handleWidgetClicked);

    HomeWidget.getWidgetData<String>('last_action').then((action) {
      if (action != null) {
        Uri uri = Uri.parse('antiiqwidget://$action');
        handleWidgetClicked(uri);
        HomeWidget.saveWidgetData<String>('last_action', null);
      }
    });

    final mediaItem = audioHandler.mediaItem.value;
    final state = audioHandler.playbackState.value;
    await updateWidgetInfo(
      mediaItem,
      state.playing,
      state.position,
      mediaItem?.duration ?? Duration.zero,
    );

    _setupBackgroundUpdates();
  }

  static Future<void> updateVisuals(int? backgroundOpacity, bool? coverArtBackground) async {
    if (backgroundOpacity != null) {
      await HomeWidget.saveWidgetData<int>(keyBackgroundOpacity, backgroundOpacity);
    }

    if (coverArtBackground != null) {
      await HomeWidget.saveWidgetData<bool>(keyCoverArtBackground, coverArtBackground);
    }

    await _updateWidgets();
  }

  static Future<void> updateWidgetInfo(
    MediaItem? mediaItem,
    bool isPlaying,
    Duration position,
    Duration duration,
  ) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        keyTitle,
        mediaItem?.title ?? 'Not Playing'
      );
      await HomeWidget.saveWidgetData<String>(
        keyArtist,
        mediaItem?.artist ?? ''
      );
      await HomeWidget.saveWidgetData<String>(
        keyAlbum,
        mediaItem?.album ?? ''
      );
      await HomeWidget.saveWidgetData<String>(
        keyArtwork,
        mediaItem?.artUri?.toString() ?? ''
      );
      await HomeWidget.saveWidgetData<bool>(keyIsPlaying, isPlaying);
      await HomeWidget.saveWidgetData<int>(keyDuration, duration.inMilliseconds);
      await HomeWidget.saveWidgetData<int>(keyPosition, position.inMilliseconds);

      await _updateWidgets();
    } catch (e) {
      debugPrint('Failed to update home widget: $e');
    }
  }

  static Future<void> updateWidgetPosition(
    Duration position,
    Duration duration,
  ) async {
    if (_updatingPosition) return;

    final now = DateTime.now();
    if (now.difference(_lastPositionUpdate).inMilliseconds < 200) return;

    _updatingPosition = true;
    _lastPositionUpdate = now;

    try {
      await HomeWidget.saveWidgetData<int>(keyPosition, position.abs().inMilliseconds);
      await HomeWidget.saveWidgetData<int>(keyDuration, duration.abs().inMilliseconds);
      await _updateWidgets();
    } catch (e) {
      debugPrint('Failed to update home widget position: $e');
    } finally {
      _updatingPosition = false;
    }
  }

  static Future<void> _updateWidgets() async {
    try {
      if (Platform.isIOS) {
        await HomeWidget.updateWidget(
          name: iOSWidgetName,
          iOSName: iOSWidgetName,
        );
      } else {
        await HomeWidget.updateWidget(
          androidName: androidWidgetName,
        );
      }
    } catch (e) {
      debugPrint('Failed to refresh widget: $e');
    }
  }

  static Future<void> handleWidgetClicked(Uri? uri) async {
    debugPrint("Widget clicked with URI: $uri");
    if (uri == null) return;

    final action = uri.host;
    debugPrint("Widget action: $action");

    switch (action) {
      case 'play_pause':
        if (audioHandler.playbackState.value.playing) {
          await audioHandler.pause();
        } else {
          await audioHandler.play();
        }
        break;
      case 'previous':
        await audioHandler.skipToPrevious();
        break;
      case 'next':
        await audioHandler.skipToNext();
        break;
      case 'open_app':
        break;
    }
  }

  static void _setupBackgroundUpdates() {
    audioHandler.playbackState.listen((state) {
      final mediaItem = audioHandler.mediaItem.value;
      updateWidgetInfo(
        mediaItem,
        state.playing,
        state.position,
        mediaItem?.duration ?? Duration.zero,
      );
    });

    audioHandler.mediaItem.listen((item) {
      if (item != null) {
         final state = audioHandler.playbackState.value;
         updateWidgetInfo(
           item,
           state.playing,
           state.position,
           item.duration ?? Duration.zero,
         );
      }
    });

    _positionSubscription?.cancel();

    _positionSubscription = AudioService.position.listen((position) {
      final mediaItem = audioHandler.mediaItem.value;
      if (mediaItem != null && audioHandler.playbackState.value.playing) {
        updateWidgetPosition(
          position,
          mediaItem.duration ?? Duration.zero,
        );
      }
    });
  }

  static void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
