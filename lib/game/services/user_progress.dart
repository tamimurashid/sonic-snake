import 'package:shared_preferences/shared_preferences.dart';

class UserProgress {
  static const String _keyCoins = 'sonic_coins';
  static const String _keyUnlockedSkins = 'unlocked_skins';
  static const String _keySelectedSkin = 'selected_skin';

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
}
