import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/level.dart';
import '../models/snake_skin.dart';

class GameMenu extends StatelessWidget {
  const GameMenu({
    super.key,
    required this.score,
    required this.currentLevel,
    required this.currentSkin,
    required this.currentTheme,
    required this.soundEnabled,
    required this.musicEnabled,
    required this.musicName,
    required this.onSelectLevel,
    required this.onSelectSkin,
    required this.onSelectTheme,
    required this.onToggleSound,
    required this.onToggleMusic,
    required this.onPickMusic,
    required this.onNextTrack,
    required this.onPrevTrack,
    required this.onStart,
    required this.unlockedSkins,
    required this.coins,
    required this.currentBoardStyle,
    required this.onSelectBoardStyle,
    required this.musicPlayerVisible,
    required this.onToggleMusicPlayer,
  });

  final int score;
  final GameLevel currentLevel;
  final SnakeSkin currentSkin;
  final GameTheme currentTheme;
  final bool soundEnabled;
  final bool musicEnabled;
  final String? musicName;
  final ValueChanged<GameLevel> onSelectLevel;
  final ValueChanged<SnakeSkin> onSelectSkin;
  final ValueChanged<GameTheme> onSelectTheme;
  final ValueChanged<bool> onToggleSound;
  final ValueChanged<bool> onToggleMusic;
  final VoidCallback onPickMusic;
  final VoidCallback onNextTrack;
  final VoidCallback onPrevTrack;
  final VoidCallback onStart;
  final List<String> unlockedSkins;
  final int coins;
  final String currentBoardStyle;
  final ValueChanged<String> onSelectBoardStyle;
  final bool musicPlayerVisible;
  final ValueChanged<bool> onToggleMusicPlayer;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SONIC-SNAKE HUB',
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueAccent,
                      letterSpacing: 4,
                    ),
                  ).animate().shimmer(duration: 2.seconds),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('LEVELS'),
                  _buildLevelChips(),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('THEMES'),
                  _buildThemeSelector(),

                  const SizedBox(height: 24),
                  _buildSectionTitle('BOARD STYLE'),
                  _buildBoardStyleSelector(),

                  const SizedBox(height: 24),
                  _buildSectionTitle('SKIN SHOP'),
                  _buildSkinGrid(),

                  const SizedBox(height: 24),
                  _buildSectionTitle('AUDIO CENTER'),
                  _buildAudioController(),
                  _buildMusicVisibilityToggle(),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 10,
                        shadowColor: Colors.blueAccent.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.power_settings_new, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'INITIALIZE CORE',
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white24).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 1.seconds),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.orbitron(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 2),
        ),
      ),
    );
  }

  Widget _buildLevelChips() {
    final levels = generateLevels().take(10).toList(); // Show first 10
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final l = levels[index];
          final isSelected = l.levelNumber == currentLevel.levelNumber;
          return ChoiceChip(
            label: Text(l.levelNumber.toString(), style: TextStyle(color: isSelected ? Colors.white : Colors.white60)),
            selected: isSelected,
            onSelected: (_) => onSelectLevel(l),
            selectedColor: Colors.blueAccent,
            backgroundColor: Colors.white.withOpacity(0.05),
          );
        },
      ),
    );
  }

  Widget _buildThemeSelector() {
    final themes = levelThemes.entries.take(3).toList();
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = themes[index];
          final theme = entry.value;
          final isSelected = theme.name == currentTheme.name;
          return InkWell(
            onTap: () => onSelectTheme(theme),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: theme.gradientColors),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.white10,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected) const SizedBox(height: 4),
                  if (isSelected) const Icon(Icons.check_circle, size: 12, color: Colors.blueAccent),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBoardStyleSelector() {
    final styles = [
      {'id': 'cyber', 'label': 'CYBER GRID', 'icon': Icons.grid_4x4},
      {'id': 'neon', 'label': 'NEON GLOW', 'icon': Icons.light_mode},
      {'id': 'matrix', 'label': 'MATRIX BIT', 'icon': Icons.code},
      {'id': 'classic', 'label': 'LEGACY', 'icon': Icons.grid_on},
    ];
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final s = styles[index];
          final isSelected = s['id'] == currentBoardStyle;
          return ChoiceChip(
            avatar: Icon(s['icon'] as IconData, size: 14, color: isSelected ? Colors.white : Colors.white60),
            label: Text(s['label'] as String),
            labelStyle: GoogleFonts.orbitron(fontSize: 8, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white60),
            selected: isSelected,
            onSelected: (_) => onSelectBoardStyle(s['id'] as String),
            selectedColor: Colors.blueAccent,
            backgroundColor: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
        },
      ),
    );
  }

  Widget _buildSkinGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('$coins', style: const TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: snakeSkins.length,
          itemBuilder: (context, index) {
            final s = snakeSkins[index];
            final isSelected = s.id == currentSkin.id;
            final isUnlocked = unlockedSkins.contains(s.id);
            final canAfford = coins >= s.price;
            
            return InkWell(
              onTap: () => onSelectSkin(s),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(color: s.headColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.label, style: const TextStyle(fontSize: 10, color: Colors.white)),
                          if (!isUnlocked && s.price > 0) 
                            Text(
                              "${s.price} Coins",
                              style: TextStyle(
                                fontSize: 8,
                                color: canAfford ? Colors.amber : Colors.red.shade300,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected) 
                      const Icon(Icons.check_circle, size: 14, color: Colors.blueAccent)
                    else if (!isUnlocked)
                      Icon(Icons.lock, size: 14, color: canAfford ? Colors.amber : Colors.red.shade300),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAudioController() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.blueAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(musicName ?? "NO SIGNAL", style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const Text("SYSTEM AUDIO", style: TextStyle(color: Colors.white54, fontSize: 8)),
                  ],
                ),
              ),
              IconButton(onPressed: () => onToggleMusic(!musicEnabled), icon: Icon(musicEnabled ? Icons.pause : Icons.play_arrow, color: Colors.white)),
            ],
          ),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(onPressed: onPrevTrack, icon: const Icon(Icons.skip_previous, color: Colors.white70)),
              IconButton(onPressed: onPickMusic, icon: const Icon(Icons.library_music, color: Colors.blueAccent)),
              IconButton(onPressed: onNextTrack, icon: const Icon(Icons.skip_next, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMusicVisibilityToggle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'HUD MUSIC PLAYER',
            style: GoogleFonts.orbitron(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38),
          ),
          Switch.adaptive(
            value: musicPlayerVisible,
            onChanged: onToggleMusicPlayer,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
