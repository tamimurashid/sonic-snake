import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Direction;
import 'package:flame/game.dart';

import '../sonic_snake_game.dart';

import '../models/direction.dart';
import '../models/level.dart';
import '../models/snake_skin.dart';
import '../models/obstacle.dart';
import '../services/music_manager.dart';
import '../services/user_progress.dart';
import '../painters/board_painter.dart';
import '../painters/game_painter.dart';
import '../models/game_item.dart';
import '../models/difficulty.dart';
import '../widgets/stat_card.dart';
import '../widgets/control_pad.dart';
import '../widgets/game_menu.dart';
import '../widgets/music_visualizer.dart';

class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({super.key});

  @override
  State<SnakeGameScreen> createState() => _SnakeGameScreenState();
}

class _SnakeGameScreenState extends State<SnakeGameScreen> with TickerProviderStateMixin {
  static const int _rows = 20;
  static const int _cols = 20;

  final math.Random _random = math.Random();
  final MusicManager _music = MusicManager();
  final UserProgress _progress = UserProgress();
  late SonicSnakeGame _game;

  bool _isRunning = false;
  bool _isGameOver = false;
  bool _showMenu = true;
  int _score = 0;
  int _combo = 0;
  int _currentLevelNum = 1;
  Difficulty _difficulty = Difficulty.medium;
  int _foodEaten = 0;
  
  late GameTheme _currentTheme;
  late List<GameLevel> _levels;
  SnakeSkin _currentSkin = snakeSkins.first;
  String _currentBoardStyle = 'cyber';
  bool _musicPlayerVisible = true;
  bool _controlsVisible = false;
  List<String> _unlockedBoardStyles = [];
  String _layoutMode = 'combined'; // combined, music, game
  int _retryCost = 10;

  // Re-added for UI/Logic
  final Stopwatch _playtimeStopwatch = Stopwatch();
  bool _showGestureGuide = true;
  
  // Proxies to Flame game engine
  int get _extraLives => _game.extraLives;
  int get _coinsCollected => _game.coinsCollected;
  bool get _isInvisible => _game.isInvisible;
  bool get _isBulletTime => _game.isBulletTime;

  @override
  void initState() {
    super.initState();
    _levels = generateLevels();
    _currentTheme = levelThemes[1]!;
    _initGame();
    _initServices();
  }

  void _initGame() {
    _game = SonicSnakeGame(
      musicManager: _music,
      skin: _currentSkin,
      onScoreChanged: (newScore) {
        setState(() {
          _score = newScore;
          // Level up logic
          if (_score >= _levels[_currentLevelNum - 1].threshold) {
            _levelUp();
          }
        });
      },
      onComboChanged: (newCombo) {
        setState(() => _combo = newCombo);
      },
      onCoinsCollected: (amount) {
        _progress.addCoins(amount);
        setState(() {});
      },
      onLifeCollected: (lives) {
        setState(() {});
      },
      onGameOver: () {
        _progress.updateHighScore(_score);
        setState(() {
          _isGameOver = true;
          _isRunning = false;
          _playtimeStopwatch.stop();
        });
      },
    );
    
    if (_currentLevelNum > 1) {
      _game.spawnObstacles(_levels[_currentLevelNum - 1].numObstacles);
    }
  }

  Future<void> _initServices() async {
    await _progress.init();
    await _music.fetchSongs();
    
    // Listen to current track changes to update UI
    _music.currentIndexStream.listen((index) {
      if (mounted) setState(() {});
    });
    
    final savedSkinId = _progress.selectedSkinId;
    setState(() {
      _currentSkin = snakeSkins.firstWhere((s) => s.id == savedSkinId);
      _currentBoardStyle = _progress.boardStyle;
      _musicPlayerVisible = _progress.musicPlayerVisible;
      _controlsVisible = _progress.controlsVisible;
      _unlockedBoardStyles = _progress.unlockedBoardStyles;
      _layoutMode = _progress.layoutMode;
      _difficulty = Difficulty.values[_progress.difficultyIndex];
    });
  }

  @override
  void dispose() {
    _playtimeStopwatch.stop();
    super.dispose();
  }

  void _resetGame() {
    _score = 0;
    _isGameOver = false;
    _isRunning = false;
    _foodEaten = 0;
    _playtimeStopwatch.reset();
    _initGame();
    setState(() {});
  }
  void _startGame() {
    if (_isGameOver) {
      _resetGame();
    }
    _game.resumeEngine();
    if (!_playtimeStopwatch.isRunning) _playtimeStopwatch.start();
    setState(() {
      _isRunning = true;
      _showMenu = false;
    });
  }

  void _pauseGame() {
    _game.pauseEngine();
    _playtimeStopwatch.stop();
    setState(() {
      _isRunning = false;
    });
  }

  void _levelUp() {
    if (_currentLevelNum >= _levels.length) return;
    
    setState(() {
      _currentLevelNum++;
      if (levelThemes.containsKey(_currentLevelNum)) {
        _currentTheme = levelThemes[_currentLevelNum]!;
      }
    });
    
    _game.spawnObstacles(_levels[_currentLevelNum - 1].numObstacles);
    HapticFeedback.heavyImpact();
  }

  void _queueDirection(Direction d) {
    if (_isRunning) {
      _game.snake.direction = d;
    }
  }

  bool _isOpposite(Direction a, Direction b) {
    return (a == Direction.up && b == Direction.down) ||
           (a == Direction.down && b == Direction.up) ||
           (a == Direction.left && b == Direction.right) ||
           (a == Direction.right && b == Direction.left);
  }

  void _toggleLayoutMode() {
    String nextMode;
    // Fast cycle optimized for user's primary choices: Combined (Hybrid) and Music
    if (_layoutMode == 'combined') nextMode = 'music';
    else if (_layoutMode == 'music') nextMode = 'game';
    else nextMode = 'combined';
    
    setState(() => _layoutMode = nextMode);
    _progress.setLayoutMode(nextMode);
    HapticFeedback.selectionClick();
  }

  Future<void> _handleRetry() async {
    if (_progress.coins >= _retryCost) {
      await _progress.spendCoins(_retryCost);
      _resetGame();
      _startGame();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins! Need 10.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentTheme.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ).animate(target: _isBulletTime ? 1 : 0).tint(color: Colors.white, end: 0.2),
          
          // Music Visualizer (Background Particles)
          MusicVisualizer(
            isPlaying: _music.isPlaying,
            color: _currentTheme.accentColor,
          ),

          SafeArea(
            child: Column(
              children: [
                if (_layoutMode != 'game') _buildHeader(),
                if (_layoutMode != 'music') Expanded(child: _buildGameBoard()),
                if (_layoutMode == 'music') const Spacer(),
                if (_layoutMode == 'music') _buildAdvancedMusicUI(), // New UI for full music mode
                if (_layoutMode != 'music') _buildHUDControls(),
              ],
            ),
          ),
          
          if (_showGestureGuide) _buildGestureGuide(),
          if (_isGameOver) _buildGameOverOverlay(),
          if (_showMenu) _buildMenuOverlay(),

          // Persistent Layout Toggle Button
          Positioned(
            top: 10,
            left: 10,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: IconButton(
                  icon: Icon(
                    _layoutMode == 'combined' ? Icons.dashboard : 
                    _layoutMode == 'music' ? Icons.music_note : Icons.videogame_asset,
                    color: Colors.blueAccent,
                  ),
                  onPressed: _toggleLayoutMode,
                  tooltip: 'Switch Layout Mode',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGestureGuide() {
    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.swipe, color: Colors.blueAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'SWIPE TO CONTROL',
                style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Up, Down, Left, Right',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().scale().fadeOut(delay: 1.5.seconds),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatCard(label: 'Score', value: _score.toString(), color: _currentTheme.accentColor),
                      const SizedBox(width: 8),
                      StatCard(label: 'High', value: _progress.highScore.toString(), color: Colors.amber),
                      const SizedBox(width: 8),
                      StatCard(label: 'Level', value: _currentLevelNum.toString(), color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      StatCard(label: 'Coins', value: _progress.coins.toString(), color: Colors.amberAccent),
                      if (_extraLives > 0) ...[
                        const SizedBox(width: 8),
                        StatCard(label: 'Lives', value: _extraLives.toString(), color: Colors.redAccent),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_musicPlayerVisible && _layoutMode != 'music') _buildMusicBar(),
        ],
      ),
    );
  }

  Widget _buildMusicBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.music_note, color: Colors.blueAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _music.currentTrack?.title ?? "NOT PLAYING",
              style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_isBulletTime) 
            Text("BULLET TIME", style: GoogleFonts.orbitron(fontSize: 8, color: Colors.redAccent, fontWeight: FontWeight.bold))
            .animate(onPlay: (c) => c.repeat()).fade().scale(),
        ],
      ),
    );
  }

  Widget _buildGameBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (math.min(constraints.maxWidth, constraints.maxHeight) - 10).clamp(0.0, double.infinity);
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _currentTheme.boardColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: _currentTheme.accentColor.withOpacity(0.3), blurRadius: 60, spreadRadius: -10),
                BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 10, offset: const Offset(5, 5)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GestureDetector(
                onPanUpdate: (details) {
                  final dx = details.delta.dx;
                  final dy = details.delta.dy;
                  if (dx.abs() > dy.abs()) {
                    _queueDirection(dx > 0 ? Direction.right : Direction.left);
                  } else {
                    _queueDirection(dy > 0 ? Direction.down : Direction.up);
                  }
                },
                child: Stack(
                  children: [
                    GameWidget(game: _game),
                    if (_isGameOver) _buildGameOverOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ).animate(target: _isBulletTime ? 1 : 0).shake(hz: 4, curve: Curves.easeInOut);
      },
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GAME OVER', 
              style: GoogleFonts.orbitron(fontSize: 40, color: Colors.redAccent, fontWeight: FontWeight.bold)
            ).animate().shake().fadeIn(),
            const SizedBox(height: 20),
            StatCard(label: 'Score', value: _score.toString(), color: Colors.white),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text("RETRY (10 COINS)", style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _handleRetry,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => setState(() => _showMenu = true), 
              child: Text("BACK TO MENU", style: GoogleFonts.orbitron(color: Colors.white70))
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedMusicUI() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MUSIC LAB', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 18)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.sort_by_alpha, color: Colors.blueAccent), 
                      onPressed: () => setState(() => _music.sortSongs('title')),
                      tooltip: 'Sort by Title',
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.blueAccent), 
                      onPressed: () => setState(() => _music.sortSongs('date')),
                      tooltip: 'Sort by Date',
                    ),
                    IconButton(
                      icon: const Icon(Icons.psychology, color: Colors.pinkAccent), 
                      onPressed: () => setState(() => _music.smartShuffle()),
                      tooltip: 'Smart Shuffle',
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: _music.songs.length,
                itemBuilder: (context, index) {
                  final song = _music.songs[index];
                  final isCurrent = _music.currentTrack?.id == song.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent ? Colors.blueAccent : Colors.white12,
                      child: Icon(isCurrent ? Icons.play_arrow : Icons.music_note, color: Colors.white),
                    ),
                    title: Text(song.title, 
                      style: TextStyle(color: isCurrent ? Colors.blueAccent : Colors.white70, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(song.album ?? "Unknown Album", 
                      style: const TextStyle(color: Colors.white38, fontSize: 12)
                    ),
                    onTap: () => setState(() => _music.playSpecific(index)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildLargeControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.shuffle, color: _music.isShuffled ? Colors.blueAccent : Colors.white38), 
          onPressed: () => setState(() => _music.toggleShuffle())
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white), 
          onPressed: () => setState(() => _music.prev())
        ),
        FloatingActionButton(
          backgroundColor: Colors.blueAccent,
          onPressed: () => setState(() => _music.isPlaying ? _music.pause() : _music.resume()),
          child: Icon(_music.isPlaying ? Icons.pause : Icons.play_arrow, size: 30),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 40, color: Colors.white), 
          onPressed: () => setState(() => _music.next())
        ),
        IconButton(
          icon: Icon(Icons.repeat, color: _music.repeatMode != RepeatMode.off ? Colors.blueAccent : Colors.white38), 
          onPressed: () => setState(() => _music.cycleRepeat())
        ),
      ],
    );
  }

  Widget _buildMenuOverlay() {
    return GameMenu(
      score: _score,
      currentLevel: _levels[_currentLevelNum - 1],
      currentSkin: _currentSkin,
      currentTheme: _currentTheme,
      soundEnabled: true,
      musicEnabled: _music.isPlaying,
      musicName: _music.currentTrack?.title,
      unlockedSkins: _progress.unlockedSkins,
      coins: _progress.coins,
      currentBoardStyle: _currentBoardStyle,
      musicPlayerVisible: _musicPlayerVisible,
      controlsVisible: _controlsVisible,
      unlockedBoardStyles: _unlockedBoardStyles,
      onUnlockBoardStyle: (styleId, price) async {
        if (await _progress.spendCoins(price)) {
          await _progress.unlockBoardStyle(styleId);
          setState(() => _unlockedBoardStyles = _progress.unlockedBoardStyles);
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.heavyImpact();
        }
      },
      currentDifficulty: _difficulty,
      onSelectDifficulty: (diff) async {
        setState(() {
          _difficulty = diff;
        });
        await _progress.setDifficultyIndex(diff.index);
        HapticFeedback.selectionClick();
      },
      foodEaten: _foodEaten,
      onToggleControls: (visible) async {
        await _progress.setControlsVisible(visible);
        setState(() => _controlsVisible = visible);
      },
      onSelectBoardStyle: (style) async {
        await _progress.setBoardStyle(style);
        setState(() => _currentBoardStyle = style);
      },
      onToggleMusicPlayer: (visible) async {
        await _progress.setMusicPlayerVisible(visible);
        setState(() => _musicPlayerVisible = visible);
      },
      onSelectLevel: (l) => setState(() => _currentLevelNum = l.levelNumber),
      onSelectTheme: (theme) {
        setState(() => _currentTheme = theme);
      },
      onSelectSkin: (s) async {
        if (_progress.isSkinUnlocked(s.id)) {
          await _progress.setSelectedSkin(s.id);
          setState(() => _currentSkin = s);
        } else {
          if (await _progress.spendCoins(s.price)) {
            await _progress.unlockSkin(s.id);
            await _progress.setSelectedSkin(s.id);
            setState(() => _currentSkin = s);
            HapticFeedback.mediumImpact();
          } else {
            HapticFeedback.heavyImpact();
          }
        }
      },
      onToggleSound: (v) {},
      onToggleMusic: (v) async {
        if (v) {
           await _music.requestPermissions();
           await _music.fetchSongs(); 
           await _music.resume();
        } else {
           await _music.pause();
        }
        setState(() {});
      },
      onPickMusic: () async {
        await _music.requestPermissions();
        await _music.fetchSongs();
        await _music.next();
        setState(() {});
      },
      onNextTrack: () async {
        await _music.next();
        setState(() {});
      },
      onPrevTrack: () async {
        await _music.prev();
        setState(() {});
      },
      onStart: _startGame,
    );
  }

  Widget _buildHUDControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Music Player Bar (Independent)
        if (_musicPlayerVisible) _buildMusicPlayer(),
        
        Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Settings button (Independent)
              _buildModernSettingsButton(),
              
              // Centered Control Pad area (Flexible to prevent overflow)
              Flexible(
                child: Center(
                  child: _controlsVisible 
                    ? ControlPad(onDirection: _queueDirection)
                    : const SizedBox(height: 120, width: 20), // Spacer to keep height and minimal width
                ),
              ),
              
              // Play/Pause button (Independent)
              _buildModernPlayButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernSettingsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        onPressed: () => setState(() => _showMenu = true),
        icon: const Icon(Icons.settings, color: Colors.white, size: 28),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(),
      ),
    ).animate().scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildModernPlayButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _currentTheme.accentColor,
            _currentTheme.accentColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _currentTheme.accentColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: _isRunning ? _pauseGame : _startGame,
        icon: Icon(
          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 36,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(12),
      ),
    ).animate(target: _isRunning ? 1 : 0).shimmer(duration: 2.seconds).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms);
  }

  Widget _buildMusicPlayer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Album art placeholder
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
              ),
            ),
            child: const Icon(Icons.music_note, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _music.currentTrack?.title ?? "No Track",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _music.currentTrack?.artist ?? "Select Music",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Music controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  await _music.prev();
                  setState(() {});
                },
                icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  _music.isPlaying ? await _music.pause() : await _music.resume();
                  setState(() {});
                },
                icon: Icon(
                  _music.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.blueAccent,
                  size: 36,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  await _music.next();
                  setState(() {});
                },
                icon: const Icon(Icons.skip_next, color: Colors.white70, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _showMusicPlaylist,
                icon: const Icon(Icons.queue_music, color: Colors.white70, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMusicPlaylist() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.queue_music, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  const Text(
                    'Music Playlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Flexible(
              child: _music.songs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_off, size: 48, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            'No music found',
                            style: TextStyle(color: Colors.white54),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add music to your device to play',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _music.songs.length,
                      itemBuilder: (context, index) {
                        final song = _music.songs[index];
                        final isPlaying = _music.currentTrack?.id == song.id;
                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: isPlaying
                                    ? [Colors.blueAccent, Colors.purpleAccent]
                                    : [Colors.white24, Colors.white12],
                              ),
                            ),
                            child: Icon(
                              isPlaying ? Icons.equalizer : Icons.music_note,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            song.title,
                            style: TextStyle(
                              color: isPlaying ? Colors.blueAccent : Colors.white,
                              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist ?? 'Unknown Artist',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isPlaying
                              ? const Icon(Icons.volume_up, color: Colors.blueAccent)
                              : null,
                          onTap: () async {
                            await _music.playSpecific(index);
                            setState(() {});
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
