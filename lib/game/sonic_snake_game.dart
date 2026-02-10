import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/direction.dart';
import 'models/snake_skin.dart';
import 'models/game_item.dart';
import 'services/music_manager.dart';
import 'components/snake_component.dart';
import 'components/item_component.dart';
import 'components/obstacle_component.dart';

class SonicSnakeGame extends FlameGame with TapCallbacks, DragCallbacks, KeyboardEvents {
  @override
  Color backgroundColor() => Colors.transparent;
  final MusicManager musicManager;
  final SnakeSkin skin;
  final Function(int) onScoreChanged;
  final Function(int) onComboChanged;
  final Function(int) onCoinsCollected;
  final Function(int) onLifeCollected;
  final VoidCallback onGameOver;

  SonicSnakeGame({
    required this.musicManager,
    required this.skin,
    required this.onScoreChanged,
    required this.onComboChanged,
    required this.onCoinsCollected,
    required this.onLifeCollected,
    required this.onGameOver,
  });

  late SnakeComponent snake;
  final List<ItemComponent> _items = [];
  final List<ObstacleComponent> _obstacles = [];
  
  int score = 0;
  int combo = 0;
  int extraLives = 0;
  int coinsCollected = 0;
  double _tickTimer = 0;
  bool isInvisible = false;
  bool isBulletTime = false;
  
  double get tickInterval {
    double base = (60 / musicManager.currentBPM) * 0.4;
    if (isBulletTime) base *= 2.0;
    return base;
  }

  @override
  FutureOr<void> onLoad() async {
    snake = SnakeComponent(
      body: [const math.Point(10, 10), const math.Point(10, 11), const math.Point(10, 12)],
      direction: Direction.up,
      skin: skin,
      cellSize: 20.0,
    );
    
    add(snake);
    _spawnNewItem(forceFood: true);
  }

  void _spawnNewItem({bool forceFood = false}) {
    final random = math.Random();
    final gridWidth = (size.x / 20).floor();
    final gridHeight = (size.y / 20).floor();
    
    math.Point<int> newPos;
    do {
      newPos = math.Point(random.nextInt(gridWidth), random.nextInt(gridHeight));
    } while (snake.body.contains(newPos) || _items.any((i) => i.gridPosition == newPos) || _obstacles.any((o) => o.gridPosition == newPos));
    
    ItemType type = ItemType.food;
    if (!forceFood) {
      final r = random.nextDouble();
      if (r < 0.1) type = ItemType.coin;
      else if (r < 0.15) type = ItemType.booster;
      else if (r < 0.18) type = ItemType.lifeSaver;
    }
    
    final item = ItemComponent(gridPosition: newPos, type: type);
    _items.add(item);
    add(item);
  }

  void spawnObstacles(int count) {
    final random = math.Random();
    final gridWidth = (size.x / 20).floor();
    final gridHeight = (size.y / 20).floor();

    for (int i = 0; i < count; i++) {
        math.Point<int> newPos;
        do {
          newPos = math.Point(random.nextInt(gridWidth), random.nextInt(gridHeight));
        } while (snake.body.contains(newPos) || _items.any((item) => item.gridPosition == newPos) || _obstacles.any((o) => o.gridPosition == newPos));
        
        final obstacle = ObstacleComponent(gridPosition: newPos);
        _obstacles.add(obstacle);
        add(obstacle);
    }
  }

  @override
  void update(double dt) {
    if (paused) return;
    super.update(dt);
    
    _tickTimer += dt;
    if (_tickTimer >= tickInterval) {
      _tickTimer = 0;
      _tick();
    }
  }

  void _tick() {
    final gridWidth = (size.x / 20).floor();
    final gridHeight = (size.y / 20).floor();

    // Check collision with next position before moving
    final nextHead = snake.nextPosition(snake.head, snake.direction, gridWidth, gridHeight);
    
    // Check item collision FIRST
    int collectedIndex = -1;
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].gridPosition == nextHead) {
        collectedIndex = i;
        break;
      }
    }

    if (collectedIndex != -1) {
      final item = _items[collectedIndex];
      _handleItemCollection(item, gridWidth, gridHeight);
      final isFood = item.type == ItemType.food;
      remove(item);
      _items.removeAt(collectedIndex);
      
      if (isFood) {
        snake.grow(gridWidth, gridHeight);
        _spawnNewItem(forceFood: true);
      } else {
        snake.move(gridWidth, gridHeight);
      }
    } else {
      // Check for obstacle or self-collision at nextHead
      bool collision = false;
      
      // Self collision
      for (final segment in snake.body) {
        if (segment == nextHead) {
          collision = true;
          break;
        }
      }

      // Obstacle collision
      if (!isInvisible && !collision) {
        for (final o in _obstacles) {
          if (o.gridPosition == nextHead) {
            collision = true;
            break;
          }
        }
      }

      if (collision) {
        if (extraLives > 0) {
          extraLives--;
          onLifeCollected(extraLives);
          HapticFeedback.vibrate();
          isInvisible = true;
          Future.delayed(const Duration(seconds: 2), () => isInvisible = false);
          snake.move(gridWidth, gridHeight); // Allow moving even on collision if lives exist
        } else {
          onGameOver();
          pauseEngine();
          return;
        }
      } else {
        snake.move(gridWidth, gridHeight);
      }
    }
  }

  void _handleItemCollection(ItemComponent item, int gridWidth, int gridHeight) {
    HapticFeedback.mediumImpact();
    switch (item.type) {
      case ItemType.food:
        score += 10;
        combo++;
        snake.grow(gridWidth, gridHeight);
        onScoreChanged(score);
        onComboChanged(combo);
        if (combo >= 10 && !isBulletTime) _triggerBulletTime();
        break;
      case ItemType.coin:
        coinsCollected++;
        onCoinsCollected(1);
        break;
      case ItemType.booster:
        _activateBooster();
        break;
      case ItemType.lifeSaver:
        extraLives++;
        onLifeCollected(extraLives);
        break;
    }
  }

  void _triggerBulletTime() {
    isBulletTime = true;
    Future.delayed(const Duration(seconds: 5), () {
      isBulletTime = false;
    });
  }

  void _activateBooster() {
    isInvisible = true;
    Future.delayed(const Duration(seconds: 5), () {
      isInvisible = false;
    });
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (paused) return;
    final delta = event.localDelta;
    if (delta.length < 5) return; // Sensitivity threshold
    
    if (delta.x.abs() > delta.y.abs()) {
      if (delta.x > 0 && snake.direction != Direction.left) snake.direction = Direction.right;
      else if (delta.x < 0 && snake.direction != Direction.right) snake.direction = Direction.left;
    } else {
      if (delta.y > 0 && snake.direction != Direction.up) snake.direction = Direction.down;
      else if (delta.y < 0 && snake.direction != Direction.down) snake.direction = Direction.up;
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.arrowUp) && snake.direction != Direction.down) {
        snake.direction = Direction.up;
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown) && snake.direction != Direction.up) {
        snake.direction = Direction.down;
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) && snake.direction != Direction.right) {
        snake.direction = Direction.left;
      } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight) && snake.direction != Direction.left) {
        snake.direction = Direction.right;
      }
    }
    return KeyEventResult.ignored;
  }
}
