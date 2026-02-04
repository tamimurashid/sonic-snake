import 'dart:async';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

enum RepeatMode { off, one, all }

class MusicManager {
  MusicManager() {
    _audioPlayer = AudioPlayer();
    _audioQuery = OnAudioQuery();
    
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (repeatMode == RepeatMode.one) {
          playTrack(currentTrack!);
        } else {
          next();
        }
      }
      isPlaying = state.playing;
    });
  }

  late final AudioPlayer _audioPlayer;
  late final OnAudioQuery _audioQuery;

  List<SongModel> playlist = [];
  SongModel? currentTrack;
  int currentIndex = -1;
  
  bool isShuffled = false;
  RepeatMode repeatMode = RepeatMode.off;
  bool isPlaying = false;

  Future<bool> requestPermissions() async {
    try {
      // Permission.storage.request() might crash if Activity is not ready, so we guard it
      final p1 = await Permission.storage.request();
      final p2 = await Permission.audio.request();
      final p3 = await Permission.notification.request();
      return p1.isGranted || p2.isGranted || p3.isGranted;
    } catch (e) {
      debugPrint("Error requesting permissions: $e");
      return false;
    }
  }

  Future<List<SongModel>> fetchSongs({bool newestFirst = true}) async {
    try {
      // Check permissions first without requesting them to avoid crashes
      if (!await Permission.storage.isGranted && !await Permission.audio.isGranted) {
        return [];
      }
      
      final songs = await _audioQuery.querySongs(
        sortType: newestFirst ? SongSortType.DATE_ADDED : SongSortType.TITLE,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
      );
      playlist = songs;
      return songs;
    } catch (e) {
      debugPrint("Error fetching songs: $e");
      return [];
    }
  }

  Future<void> playTrack(SongModel song) async {
    currentTrack = song;
    currentIndex = playlist.indexOf(song);
    
    // Set metadata for system notification tray
    final audioSource = AudioSource.uri(
      Uri.parse(song.uri ?? song.data),
      tag: MediaItem(
        id: song.id.toString(),
        album: song.album ?? "Unknown Album",
        title: song.title,
        artist: song.artist ?? "Unknown Artist",
        duration: Duration(milliseconds: song.duration ?? 0),
        artUri: Uri.parse('content://media/external/audio/media/${song.id}/albumart'), // Try to get album art
      ),
    );

    await _audioPlayer.setAudioSource(audioSource);
    await _audioPlayer.play();
    isPlaying = true;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    isPlaying = false;
  }

  Future<void> resume() async {
    await _audioPlayer.play();
    isPlaying = true;
  }

  Future<void> next() async {
    if (playlist.isEmpty) return;
    currentIndex = (currentIndex + 1) % playlist.length;
    await playTrack(playlist[currentIndex]);
  }

  Future<void> prev() async {
    if (playlist.isEmpty) return;
    currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;
    await playTrack(playlist[currentIndex]);
  }

  Future<void> playSpecific(int index) async {
    if (playlist.isEmpty || index < 0 || index >= playlist.length) return;
    currentIndex = index;
    await playTrack(playlist[currentIndex]);
  }

  List<SongModel> get songs => playlist;

  void toggleShuffle() => isShuffled = !isShuffled;
  
  void cycleRepeat() {
    repeatMode = RepeatMode.values[(repeatMode.index + 1) % RepeatMode.values.length];
    if (repeatMode == RepeatMode.one) {
      _audioPlayer.setLoopMode(LoopMode.one);
    } else if (repeatMode == RepeatMode.all) {
      _audioPlayer.setLoopMode(LoopMode.all);
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
    }
  }

  double get currentBPM => 120.0;
}
