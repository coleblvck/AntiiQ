import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'dart:collection';

enum PlaylistType {
  shuffleAll,
  genre,
  artist,
  album,
  year,
  likedShuffle,
  similarToTrack,
  fromHistory,
  mood,
  tempo,
  freshDiscovery,
  recentlyAdded,
  decadesMix,
  acousticVibe,
}

class AntiiqPlaylistGenerator {
  final Random _random = Random();
  final Map<String, List<String>> _genreMappings = {
    'hip hop': ['hiphop', 'hip-hop', 'trap', 'rap', 'grime', 'drill'],
    'rock': ['alt rock', 'alternative rock', 'hard rock', 'indie rock', 'classic rock', 'prog rock', 'punk rock'],
    'electronic': ['edm', 'dance', 'house', 'techno', 'dubstep', 'drum and bass', 'drum & bass', 'trance', 'ambient', 'electronica'],
    'r&b': ['rnb', 'rhythm and blues', 'soul', 'neo soul', 'contemporary r&b'],
    'pop': ['pop rock', 'dance pop', 'synth pop', 'k-pop', 'j-pop', 'indie pop', 'dream pop'],
    'metal': ['heavy metal', 'death metal', 'black metal', 'thrash metal', 'doom metal', 'progressive metal', 'nu metal', 'metalcore'],
    'jazz': ['smooth jazz', 'bebop', 'fusion', 'swing', 'bossa nova', 'big band', 'contemporary jazz'],
    'classical': ['orchestra', 'chamber', 'piano', 'symphony', 'baroque', 'romantic', 'opera', 'contemporary classical'],
    'country': ['americana', 'folk', 'bluegrass', 'country rock', 'alternative country', 'country pop'],
    'reggae': ['dancehall', 'ska', 'dub', 'reggaeton', 'roots reggae'],
    'indie': ['indie rock', 'indie pop', 'indie folk', 'indie electronic', 'alternative'],
    'folk': ['folk rock', 'traditional folk', 'contemporary folk', 'singer-songwriter'],
    'blues': ['chicago blues', 'delta blues', 'electric blues', 'blues rock'],
    'funk': ['disco', 'soul', 'r&b', 'jazz-funk'],
    'punk': ['hardcore', 'post-punk', 'pop punk', 'punk rock', 'emo'],
    'world': ['latin', 'afrobeat', 'celtic', 'flamenco', 'middle eastern', 'asian', 'indian'],
    'acoustic': ['folk', 'singer-songwriter', 'unplugged', 'acoustic rock', 'acoustic pop'],
    'instrumental': ['post-rock', 'ambient', 'soundtrack', 'classical', 'lo-fi'],
  };

  final Map<String, double> _trackWeights = {};
  final Map<String, double> _similarityCache = {};
  final int _maxHistoryInfluence = 50;

  final Map<String, double> _similarityWeights = {
    'artist': 0.4,
    'album': 0.3,
    'genre': 0.3,
    'year': 0.1,
    'bpm': 0.1,
  };

  AntiiqPlaylistGenerator();

  Future<void> loadQueue(List<MediaItem> queue) async {
    if (kDebugMode) {
      print('Loading queue with ${queue.length} tracks');
    }
    await audioHandler.updateQueue(queue);
  }

  void clearCache() {
    _similarityCache.clear();
    _trackWeights.clear();
  }

  Future<List<MediaItem>?> generatePlaylist({
    required PlaylistType type,
    String? filterValue,
    Track? seedTrack,
    List<Track>? playHistory,
    bool shuffleAlbum = true,
    bool autoPlay = true,
    int maxTracks = 100,
    double similarityThreshold = 0.5,
    Map<String, double>? customWeights,
  }) async {
    try {
      List<Track> filteredTracks = [];
      final allTracks = antiiqState.music.tracks.list;

      if (allTracks.isEmpty) {
        if (kDebugMode) {
          print('No tracks available in antiiqState');
        }
        return null;
      }

      final weights = customWeights ?? _similarityWeights;

      _updateTrackWeights(playHistory);

      switch (type) {
        case PlaylistType.shuffleAll:
          filteredTracks = allTracks.where((t) => t.mediaItem != null).toList();
          break;

        case PlaylistType.genre:
          if (filterValue == null || filterValue.isEmpty) return null;

          final normalizedGenre = _normalizeText(filterValue);
          final genreMatches = _findMatchingGenre(normalizedGenre);

          filteredTracks = allTracks
              .where((track) =>
                  track.mediaItem != null &&
                  _isGenreMatch(track, genreMatches))
              .toList();
          break;

        case PlaylistType.artist:
          if (filterValue == null || filterValue.isEmpty) return null;

          final normalizedArtist = _normalizeText(filterValue);
          filteredTracks = allTracks
              .where((track) =>
                track.mediaItem != null &&
                track.trackData?.trackArtistNames != null &&
                (_calculateSimilarity(
                    _normalizeText(track.trackData!.trackArtistNames!),
                    normalizedArtist) > 0.7 ||
                   _normalizeText(track.trackData!.trackArtistNames!).contains(normalizedArtist) ||
                   normalizedArtist.contains(_normalizeText(track.trackData!.trackArtistNames!))))
              .toList();
          break;

        case PlaylistType.album:
          if (filterValue == null || filterValue.isEmpty) return null;

          final normalizedAlbum = _normalizeText(filterValue);
          filteredTracks = allTracks
              .where((track) =>
                track.mediaItem != null &&
                track.trackData?.albumName != null &&
                (_calculateSimilarity(
                  _normalizeText(track.trackData!.albumName!),
                  normalizedAlbum) > 0.8 ||
                _normalizeText(track.trackData!.albumName!).contains(normalizedAlbum) ||
                normalizedAlbum.contains(_normalizeText(track.trackData!.albumName!))))
              .toList();

          if (filteredTracks.isNotEmpty) {
            if (!shuffleAlbum) {
              filteredTracks.sort((a, b) {
                final discNumA = a.trackData?.discNumber ?? 1;
                final discNumB = b.trackData?.discNumber ?? 1;

                if (discNumA != discNumB) {
                  return discNumA.compareTo(discNumB);
                }

                final trackNumA = a.trackData?.trackNumber ?? 0;
                final trackNumB = b.trackData?.trackNumber ?? 0;

                return trackNumA.compareTo(trackNumB);
              });
            }
          }
          break;

        case PlaylistType.year:
          if (filterValue == null || filterValue.isEmpty) return null;

          final yearValue = filterValue.trim();
          final isRange = yearValue.contains('-');

          if (isRange) {
            final range = yearValue.split('-');
            if (range.length == 2) {
              final startYear = int.tryParse(range[0].trim());
              final endYear = int.tryParse(range[1].trim());

              if (startYear != null && endYear != null) {
                filteredTracks = allTracks
                    .where((track) {
                      final year = track.trackData?.year;
                      return track.mediaItem != null && year != null && year >= startYear && year <= endYear;
                    })
                    .toList();
              }
            }
          } else {
            final int? year = int.tryParse(yearValue);
            final decade = yearValue.endsWith('s')
                ? int.tryParse(yearValue.substring(0, yearValue.length - 1))
                : null;

            filteredTracks = allTracks.where((track) {
              if (track.mediaItem == null) return false;

              final trackYear = track.trackData?.year;
              if (trackYear == null) return false;

              if (year != null) {
                return trackYear == year;
              } else if (decade != null) {
                return trackYear >= decade && trackYear < decade + 10;
              }

              return trackYear.toString().toLowerCase() == yearValue.toLowerCase();
            }).toList();
          }
          break;

        case PlaylistType.likedShuffle:
          filteredTracks = antiiqState.music.favourites.list.where((t) => t.mediaItem != null).toList();
          break;

        case PlaylistType.similarToTrack:
          if (seedTrack == null || seedTrack.mediaItem == null) return null;

          final scoredTracks = _findSimilarTracks(
            seedTrack: seedTrack,
            allTracks: allTracks,
            weights: weights,
            similarityThreshold: similarityThreshold
          );

          scoredTracks.sort((a, b) => b.value.compareTo(a.value));

          final List<Track> selectedTracks = [];

          final mostSimilar = scoredTracks.take(20).map((e) => e.key).toList();
          selectedTracks.addAll(mostSimilar);

          if (scoredTracks.length > 20) {
            final remaining = scoredTracks.skip(20).map((e) => e.key).toList();
            final weightedRemainingMediaItems = _applyWeightedShuffle(
                remaining.where((t) => t.mediaItem != null).map((t) => t.mediaItem!).toList(),
                maxTracks - selectedTracks.length
            );
            final weightedRemainingTracks = allTracks.where((track) =>
                weightedRemainingMediaItems.any((mi) => mi.id == track.mediaItem?.id)
            ).toList();
            selectedTracks.addAll(weightedRemainingTracks);
          }

          filteredTracks = selectedTracks;
          break;

        case PlaylistType.fromHistory:
          if (playHistory == null || playHistory.isEmpty) return null;

          final recentHistory = playHistory.length > 50 ? playHistory.sublist(0, 50) : playHistory;

          final historyFeatures = _extractFeaturesFromHistory(recentHistory);

          final scoredTracks = _scoreTracksAgainstHistory(
            allTracks: allTracks,
            historyFeatures: historyFeatures,
            weights: weights,
            playHistory: recentHistory
          );

          scoredTracks.sort((a, b) => b.value.compareTo(a.value));

          filteredTracks = _ensureDiversity(
            scoredTracks.map((e) => e.key).toList(),
            maxTracks: maxTracks
          );
          break;

        case PlaylistType.mood:
          if (filterValue == null || filterValue.isEmpty) return null;

          final mood = filterValue.toLowerCase().trim();
          final Map<String, List<String>> moodGenres = {
            'happy': ['pop', 'dance', 'disco', 'reggae', 'ska', 'j-pop', 'k-pop', 'power pop'],
            'sad': ['blues', 'soul', 'ambient', 'slowcore', 'folk', 'indie folk', 'emo', 'dream pop'],
            'energetic': ['rock', 'punk', 'metal', 'edm', 'techno', 'drum and bass', 'power metal', 'hardcore'],
            'chill': ['lofi', 'chillout', 'ambient', 'trip hop', 'downtempo', 'smooth jazz', 'acoustic'],
            'romantic': ['r&b', 'soul', 'jazz', 'soft rock', 'love songs', 'bossa nova', 'adult contemporary'],
            'angry': ['metal', 'hardcore', 'punk', 'industrial', 'grindcore', 'death metal', 'thrash metal'],
            'focus': ['classical', 'ambient', 'instrumental', 'post-rock', 'minimal', 'piano', 'soundtrack'],
            'nostalgic': ['oldies', '80s', '90s', 'classic rock', 'disco', 'synthwave', 'retro'],
            'epic': ['orchestral', 'soundtrack', 'trailer music', 'epic metal', 'power metal', 'symphonic'],
          };

          List<String> targetGenres = moodGenres[mood] ?? [];
          if (targetGenres.isEmpty) return null;

          final scoredTracks = _getMoodBasedTracks(
            allTracks: allTracks,
            targetGenres: targetGenres,
            mood: mood
          );

          scoredTracks.sort((a, b) => b.value.compareTo(a.value));
          filteredTracks = scoredTracks.take(maxTracks).map((e) => e.key).toList();
          break;

        case PlaylistType.tempo:
          if (filterValue == null || filterValue.isEmpty) return null;

          final tempo = filterValue.toLowerCase().trim();
          final Map<String, List<String>> tempoGenres = {
            'fast': ['punk', 'metal', 'drum and bass', 'techno', 'hardcore', 'thrash metal', 'speed metal'],
            'medium': ['rock', 'pop', 'hip hop', 'reggae', 'disco', 'funk', 'alternative'],
            'slow': ['ambient', 'blues', 'jazz', 'folk', 'classical', 'downtempo', 'trip-hop', 'chillout']
          };

          Map<String, List<int>> bpmRanges = {
            'fast': [120, 200],
            'medium': [80, 120],
            'slow': [40, 80],
          };

          List<String> targetGenres = tempoGenres[tempo] ?? [];
          List<int>? bpmRange = bpmRanges[tempo];

          final scoredTracks = _getTempoBasedTracks(
            allTracks: allTracks,
            targetGenres: targetGenres,
            bpmRange: bpmRange,
            tempo: tempo
          );

          scoredTracks.sort((a, b) => b.value.compareTo(a.value));
          filteredTracks = scoredTracks.take(maxTracks).map((e) => e.key).toList();
          break;

        case PlaylistType.freshDiscovery:
          filteredTracks = _getDiscoveryTracks(allTracks, playHistory);
          break;

        case PlaylistType.recentlyAdded:
          final scoredTracks = allTracks
              .where((t) => t.mediaItem != null)
              .map((track) {
                final random = Random();
                final score = random.nextDouble();
                return MapEntry(track, score);
              })
              .toList();

          scoredTracks.sort((a, b) => b.value.compareTo(a.value));
          filteredTracks = scoredTracks.take(maxTracks).map((e) => e.key).toList();
          break;

        case PlaylistType.decadesMix:
          filteredTracks = _getDecadesMixTracks(allTracks, maxTracks);
          break;

        case PlaylistType.acousticVibe:
          final acousticGenres = ['acoustic', 'folk', 'singer-songwriter', 'unplugged', 'classical'];

          final scoredTracks = allTracks
              .where((t) => t.mediaItem != null)
              .map((track) {
                double score = 0.0;
                final trackGenre = track.trackData?.genre;

                if (trackGenre != null) {
                  final normalizedGenre = _normalizeText(trackGenre);

                  for (final genre in acousticGenres) {
                    if (_calculateSimilarity(normalizedGenre, genre) > 0.7) {
                      score = 1.0;
                      break;
                    }

                    final relatedGenres = _findMatchingGenre(genre);
                    if (_isGenreInList(normalizedGenre, relatedGenres)) {
                      score = max(score, 0.8);
                      break;
                    }
                  }

                  if (score < 0.8 && track.mediaItem?.title != null) {
                    final title = _normalizeText(track.mediaItem!.title);
                    if (title.contains('acoustic') ||
                        title.contains('unplugged') ||
                        title.contains('live') ||
                        title.contains('session')) {
                      score = max(score, 0.9);
                    }
                  }
                }

                if (track.trackData?.bpm != null) {
                  final bpm = track.trackData!.bpm!;
                  if (bpm < 120) {
                    score = max(score, 0.5);
                  }
                }


                return score > 0 ? MapEntry(track, score) : null;
              })
              .nonNulls
              .toList();

          scoredTracks.sort((a, b) => b.value.compareTo(a.value));
          filteredTracks = scoredTracks.take(maxTracks).map((e) => e.key).toList();
          break;
      }

      if (filteredTracks.isEmpty) {
        if (kDebugMode) {
          print('No tracks match the filter criteria for type: $type');
        }
        return null;
      }

      List<MediaItem> finalQueue = filteredTracks.where((t) => t.mediaItem != null).map((t) => t.mediaItem!).toList();

      if (type != PlaylistType.album || shuffleAlbum) {
         finalQueue = _applyWeightedShuffle(finalQueue, maxTracks);
      } else if (finalQueue.length > maxTracks) {
         finalQueue = finalQueue.take(maxTracks).toList();
      }


      if (kDebugMode) {
        print('Successfully created playlist with ${finalQueue.length} tracks');
        print(
            'First few tracks: ${finalQueue.take(3).map((t) => t.title).join(', ')}');
      }

      await loadQueue(finalQueue);

      if (autoPlay) {
        await audioHandler.play();
      }

      return finalQueue;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error generating playlist: $e');
        print(stackTrace);
      }
      return null;
    }
  }

  bool _isGenreMatch(Track track, List<String> genreMatches) {
    if (track.trackData?.genre == null) return false;

    final trackGenre = track.trackData!.genre!.toLowerCase();
    return _isGenreInList(trackGenre, genreMatches);
  }

  bool _isGenreInList(String genre, List<String> genreList) {
    if (genreList.contains(genre)) return true;

    for (final matchGenre in genreList) {
      if (_calculateSimilarity(genre, matchGenre) > 0.7) {
        return true;
      }
    }

    return false;
  }

  List<String> _findMatchingGenre(String input) {
    final normalizedInput = input.toLowerCase().trim();
    Set<String> matches = {normalizedInput};

    _genreMappings.forEach((mainGenre, relatedGenres) {
      if (mainGenre == normalizedInput) {
        matches.addAll(relatedGenres);
      } else if (relatedGenres.contains(normalizedInput)) {
        matches.add(mainGenre);
        matches.addAll(relatedGenres);
      } else {
        for (final related in relatedGenres) {
           if (_calculateSimilarity(normalizedInput, related) > 0.8) {
             matches.add(mainGenre);
             matches.add(related);
             matches.addAll(relatedGenres);
             break;
           }
        }
      }
    });

    for (String mainGenre in _genreMappings.keys) {
       if (_calculateSimilarity(normalizedInput, mainGenre) > 0.8) {
         matches.add(mainGenre);
         matches.addAll(_genreMappings[mainGenre] ?? []);
       }
    }


    return matches.toList();
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a.contains(b) || b.contains(a)) return 0.9;

    final cacheKey = '${a}_$b';
    if (_similarityCache.containsKey(cacheKey)) {
      return _similarityCache[cacheKey]!;
    }

    final distance = _levenshteinDistance(a, b);
    final maxLength = max(a.length, b.length);

    if (maxLength == 0) return 0.0;

    final similarity = 1.0 - (distance / maxLength);
    _similarityCache[cacheKey] = similarity;
    return similarity;
  }

  int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previous = List<int>.generate(b.length + 1, (i) => i);
    List<int> current = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      current[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        int cost = (a[i] == b[j]) ? 0 : 1;
        current[j + 1] = min(
          min(current[j] + 1, previous[j + 1] + 1),
          previous[j] + cost
        );
      }

      List<int> temp = previous;
      previous = current;
      current = temp;
    }

    return previous[b.length];
  }

  void _updateTrackWeights(List<Track>? history) {
    _trackWeights.clear();

    if (history == null || history.isEmpty) return;

    for (int i = 0; i < history.length; i++) {
      final track = history[i];
      if (track.mediaItem == null) continue;

      final position = history.length - i;
      final weight = position / history.length;

      _trackWeights[track.mediaItem!.id] = weight;

      final artist = track.trackData?.trackArtistNames;
      if (artist != null) {
        final allTracks = antiiqState.music.tracks.list;
        final artistTracks = allTracks
            .where((t) =>
              t.mediaItem != null &&
              t.trackData?.trackArtistNames != null &&
              t.trackData!.trackArtistNames!.toLowerCase() == artist.toLowerCase() &&
              t.mediaItem!.id != track.mediaItem!.id)
            .map((t) => t.mediaItem!);

        for (final otherTrackMediaItem in artistTracks) {
          final existingWeight = _trackWeights[otherTrackMediaItem.id] ?? 0.0;
          _trackWeights[otherTrackMediaItem.id] = existingWeight + (weight * 0.5);
        }
      }
    }

    if (_trackWeights.isNotEmpty) {
      final maxWeight = _trackWeights.values.reduce(max);
      if (maxWeight > 0) {
        _trackWeights.forEach((key, value) {
          _trackWeights[key] = value / maxWeight;
        });
      }
    }
  }

  List<MediaItem> _applyWeightedShuffle(List<MediaItem> tracks, int maxCount) {
    if (tracks.isEmpty) return [];
    if (maxCount <= 0 || tracks.length <= maxCount) {
      tracks.shuffle(_random);
      return tracks;
    }

    final List<MediaItem> weightedItems = [];
    final List<MediaItem> sourceItems = List.from(tracks);

    for (final track in sourceItems) {
      if (_trackWeights.containsKey(track.id)) {
        final weight = _trackWeights[track.id]!;
        final copies = (weight * _maxHistoryInfluence).round();
        for (int i = 0; i < copies; i++) {
          weightedItems.add(track);
        }
      }
    }

    final combined = [...weightedItems, ...sourceItems];
    combined.shuffle(_random);

    final result = <MediaItem>[];
    final seen = <String>{};

    for (final item in combined) {
      if (!seen.contains(item.id)) {
        result.add(item);
        seen.add(item.id);

        if (result.length >= maxCount) break;
      }
    }

    if (result.length < maxCount) {
        final remainingOriginal = sourceItems.where((item) => !seen.contains(item.id)).toList();
        remainingOriginal.shuffle(_random);
        final needed = maxCount - result.length;
        result.addAll(remainingOriginal.take(needed));
    }


    return result;
  }

  String _normalizeText(String text) {
    return text.toLowerCase().trim();
  }

  List<MapEntry<Track, double>> _findSimilarTracks({
    required Track seedTrack,
    required List<Track> allTracks,
    required Map<String, double> weights,
    required double similarityThreshold,
  }) {
    final seedGenre = seedTrack.trackData?.genre;
    final seedArtist = seedTrack.trackData?.trackArtistNames?.toLowerCase();
    final seedAlbum = seedTrack.trackData?.albumName?.toLowerCase();
    final seedYear = seedTrack.trackData?.year;
    final seedBpm = seedTrack.trackData?.bpm;


    final scoredTracks = allTracks
        .where((t) => t.mediaItem != null && t.mediaItem!.id != seedTrack.mediaItem!.id)
        .map((track) {
          double score = 0.0;

          final trackArtist = track.trackData?.trackArtistNames?.toLowerCase();
          if (seedArtist != null && trackArtist != null) {
            score += _calculateSimilarity(trackArtist, seedArtist) * (weights['artist'] ?? 0.0);
          }

          final trackAlbum = track.trackData?.albumName?.toLowerCase();
          if (seedAlbum != null && trackAlbum != null) {
            score += _calculateSimilarity(trackAlbum, seedAlbum) * (weights['album'] ?? 0.0);
          }

          final trackGenre = track.trackData?.genre;
          if (seedGenre != null && trackGenre != null) {
            final genreMatches = _findMatchingGenre(seedGenre.toLowerCase());
            if (_isGenreInList(trackGenre.toLowerCase(), genreMatches)) {
               score += (weights['genre'] ?? 0.0);
            } else {
              score += _calculateSimilarity(trackGenre.toLowerCase(), seedGenre.toLowerCase()) * (weights['genre'] ?? 0.0) * 0.5;
            }
          }

          final trackYear = track.trackData?.year;
          if (seedYear != null && trackYear != null) {
            final yearDiff = (trackYear - seedYear).abs();
            score += max(0.0, 1.0 - (yearDiff / 10.0)) * (weights['year'] ?? 0.0);
          }

          final trackBpm = track.trackData?.bpm;
          if (seedBpm != null && trackBpm != null) {
             final bpmDiff = (trackBpm - seedBpm).abs();
             score += max(0.0, 1.0 - (bpmDiff / 50.0)) * (weights['bpm'] ?? 0.0);
          }


          return score >= similarityThreshold ? MapEntry(track, score) : null;
        })
        .nonNulls
        .toList();

    return scoredTracks;
  }

  Map<String, dynamic> _extractFeaturesFromHistory(List<Track> history) {
    final historyGenres = <String, int>{};
    final historyArtists = <String, int>{};
    final historyYears = <int, int>{};
    final historyBpms = <int>[];

    for (final track in history) {
      final genre = track.trackData?.genre;
      if (genre != null) {
        historyGenres[genre.toLowerCase()] = (historyGenres[genre.toLowerCase()] ?? 0) + 1;
      }

      final artist = track.trackData?.trackArtistNames;
      if (artist != null) {
        historyArtists[artist.toLowerCase()] = (historyArtists[artist.toLowerCase()] ?? 0) + 1;
      }

      final year = track.trackData?.year;
      if (year is int) {
        historyYears[year] = (historyYears[year] ?? 0) + 1;
      }

      final bpm = track.trackData?.bpm;
      if (bpm != null) {
        historyBpms.add(bpm);
      }
    }

    return {
      'genres': historyGenres,
      'artists': historyArtists,
      'years': historyYears,
      'bpms': historyBpms,
    };
  }

  List<MapEntry<Track, double>> _scoreTracksAgainstHistory({
    required List<Track> allTracks,
    required Map<String, dynamic> historyFeatures,
    required Map<String, double> weights,
    required List<Track> playHistory,
  }) {
    final historyGenres = historyFeatures['genres'] as Map<String, int>;
    final historyArtists = historyFeatures['artists'] as Map<String, int>;
    final historyYears = historyFeatures['years'] as Map<int, int>;
    final historyBpms = historyFeatures['bpms'] as List<int>;

    final scoredTracks = allTracks
        .where((t) => t.mediaItem != null && !playHistory.any((h) => h.mediaItem?.id == t.mediaItem!.id))
        .map((track) {
          double score = 0.0;

          final trackGenre = track.trackData?.genre;
          if (trackGenre != null) {
            final cleanGenre = trackGenre.toLowerCase();
            final matchingGenres = _findMatchingGenre(cleanGenre);

            for (final entry in historyGenres.entries) {
              final historyGenre = entry.key;
              final count = entry.value;
              if (cleanGenre == historyGenre || _isGenreInList(historyGenre, matchingGenres)) {
                score += (weights['genre'] ?? 0.0) * (count / playHistory.length);
              }
            }
          }

          final trackArtist = track.trackData?.trackArtistNames?.toLowerCase();
          if (trackArtist != null) {
            for (final entry in historyArtists.entries) {
              final historyArtist = entry.key;
              final count = entry.value;
              if (trackArtist == historyArtist) {
                score += (weights['artist'] ?? 0.0) * (count / playHistory.length);
              } else {
                 score += _calculateSimilarity(trackArtist, historyArtist) * (weights['artist'] ?? 0.0) * 0.5 * (count / playHistory.length);
              }
            }
          }

          final trackYear = track.trackData?.year;
          if (trackYear is int) {
            for (final entry in historyYears.entries) {
              final historyYear = entry.key;
              final count = entry.value;

              final yearDiff = (trackYear - historyYear).abs();
              score += max(0.0, 1.0 - (yearDiff / 10.0)) * (weights['year'] ?? 0.0) * (count / playHistory.length);
            }
          }

          final trackBpm = track.trackData?.bpm;
          if (trackBpm != null && historyBpms.isNotEmpty) {
              final avgHistoryBpm = historyBpms.reduce((a, b) => a + b) / historyBpms.length;
              final bpmDiff = (trackBpm - avgHistoryBpm).abs();
              score += max(0.0, 1.0 - (bpmDiff / 50.0)) * (weights['bpm'] ?? 0.0);
          }


          final trackId = track.mediaItem!.id;
          if (_trackWeights.containsKey(trackId)) {
            score *= (1 + _trackWeights[trackId]! * 0.5);
          }

          return score > 0 ? MapEntry(track, score) : null;
        })
        .nonNulls
        .toList();

    return scoredTracks;
  }


  List<MapEntry<Track, double>> _getMoodBasedTracks({
    required List<Track> allTracks,
    required List<String> targetGenres,
    required String mood,
  }) {
    final Map<String, Map<String, dynamic>> moodFeatures = {
      'happy': {'bpmRange': [90, 140], 'titleKeywords': ['happy', 'joy', 'fun', 'smile', 'good', 'upbeat']},
      'sad': {'bpmRange': [60, 90], 'titleKeywords': ['sad', 'cry', 'tears', 'blue', 'alone', 'lost', 'melancholy']},
      'energetic': {'bpmRange': [120, 180], 'titleKeywords': ['energy', 'power', 'jump', 'run', 'fire', 'fast', 'workout']},
      'chill': {'bpmRange': [60, 100], 'titleKeywords': ['chill', 'relax', 'calm', 'peace', 'dream', 'ambient', 'lounge']},
      'romantic': {'bpmRange': [70, 110], 'titleKeywords': ['love', 'heart', 'romance', 'kiss', 'touch', 'sweet', 'together']},
      'angry': {'bpmRange': [110, 160], 'titleKeywords': ['anger', 'rage', 'fight', 'hate', 'fury', 'aggression', 'metal']},
      'focus': {'bpmRange': [70, 110], 'titleKeywords': ['focus', 'study', 'work', 'instrumental', 'minimal', 'ambient']},
      'nostalgic': {'bpmRange': [80, 130], 'titleKeywords': ['oldies', 'retro', 'classic', 'vintage', 'memory']},
      'epic': {'bpmRange': [100, 150], 'titleKeywords': ['epic', 'heroic', 'grand', 'orchestral', 'soundtrack', 'trailer']},
    };

    final moodFeature = moodFeatures[mood];
    final List<int>? bpmRange = moodFeature?['bpmRange'];
    final List<String>? titleKeywords = moodFeature?['titleKeywords'];


    return allTracks
        .where((t) => t.mediaItem != null)
        .map((track) {
          double score = 0.0;
          final trackGenre = track.trackData?.genre;
          final trackBpm = track.trackData?.bpm;
          final trackTitle = track.mediaItem?.title;

          if (trackGenre != null) {
            final normalizedGenre = _normalizeText(trackGenre);
            for (final genre in targetGenres) {
              if (_calculateSimilarity(normalizedGenre, genre) > 0.7) {
                score = max(score, 1.0);
                break;
              }
              final relatedGenres = _findMatchingGenre(genre);
              if (_isGenreInList(normalizedGenre, relatedGenres)) {
                score = max(score, 0.8);
                break;
              }
            }
          }

          if (trackBpm != null && bpmRange != null) {
             if (trackBpm >= bpmRange[0] && trackBpm <= bpmRange[1]) {
               score = max(score, 0.9);
             } else {
               final distanceFromRange = min(
                 (trackBpm - bpmRange[1]).abs(),
                 (trackBpm - bpmRange[0]).abs()
               );
               score = max(score, 0.7 * max(0.0, 1.0 - (distanceFromRange / 50.0)));
             }
          }

          if (trackTitle != null && titleKeywords != null) {
            final normalizedTitle = _normalizeText(trackTitle);
            for (final keyword in titleKeywords) {
              if (normalizedTitle.contains(keyword)) {
                score = max(score, 0.8);
                break;
              }
            }
          }


          return score > 0 ? MapEntry(track, score) : null;
        })
        .nonNulls
        .toList();
  }


  List<MapEntry<Track, double>> _getTempoBasedTracks({
    required List<Track> allTracks,
    required List<String> targetGenres,
    List<int>? bpmRange,
    required String tempo,
  }) {
    return allTracks
        .where((t) => t.mediaItem != null)
        .map((track) {
          double score = 0.0;
          final int? trackBpm = track.trackData?.bpm;

          if (trackBpm != null && bpmRange != null) {
            if (trackBpm >= bpmRange[0] && trackBpm <= bpmRange[1]) {
              score = max(score, 1.0);
            } else {
              final distanceFromRange = min(
                (trackBpm - bpmRange[1]).abs(),
                (trackBpm - bpmRange[0]).abs()
              );
              score = max(score, 0.8 * max(0.0, 1.0 - (distanceFromRange / 50.0)));
            }
          }

          if (score < 0.8 && targetGenres.isNotEmpty) {
            final trackGenre = track.trackData?.genre;
            if (trackGenre != null) {
              final normalizedGenre = _normalizeText(trackGenre);
              for (final genre in targetGenres) {
                if (_calculateSimilarity(normalizedGenre, genre) > 0.7) {
                  score = max(score, 0.7);
                  break;
                }
                final relatedGenres = _findMatchingGenre(genre);
                if (_isGenreInList(normalizedGenre, relatedGenres)) {
                  score = max(score, 0.6);
                  break;
                }
              }
            }
          }

          if (track.mediaItem?.title != null) {
            final title = _normalizeText(track.mediaItem!.title);

            if (tempo == 'fast' &&
                (title.contains('fast') || title.contains('speed') || title.contains('rush') || title.contains('upbeat'))) {
              score = max(score, 0.8);
            } else if (tempo == 'slow' &&
                     (title.contains('slow') || title.contains('ballad') || title.contains('chill') || title.contains('lounge'))) {
              score = max(score, 0.8);
            }
          }

          return score > 0 ? MapEntry(track, score) : null;
        })
        .nonNulls
        .toList();
  }

  List<Track> _getDecadesMixTracks(List<Track> allTracks, int maxTracks) {
    final Map<int, List<Track>> tracksByDecade = {};

    for (final track in allTracks) {
      if (track.mediaItem != null && track.trackData?.year != null) {
        final decade = (track.trackData!.year! ~/ 10) * 10;
        tracksByDecade.putIfAbsent(decade, () => []);
        tracksByDecade[decade]!.add(track);
      }
    }

    final sortedDecades = tracksByDecade.keys.toList()..sort();

    final tracksPerDecade = max(1, maxTracks ~/ tracksByDecade.length);

    final result = <Track>[];
    for (final decade in sortedDecades) {
      if (tracksByDecade[decade]!.isEmpty) continue;

      tracksByDecade[decade]!.shuffle(_random);

      final decadeTracks = tracksByDecade[decade]!.take(tracksPerDecade).toList();
      result.addAll(decadeTracks);

      if (result.length >= maxTracks) break;
    }

    if (result.length < maxTracks) {
      final allDecadeTracks = tracksByDecade.values.expand((e) => e).toList()
        ..removeWhere((t) => result.contains(t));
      allDecadeTracks.shuffle(_random);

      final remaining = maxTracks - result.length;
      result.addAll(allDecadeTracks.take(remaining));
    }

    return result;
  }

  List<Track> _getDiscoveryTracks(List<Track> allTracks, List<Track>? playHistory) {
    final Map<String, int> playCount = {};

    if (playHistory != null && playHistory.isNotEmpty) {
      for (final track in playHistory) {
        if (track.mediaItem != null) {
          final id = track.mediaItem!.id;
          playCount[id] = (playCount[id] ?? 0) + 1;
        }
      }
    }

    final scoredTracks = allTracks
        .where((t) => t.mediaItem != null)
        .map((track) {
          final playedCount = playCount[track.mediaItem!.id] ?? 0;

          double score;
          if (playedCount == 0) {
            score = 1.0;
          } else {
            score = exp(-playedCount / 5);
          }

          return MapEntry(track, score);
        })
        .toList();

    scoredTracks.sort((a, b) => b.value.compareTo(a.value));

    return scoredTracks.map((e) => e.key).toList();
  }

  List<Track> _ensureDiversity(List<Track> candidateTracks, {required int maxTracks}) {
    if (candidateTracks.length <= maxTracks) return candidateTracks;

    final selectedTracks = <Track>[];
    final artistCounts = <String, int>{};
    final genreCounts = <String, int>{};

    final initialSelection = min(maxTracks ~/ 3, candidateTracks.length);
    selectedTracks.addAll(candidateTracks.take(initialSelection));

    for (final track in selectedTracks) {
      if (track.trackData?.trackArtistNames != null) {
        final artist = track.trackData!.trackArtistNames!.toLowerCase();
        artistCounts[artist] = (artistCounts[artist] ?? 0) + 1;
      }

      if (track.trackData?.genre != null) {
        final genre = track.trackData!.genre!.toLowerCase();
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }
    }

    final remainingCandidates = candidateTracks.skip(initialSelection).toList();
    remainingCandidates.shuffle(_random);

    for (final track in remainingCandidates) {
      if (selectedTracks.length >= maxTracks) break;

      final artist = track.trackData?.trackArtistNames?.toLowerCase();
      final genre = track.trackData?.genre?.toLowerCase();

      int artistCount = artist != null ? (artistCounts[artist] ?? 0) : 0;
      int genreCount = genre != null ? (genreCounts[genre] ?? 0) : 0;

      if (artistCount >= 3) continue;

      if (genreCount >= maxTracks ~/ 4) continue;

      selectedTracks.add(track);
      if (artist != null) {
        artistCounts[artist] = artistCount + 1;
      }
      if (genre != null) {
        genreCounts[genre] = genreCount + 1;
      }
    }

    if (selectedTracks.length < maxTracks) {
      final remainingPool = candidateTracks.where((t) => !selectedTracks.contains(t)).toList();
      remainingPool.shuffle(_random);
      selectedTracks.addAll(remainingPool.take(maxTracks - selectedTracks.length));
    }

    return selectedTracks;
  }


  List<String> getAvailableGenres() {
    final genres = <String>{};
    for (var track in antiiqState.music.tracks.list) {
      if (track.trackData?.genre != null &&
          track.trackData!.genre!.isNotEmpty) {
        genres.add(track.trackData!.genre!);
      }
    }
    return genres.toList()..sort();
  }

  List<String> getAvailableArtists() {
    final artists = <String>{};
    final allTracks = antiiqState.music.tracks.list;
    for (var track in allTracks) {
      if (track.trackData?.trackArtistNames != null && track.trackData!.trackArtistNames!.isNotEmpty) {
        artists.add(track.trackData!.trackArtistNames!);
      }
    }
    return artists.toList()..sort();
  }

  List<String> getAvailableAlbums() {
    final albums = <String>{};
    final allTracks = antiiqState.music.tracks.list;
    for (var track in allTracks) {
      if (track.trackData?.albumName != null && track.trackData!.albumName!.isNotEmpty) {
        albums.add(track.trackData!.albumName!);
      }
    }
    return albums.toList()..sort();
  }

  List<String> getAvailableYears() {
    final years = <String>{};
    final allTracks = antiiqState.music.tracks.list;
    for (var track in allTracks) {
      final year = track.trackData?.year;
      if (year != null) {
        years.add(year.toString());
      }
    }
    return years.toList()..sort();
  }

  List<String> getAvailableMoods() {
    return ['happy', 'sad', 'energetic', 'chill', 'romantic', 'angry', 'focus', 'nostalgic', 'epic'];
  }

  List<String> getAvailableTempos() {
    return ['fast', 'medium', 'slow'];
  }

  Map<String, List<String>> getGenreMappings() {
    return Map.from(_genreMappings);
  }

  void addGenreMapping(String mainGenre, List<String> relatedGenres) {
    _genreMappings[mainGenre.toLowerCase()] = relatedGenres.map((g) => g.toLowerCase()).toList();
  }

  List<MediaItem> tracksToMediaItems(List<Track> tracks) {
    return tracks.where((t) => t.mediaItem != null).map((t) => t.mediaItem!).toList();
  }
}
