import 'dart:async';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

enum RepeatMode { off, one, all }

class MusicManager {
  MusicManager() {
    _audioPlayer = AudioPlayer();
    _audioQuery = OnAudioQuery();
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (repeatMode == RepeatMode.one) {
        playTrack(currentTrack!);
      } else {
        next();
      }
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

  Future<void> requestPermissions() async {
    await Permission.storage.request();
    await Permission.audio.request();
  }

  Future<List<SongModel>> fetchSongs({bool newestFirst = true}) async {
    final songs = await _audioQuery.querySongs(
      sortType: newestFirst ? SongSortType.DATE_ADDED : SongSortType.TITLE,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
    );
    playlist = songs;
    return songs;
  }

  Future<void> playTrack(SongModel song) async {
    currentTrack = song;
    currentIndex = playlist.indexOf(song);
    await _audioPlayer.play(DeviceFileSource(song.data));
    isPlaying = true;
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    isPlaying = false;
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
    isPlaying = true;
  }

  Future<void> next() async {
    if (playlist.isEmpty) return;
    if (isShuffled) {
      // Logic for shuffle
    } else {
      currentIndex = (currentIndex + 1) % playlist.length;
    }
    await playTrack(playlist[currentIndex]);
  }

  Future<void> prev() async {
    if (playlist.isEmpty) return;
    currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;
    await playTrack(playlist[currentIndex]);
  }

  void toggleShuffle() => isShuffled = !isShuffled;
  
  void cycleRepeat() {
    repeatMode = RepeatMode.values[(repeatMode.index + 1) % RepeatMode.values.length];
  }

  // BPM calculation simulation or placeholder
  double get currentBPM => 120.0; // Placeholder
}
