import 'dart:async';

import 'package:flutter/services.dart';

class NativeEqBand {
  const NativeEqBand({
    required this.frequency,
    required this.gainDb,
    required this.q,
    this.type = 0,
    this.enabled = true,
  });

  final double frequency;
  final double gainDb;
  final double q;
  final int type;
  final bool enabled;

  Map<String, Object> toMap() => {
        'frequency': frequency,
        'gainDb': gainDb,
        'q': q,
        'type': type,
        'enabled': enabled,
      };
}

class NativeAudioPlayer {
  NativeAudioPlayer() {
    _eventSubscription = _events.receiveBroadcastStream().listen(
          _handleEvent,
          onError: (_) => _playingController.add(false),
        );
    _positionTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_playingController.value) {
        refreshPosition();
      }
    });
  }

  static const MethodChannel _channel =
      MethodChannel('com.coleblvck.antiiq/native_audio');
  static const EventChannel _events =
      EventChannel('com.coleblvck.antiiq/native_audio_events');

  final StreamController<void> _completedController =
      StreamController<void>.broadcast();
  final StreamController<String> _transitionController =
      StreamController<String>.broadcast();
  final _positionController = _ValueStreamController<Duration>(Duration.zero);
  final _durationController = _ValueStreamController<Duration>(Duration.zero);
  final _playingController = _ValueStreamController<bool>(false);
  final _speedController = _ValueStreamController<double>(1.0);
  final _pitchController = _ValueStreamController<double>(1.0);
  StreamSubscription<dynamic>? _eventSubscription;
  Timer? _positionTimer;
  bool _hasOpenTrack = false;

  Stream<void> get completedStream => _completedController.stream;
  Stream<String> get transitionStream => _transitionController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<double> get pitchStream => _pitchController.stream;

  Duration get position => _positionController.value;
  Duration get duration => _durationController.value;
  bool get playing => _playingController.value;
  double get speed => _speedController.value;
  double get pitch => _pitchController.value;

  Future<int> open(String path, String id) async {
    final result = await _channel.invokeMethod<int>('open', {
      'path': path,
      'id': id,
    });
    _hasOpenTrack = (result ?? -1) == 0;
    await refreshDuration();
    await refreshPosition();
    return result ?? -1;
  }

  Future<void> play() async {
    if (!_hasOpenTrack) return;
    await _channel.invokeMethod<void>('play');
    _playingController.add(true);
  }

  Future<void> pause() async {
    await _channel.invokeMethod<void>('pause');
    _playingController.add(false);
    await refreshPosition();
  }

  Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
    _playingController.add(false);
    _positionController.add(Duration.zero);
    _hasOpenTrack = false;
  }

  Future<void> seek(Duration position) async {
    if (!_hasOpenTrack) return;
    await _channel.invokeMethod<void>('seek', {
      'positionMs': position.inMilliseconds,
    });
    _positionController.add(position);
  }

  Future<void> setGaplessEnabled(bool enabled) async {
    await _channel
        .invokeMethod<void>('setGaplessEnabled', {'enabled': enabled});
  }

  Future<void> setCrossfadeEnabled(bool enabled) async {
    await _channel
        .invokeMethod<void>('setCrossfadeEnabled', {'enabled': enabled});
  }

  Future<void> setCrossfadeDuration(Duration duration) async {
    await _channel.invokeMethod<void>('setCrossfadeDuration', {
      'durationMs': duration.inMilliseconds,
    });
  }

  Future<void> setUpcomingQueue(List<({String id, String path})> tracks) async {
    await _channel.invokeMethod<void>('setUpcomingQueue', {
      'tracks': [
        for (final track in tracks) {'id': track.id, 'path': track.path},
      ],
    });
  }

  Future<void> setEffectsEnabled(bool enabled) async {
    await _channel
        .invokeMethod<void>('setEffectsEnabled', {'enabled': enabled});
    await _channel
        .invokeMethod<void>('setParametricEqEnabled', {'enabled': enabled});
  }

  Future<void> setParametricEqBands(List<NativeEqBand> bands) async {
    await _channel.invokeMethod<void>('setParametricEqBands', {
      'bands': bands.take(15).map((band) => band.toMap()).toList(),
    });
  }

  Future<void> setSpeed(double value) async {
    final speed = value.clamp(0.5, 1.5).toDouble();
    await _channel.invokeMethod<void>('setSpeed', {'speed': speed});
    _speedController.add(speed);
  }

  Future<void> setPitch(double value) async {
    final pitch = value.clamp(0.5, 2.0).toDouble();
    await _channel.invokeMethod<void>('setPitch', {'pitch': pitch});
    _pitchController.add(pitch);
  }

  Future<void> refreshPosition() async {
    if (!_hasOpenTrack) return;
    final value = await _channel.invokeMethod<int>('position') ?? 0;
    _positionController.add(Duration(milliseconds: value));
  }

  Future<void> refreshDuration() async {
    if (!_hasOpenTrack) return;
    final value = await _channel.invokeMethod<int>('duration') ?? 0;
    _durationController.add(Duration(milliseconds: value));
  }

  Future<void> dispose() async {
    _positionTimer?.cancel();
    await _eventSubscription?.cancel();
    await _completedController.close();
    await _transitionController.close();
    await _positionController.close();
    await _durationController.close();
    await _playingController.close();
    await _speedController.close();
    await _pitchController.close();
  }

  void _handleEvent(Object? event) {
    if (event is! Map) return;
    if (event['event'] == 'completed') {
      _playingController.add(false);
      _completedController.add(null);
    } else if (event['event'] == 'pausedByFocus') {
      _playingController.add(false);
    } else if (event['event'] == 'resumedByFocus') {
      _playingController.add(true);
    } else if (event['event'] == 'error' || event['event'] == 'nextFailed') {
      _playingController.add(false);
    } else if (event['event'] == 'transition') {
      final to = event['to'];
      if (to is String) {
        _transitionController.add(to);
      }
    }
  }
}

class _ValueStreamController<T> {
  _ValueStreamController(this.value);

  T value;
  final StreamController<T> _controller = StreamController<T>.broadcast();

  Stream<T> get stream async* {
    yield value;
    yield* _controller.stream;
  }

  void add(T newValue) {
    value = newValue;
    if (!_controller.isClosed) {
      _controller.add(newValue);
    }
  }

  Future<void> close() => _controller.close();
}
