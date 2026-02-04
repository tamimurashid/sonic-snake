import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

class AudioManager {
  AudioManager() {
    _sfxPlayer = AudioPlayer();
    _musicPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  }

  late final AudioPlayer _sfxPlayer;
  late final AudioPlayer _musicPlayer;

  bool soundEnabled = true;
  bool musicEnabled = false;

  List<PlatformFile> playlist = [];
  int currentTrackIndex = -1;
  bool isShuffled = false;

  void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }

  Future<void> playSfx(String assetPath) async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> pickMusic() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    playlist = result.files;
    currentTrackIndex = 0;
    musicEnabled = true;
    await _playCurrentTrack();
  }

  Future<void> _playCurrentTrack() async {
    if (currentTrackIndex < 0 || currentTrackIndex >= playlist.length) return;
    final path = playlist[currentTrackIndex].path;
    if (path == null) return;

    try {
      await _musicPlayer.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<void> toggleMusic(bool enabled) async {
    musicEnabled = enabled;
    if (musicEnabled) {
      await _playCurrentTrack();
    } else {
      await _musicPlayer.pause();
    }
  }

  Future<void> nextTrack() async {
    if (playlist.isEmpty) return;
    if (isShuffled) {
      currentTrackIndex = Random().nextInt(playlist.length);
    } else {
      currentTrackIndex = (currentTrackIndex + 1) % playlist.length;
    }
    await _playCurrentTrack();
  }

  Future<void> previousTrack() async {
    if (playlist.isEmpty) return;
    currentTrackIndex = (currentTrackIndex - 1 + playlist.length) % playlist.length;
    await _playCurrentTrack();
  }

  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  String? get currentTrackName {
    if (currentTrackIndex < 0 || currentTrackIndex >= playlist.length) return null;
    return playlist[currentTrackIndex].name;
  }
}
