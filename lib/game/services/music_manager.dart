import 'dart:async';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;


enum RepeatMode { off, one, all }
enum PlaybackMode { normal, shuffle, mix, random }

class MusicManager {
  MusicManager() {
    _audioQuery = OnAudioQuery();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      
      // Listen for underlying playback errors
      _audioPlayer?.playbackEventStream.listen((event) {
        // Normal playback events
      }, onError: (Object e, StackTrace stack) {
        debugPrint('A stream error occurred: $e');
      });

      _audioPlayer?.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (repeatMode == RepeatMode.one) {
            playTrack(currentTrack!);
          } else {
            next();
          }
        }
        isPlaying = state.playing;
      });
    } catch (e) {
      debugPrint("Error initializing AudioPlayer: $e");
    }
  }

  // Removed _initAudioSession entirely to let just_audio_background manage the session

  AudioPlayer? _audioPlayer;
  late final OnAudioQuery _audioQuery;

  List<SongModel> playlist = [];
  List<SongModel> _originalPlaylist = []; // Keep for reference
  Map<String, int> _genrePreferences = {}; // "ML-lite" preference tracking
  bool isShuffled = false;
  PlaybackMode playbackMode = PlaybackMode.normal;
  RepeatMode repeatMode = RepeatMode.off;
  bool isPlaying = false;

  // Stream for current index to keep UI in sync
  Stream<int?> get currentIndexStream => _audioPlayer?.currentIndexStream ?? const Stream.empty();
  int? get currentIndex => _audioPlayer?.currentIndex;
  SongModel? get currentTrack => (_audioPlayer != null && currentIndex != null && currentIndex! < playlist.length) ? playlist[currentIndex!] : null;

  Future<bool> requestPermissions() async {
    try {
      final p1 = await Permission.storage.request();
      final p2 = await Permission.audio.request();
      final p3 = await Permission.notification.request();
      final granted = p1.isGranted || p2.isGranted || p3.isGranted;
      debugPrint("Permissions status: storage=${p1.isGranted}, audio=${p2.isGranted}, notification=${p3.isGranted}");
      return granted;
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
      return false;
    }
  }

  Future<List<SongModel>> fetchSongs({bool newestFirst = true}) async {
    try {
      final storageGranted = await Permission.storage.isGranted;
      final audioGranted = await Permission.audio.isGranted;
      
      if (!storageGranted && !audioGranted) {
        debugPrint("FETCH SONGS: Permissions NOT granted.");
        return [];
      }
      
      final songs = await _audioQuery.querySongs(
        sortType: newestFirst ? SongSortType.DATE_ADDED : SongSortType.TITLE,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );
      playlist = songs;
      _originalPlaylist = List.from(songs);
      
      // Initialize preferences if empty
      if (_genrePreferences.isEmpty) {
        for (var song in songs) {
          if (song.genre != null) _genrePreferences[song.genre!] = 0;
        }
      }

      await _updateAudioSource();
      debugPrint("FETCH SONGS: Found ${songs.length} songs.");
      return songs;
    } catch (e) {
      debugPrint("Error fetching songs: $e");
      return [];
    }
  }

  Future<void> playTrack(SongModel song) async {
    final index = playlist.indexOf(song);
    if (index != -1) {
      await playSpecific(index);
    }
  }

  Future<void> pause() async {
    await _audioPlayer?.pause();
    isPlaying = false;
  }

  Future<void> resume() async {
    await _audioPlayer?.play();
    isPlaying = true;
  }

  Future<void> next() async {
    if (playbackMode == PlaybackMode.random && playlist.isNotEmpty) {
      final randomIndex = math.Random().nextInt(playlist.length);
      await playSpecific(randomIndex);
      return;
    }

    if (_audioPlayer?.hasNext ?? false) {
      await _audioPlayer?.seekToNext();
    } else if (playlist.isNotEmpty) {
      await playSpecific(0); // Wrap to beginning
    }
  }

  Future<void> prev() async {
    if (_audioPlayer?.hasPrevious ?? false) {
      await _audioPlayer?.seekToPrevious();
    } else if (playlist.isNotEmpty) {
      await playSpecific(playlist.length - 1); // Wrap to end
    }
  }

  Future<void> playSpecific(int index) async {
    if (playlist.isEmpty || index < 0 || index >= playlist.length) return;
    try {
      final song = playlist[index];
      // "ML" - Record preference
      if (song.genre != null) {
        _genrePreferences[song.genre!] = (_genrePreferences[song.genre!] ?? 0) + 1;
      }

      await _audioPlayer?.seek(Duration.zero, index: index);
      _audioPlayer?.play();
      isPlaying = true;
    } catch (e) {
      debugPrint("Error playing specific track: $e");
    }
  }

  Future<void> _updateAudioSource() async {
    if (_audioPlayer == null) return;
    await _audioPlayer!.setAudioSource(
      ConcatenatingAudioSource(
        children: playlist.map((song) {
          final Uri contentUri = Uri.parse('content://media/external/audio/media/${song.id}');
          return AudioSource.uri(
            contentUri,
            tag: MediaItem(
              id: song.id.toString(),
              album: song.album ?? "Unknown Album",
              title: song.title,
              artist: song.artist ?? "Unknown Artist",
              duration: Duration(milliseconds: song.duration ?? 0),
              artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'),
            ),
          );
        }).toList(),
      ),
      preload: false,
    );
  }

  void sortSongs(String criteria) {
    switch (criteria) {
      case 'title':
        playlist.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'album':
        playlist.sort((a, b) => (a.album ?? "").compareTo(b.album ?? ""));
        break;
      case 'date_desc':
        playlist.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        break;
      case 'date_asc':
        playlist.sort((a, b) => (a.dateAdded ?? 0).compareTo(b.dateAdded ?? 0));
        break;
    }
    _updateAudioSource();
  }

  Map<String, List<SongModel>> getAlbums() {
    Map<String, List<SongModel>> albums = {};
    for (var song in _originalPlaylist) {
      final albumName = song.album ?? "Unknown Album";
      albums.putIfAbsent(albumName, () => []).add(song);
    }
    return albums;
  }

  Map<String, List<SongModel>> getGenres() {
    Map<String, List<SongModel>> genres = {};
    for (var song in _originalPlaylist) {
      final genreName = song.genre ?? "Unknown Genre";
      genres.putIfAbsent(genreName, () => []).add(song);
    }
    return genres;
  }

  void smartShuffle() {
    if (playlist.isEmpty) return;
    
    // Sort playlist biased by genre preferences
    playlist.sort((a, b) {
      final prefA = _genrePreferences[a.genre] ?? 0;
      final prefB = _genrePreferences[b.genre] ?? 0;
      if (prefA != prefB) return prefB.compareTo(prefA);
      return math.Random().nextInt(3) - 1; // Random tie-break
    });

    _updateAudioSource();
    playSpecific(0);
    isShuffled = true;
  }

  List<SongModel> get songs => playlist;

  void togglePlayMode() {
    playbackMode = PlaybackMode.values[(playbackMode.index + 1) % PlaybackMode.values.length];
    
    switch (playbackMode) {
      case PlaybackMode.normal:
        isShuffled = false;
        _audioPlayer?.setShuffleModeEnabled(false);
        // Restore original order if needed, but usually just turning off shuffle is enough
        break;
      case PlaybackMode.shuffle:
        isShuffled = true;
        _audioPlayer?.setShuffleModeEnabled(true);
        break;
      case PlaybackMode.mix:
        isShuffled = false;
        _audioPlayer?.setShuffleModeEnabled(false);
        smartShuffle();
        break;
      case PlaybackMode.random:
        isShuffled = false;
        _audioPlayer?.setShuffleModeEnabled(false);
        // Pure random is handled in next()
        break;
    }
  }

  void toggleShuffle() {
    isShuffled = !isShuffled;
    _audioPlayer?.setShuffleModeEnabled(isShuffled);
    if (isShuffled) playbackMode = PlaybackMode.shuffle;
    else playbackMode = PlaybackMode.normal;
  }
  
  void cycleRepeat() {
    repeatMode = RepeatMode.values[(repeatMode.index + 1) % RepeatMode.values.length];
    if (repeatMode == RepeatMode.one) {
      _audioPlayer?.setLoopMode(LoopMode.one);
    } else if (repeatMode == RepeatMode.all) {
      _audioPlayer?.setLoopMode(LoopMode.all);
    } else {
      _audioPlayer?.setLoopMode(LoopMode.off);
    }
  }

  double get currentBPM => 120.0;
}
