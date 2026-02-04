import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Direction;

import '../models/direction.dart';
import '../models/level.dart';
import '../models/snake_skin.dart';
import '../models/obstacle.dart';
import '../services/music_manager.dart';
import '../services/user_progress.dart';
import '../painters/board_painter.dart';
import '../painters/game_painter.dart';
import '../widgets/stat_card.dart';
import '../widgets/control_pad.dart';
import '../widgets/game_menu.dart';

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
  Timer? _timer;

  List<math.Point<int>> _snake = [];
  math.Point<int> _food = const math.Point<int>(0, 0);
  List<Obstacle> _obstacles = [];
  
  Direction _direction = Direction.right;
  Direction _queuedDirection = Direction.right;
  
  bool _isRunning = false;
  bool _isGameOver = false;
  bool _showMenu = true;
  int _score = 0;
  int _combo = 0;
  int _currentLevelNum = 1;
  bool _isBulletTime = false;
  
  late GameTheme _currentTheme;
  late List<GameLevel> _levels;
  SnakeSkin _currentSkin = snakeSkins.first;
  String _currentBoardStyle = 'cyber';
  bool _musicPlayerVisible = true;

  @override
  void initState() {
    super.initState();
    _levels = generateLevels();
    _currentTheme = levelThemes[1]!;
    _initServices();
    _resetGame();
  }

  Future<void> _initServices() async {
    await _progress.init();
    await _music.requestPermissions();
    await _music.fetchSongs();
    
    final savedSkinId = _progress.selectedSkinId;
    setState(() {
      _currentSkin = snakeSkins.firstWhere((s) => s.id == savedSkinId);
      _currentBoardStyle = _progress.boardStyle;
      _musicPlayerVisible = _progress.musicPlayerVisible;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetGame() {
    _timer?.cancel();
    _score = 0;
    _combo = 0;
    _currentLevelNum = 1;
    _isGameOver = false;
    _isRunning = false;
    _isBulletTime = false;
    _direction = Direction.right;
    _queuedDirection = Direction.right;
    _currentTheme = levelThemes[1]!;

    final int midRow = _rows ~/ 2;
    _snake = [
      math.Point<int>(midRow, 5),
      math.Point<int>(midRow, 4),
      math.Point<int>(midRow, 3),
    ];
    
    _obstacles = [];
    _food = _spawnItem();
    setState(() {});
  }

  math.Point<int> _spawnItem() {
    while (true) {
      final p = math.Point(_random.nextInt(_rows), _random.nextInt(_cols));
      if (!_snake.contains(p)) return p;
    }
  }

  void _startGame() {
    if (_isGameOver) {
      _resetGame();
    }
    if (_isRunning) {
      // If already running, just close menu
      setState(() => _showMenu = false);
      return;
    }
    _isRunning = true;
    _showMenu = false;
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    _timer?.cancel();
    final tickRate = _levels[_currentLevelNum - 1].tickRate;
    final effectiveRate = _isBulletTime ? tickRate * 2 : tickRate;
    _timer = Timer.periodic(effectiveRate, (_) => _tick());
  }

  void _pauseGame() {
    _isRunning = false;
    _timer?.cancel();
    setState(() {});
  }

  void _tick() {
    if (!_isRunning) return;

    _direction = _queuedDirection;
    final head = _snake.first;
    final nextHead = _nextPosition(head, _direction);

    if (_isCollision(nextHead)) {
      _handleGameOver();
      return;
    }

    _snake.insert(0, nextHead);

    if (nextHead == _food) {
      _handleEat();
    } else {
      _snake.removeLast();
    }

    setState(() {});
  }

  void _handleEat() {
    _score += 10;
    _combo++;
    _food = _spawnItem();
    HapticFeedback.mediumImpact();

    // Economic increment
    if (_score % 50 == 0) _progress.addCoins(1);

    // Bullet Time Trigger
    if (_combo >= 10 && !_isBulletTime) {
      _triggerBulletTime();
    }

    // Level up logic
    if (_score >= _levels[_currentLevelNum - 1].threshold) {
      _levelUp();
    }
  }

  void _triggerBulletTime() {
    setState(() => _isBulletTime = true);
    _startTimer(); // Restart with slower rate
    Future.delayed(3.seconds, () {
      if (mounted) {
        setState(() {
          _isBulletTime = false;
          if (_isRunning) _startTimer();
        });
      }
    });
  }

  void _levelUp() {
    _currentLevelNum++;
    if (_currentLevelNum > _levels.length) _currentLevelNum = _levels.length;
    if (levelThemes.containsKey(_currentLevelNum)) {
      _currentTheme = levelThemes[_currentLevelNum]!;
    }
    
    // Generate obstacles for levels 2+
    _generateObstacles();
    
    HapticFeedback.heavyImpact();
    _startTimer();
  }

  void _generateObstacles() {
    _obstacles.clear();
    if (_currentLevelNum >= 2) {
      final currentLevel = _levels[_currentLevelNum - 1];
      for (int i = 0; i < currentLevel.numObstacles; i++) {
        math.Point<int> obstaclePos;
        do {
          obstaclePos = math.Point(_random.nextInt(_rows), _random.nextInt(_cols));
        } while (_snake.contains(obstaclePos) || obstaclePos == _food || _obstacles.any((o) => o.position == obstaclePos));
        _obstacles.add(Obstacle(position: obstaclePos));
      }
    }
  }

  void _handleGameOver() {
    _isGameOver = true;
    _isRunning = false;
    _timer?.cancel();
    _combo = 0;
    HapticFeedback.vibrate();
    setState(() {});
  }

  math.Point<int> _nextPosition(math.Point<int> current, Direction direction) {
    switch (direction) {
      case Direction.up: return math.Point((current.x - 1 + _rows) % _rows, current.y);
      case Direction.down: return math.Point((current.x + 1) % _rows, current.y);
      case Direction.left: return math.Point(current.x, (current.y - 1 + _cols) % _cols);
      case Direction.right: return math.Point(current.x, (current.y + 1) % _cols);
    }
  }

  bool _isCollision(math.Point<int> p) {
    // Check snake collision
    if (_snake.contains(p)) return true;
    
    // Check obstacle collision
    for (final obstacle in _obstacles) {
      if (obstacle.position == p) return true;
    }
    
    return false;
  }

  void _queueDirection(Direction d) {
    if (_isOpposite(d, _direction)) return;
    _queuedDirection = d;
  }

  bool _isOpposite(Direction a, Direction b) {
    return (a == Direction.up && b == Direction.down) ||
           (a == Direction.down && b == Direction.up) ||
           (a == Direction.left && b == Direction.right) ||
           (a == Direction.right && b == Direction.left);
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
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildGameBoard()),
                _buildControls(),
              ],
            ),
          ),
          
          if (_showMenu) _buildMenuOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatCard(label: 'Score', value: _score.toString(), color: _currentTheme.accentColor),
                const SizedBox(width: 8),
                StatCard(label: 'Level', value: _currentLevelNum.toString(), color: Colors.amber),
                const SizedBox(width: 8),
                StatCard(label: 'Coins', value: _progress.coins.toString(), color: Colors.amberAccent),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_musicPlayerVisible) _buildMusicBar(),
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
        final size = math.min(constraints.maxWidth, constraints.maxHeight) - 10;
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
                    CustomPaint(
                      painter: BoardPainter(
                        rows: _rows, 
                        cols: _cols, 
                        gridColor: _currentTheme.gridColor,
                        accentColor: _currentTheme.accentColor,
                        style: _currentBoardStyle,
                      ),
                      size: Size(size, size),
                    ),
                    CustomPaint(
                      painter: GamePainter(
                        rows: _rows,
                        cols: _cols,
                        snake: _snake,
                        food: _food,
                        skin: _currentSkin,
                        direction: _direction,
                        isBulletTime: _isBulletTime,
                        obstacles: _obstacles,
                      ),
                      size: Size(size, size),
                    ),
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
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('GAME OVER', style: GoogleFonts.orbitron(fontSize: 32, color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            StatCard(label: 'Final Score', value: _score.toString(), color: Colors.white),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _resetGame, child: const Text("RETRY")),
            TextButton(onPressed: () => setState(() => _showMenu = true), child: const Text("MENU")),
          ],
        ),
      ),
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
        v ? await _music.resume() : await _music.pause();
        setState(() {});
      },
      onPickMusic: () async {
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

  Widget _buildControls() {
    return Column(
      children: [
        // Music Player Bar
        if (_musicPlayerVisible) _buildMusicPlayer(),
        const SizedBox(height: 16),
        // Centered Control Pad with side buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Settings button
              _buildModernSettingsButton(),
              // Centered Control Pad
              ControlPad(onDirection: _queueDirection),
              // Play/Pause button
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        onPressed: () => setState(() => _showMenu = true),
        icon: const Icon(Icons.settings, color: Colors.white, size: 28),
        padding: const EdgeInsets.all(16),
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
