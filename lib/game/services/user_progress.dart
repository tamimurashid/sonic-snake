import 'package:shared_preferences/shared_preferences.dart';

class UserProgress {
  static const String _keyCoins = 'sonic_coins';
  static const String _keyUnlockedSkins = 'unlocked_skins';
  static const String _keySelectedSkin = 'selected_skin';
  static const String _keyBoardStyle = 'board_style';
  static const String _keyMusicPlayerVisible = 'music_player_visible';
  static const String _keyControlsVisible = 'controls_visible';
  static const String _keyUnlockedBoardStyles = 'unlocked_board_styles';
  static const String _keyDifficulty = 'game_difficulty';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  int get coins => _isInitialized ? (_prefs?.getInt(_keyCoins) ?? 0) : 0;

  Future<void> addCoins(int amount) async {
    if (!_isInitialized) return;
    await _prefs!.setInt(_keyCoins, coins + amount);
  }

  Future<bool> spendCoins(int amount) async {
    if (!_isInitialized) return false;
    if (coins >= amount) {
      await _prefs!.setInt(_keyCoins, coins - amount);
      return true;
    }
    return false;
  }

  List<String> get unlockedSkins => _isInitialized 
      ? (_prefs?.getStringList(_keyUnlockedSkins) ?? ['classic']) 
      : ['classic'];

  Future<void> unlockSkin(String skinId) async {
    if (!_isInitialized) return;
    final skins = unlockedSkins;
    if (!skins.contains(skinId)) {
      skins.add(skinId);
      await _prefs!.setStringList(_keyUnlockedSkins, skins);
    }
  }

  bool isSkinUnlocked(String skinId) => unlockedSkins.contains(skinId);

  String get selectedSkinId => _isInitialized 
      ? (_prefs?.getString(_keySelectedSkin) ?? 'classic') 
      : 'classic';

  Future<void> setSelectedSkin(String skinId) async {
    if (!_isInitialized) return;
    await _prefs!.setString(_keySelectedSkin, skinId);
  }

  String get boardStyle => _isInitialized 
      ? (_prefs?.getString(_keyBoardStyle) ?? 'cyber') 
      : 'cyber';

  Future<void> setBoardStyle(String style) async {
    if (!_isInitialized) return;
    await _prefs!.setString(_keyBoardStyle, style);
  }

  bool get musicPlayerVisible => _isInitialized 
      ? (_prefs?.getBool(_keyMusicPlayerVisible) ?? true) 
      : true;

  Future<void> setMusicPlayerVisible(bool visible) async {
    if (!_isInitialized) return;
    await _prefs!.setBool(_keyMusicPlayerVisible, visible);
  }

  bool get controlsVisible => _isInitialized 
      ? (_prefs?.getBool(_keyControlsVisible) ?? false) 
      : false;

  Future<void> setControlsVisible(bool visible) async {
    if (!_isInitialized) return;
    await _prefs!.setBool(_keyControlsVisible, visible);
  }

  List<String> get unlockedBoardStyles => _isInitialized 
      ? (_prefs?.getStringList(_keyUnlockedBoardStyles) ?? ['cyber', 'neon', 'matrix', 'classic', 'style5', 'style6', 'style7', 'style8', 'style9', 'style10']) 
      : ['cyber', 'neon', 'matrix', 'classic', 'style5', 'style6', 'style7', 'style8', 'style9', 'style10'];

  Future<void> unlockBoardStyle(String styleId) async {
    if (!_isInitialized) return;
    final styles = unlockedBoardStyles;
    if (!styles.contains(styleId)) {
      styles.add(styleId);
      await _prefs!.setStringList(_keyUnlockedBoardStyles, styles);
    }
  }

  bool isBoardStyleUnlocked(String styleId) => unlockedBoardStyles.contains(styleId);

  int get difficultyIndex => _isInitialized ? (_prefs?.getInt(_keyDifficulty) ?? 1) : 1;

  Future<void> setDifficultyIndex(int index) async {
    if (!_isInitialized) return;
    await _prefs!.setInt(_keyDifficulty, index);
  }
}
