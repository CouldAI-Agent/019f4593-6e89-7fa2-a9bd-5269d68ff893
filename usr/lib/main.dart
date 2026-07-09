import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const GameScreen(),
      },
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _gameLoop;
  
  // Game state
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  
  // Player state
  double _playerX = 0; // -1 to 1 (left to right)
  final double _playerWidth = 0.2; // 20% of screen width
  final double _playerHeight = 0.15; // 15% of screen height
  
  // Obstacles
  List<Obstacle> _obstacles = [];
  int _ticks = 0;
  final Random _random = Random();
  
  // Input tracking
  int _movementDirection = 0; // -1 left, 1 right, 0 none

  @override
  void initState() {
    super.initState();
    _gameLoop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateGame);
  }

  @override
  void dispose() {
    _gameLoop.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _playerX = 0;
      _obstacles.clear();
      _ticks = 0;
    });
    _gameLoop.repeat();
  }

  void _updateGame() {
    if (!_isPlaying || _isGameOver) return;

    setState(() {
      _ticks++;
      
      // Update player position based on continuous input
      if (_movementDirection != 0) {
        _playerX += _movementDirection * 0.05;
        // Clamp position to screen bounds
        _playerX = _playerX.clamp(-1.0 + _playerWidth, 1.0 - _playerWidth);
      }
      
      // Add new obstacles
      if (_ticks % 30 == 0) {
        _obstacles.add(Obstacle(
          x: (_random.nextDouble() * 2 - 1) * (1 - _playerWidth),
          y: -1.2,
          speed: 0.02 + (_score * 0.0005), // Speed increases with score
        ));
      }

      // Move and check obstacles
      for (int i = _obstacles.length - 1; i >= 0; i--) {
        var obs = _obstacles[i];
        obs.y += obs.speed;

        // Collision detection
        if (obs.y > 1.0 - _playerHeight * 2 && obs.y < 1.0) {
          if ((_playerX - obs.x).abs() < _playerWidth) {
            _gameOver();
          }
        }

        // Remove obstacles that passed
        if (obs.y > 1.2) {
          _obstacles.removeAt(i);
          _score += 10;
        }
      }
    });
  }

  void _gameOver() {
    _gameLoop.stop();
    setState(() {
      _isGameOver = true;
      _isPlaying = false;
    });
  }

  void _movePlayer(int direction) {
    _movementDirection = direction;
  }
  
  void _stopPlayer() {
    _movementDirection = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: KeyboardListener(
          autofocus: true,
          focusNode: FocusNode(),
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                _movePlayer(-1);
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _movePlayer(1);
              }
            } else if (event is KeyUpEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                  event.logicalKey == LogicalKeyboardKey.arrowRight) {
                _stopPlayer();
              }
            }
          },
          child: Stack(
            children: [
              // Road background
              Container(
                color: Colors.grey[900],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) => Container(
                    width: 2,
                    height: double.infinity,
                    color: Colors.white24,
                  )),
                ),
              ),

              // Score
              Positioned(
                top: 20,
                left: 20,
                child: Text(
                  'Score: $_score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Obstacles
              ..._obstacles.map((obs) {
                return Align(
                  alignment: Alignment(obs.x, obs.y),
                  child: Container(
                    width: MediaQuery.of(context).size.width * _playerWidth,
                    height: MediaQuery.of(context).size.height * _playerHeight,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.car_crash, color: Colors.white),
                    ),
                  ),
                );
              }).toList(),

              // Player
              if (_isPlaying || _isGameOver)
                Align(
                  alignment: Alignment(_playerX, 0.8),
                  child: Container(
                    width: MediaQuery.of(context).size.width * _playerWidth,
                    height: MediaQuery.of(context).size.height * _playerHeight,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.directions_car, color: Colors.white, size: 40),
                    ),
                  ),
                ),

              // Touch controls (visible only on mobile/touch screens)
              if (_isPlaying)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTapDown: (_) => _movePlayer(-1),
                        onTapUp: (_) => _stopPlayer(),
                        onTapCancel: () => _stopPlayer(),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_left, size: 50, color: Colors.white),
                        ),
                      ),
                      GestureDetector(
                        onTapDown: (_) => _movePlayer(1),
                        onTapUp: (_) => _stopPlayer(),
                        onTapCancel: () => _stopPlayer(),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_right, size: 50, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // Overlay menus
              if (!_isPlaying)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isGameOver ? 'GAME OVER' : 'CAR RACER',
                          style: TextStyle(
                            color: _isGameOver ? Colors.red : Colors.blue,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isGameOver) ...[
                          Text(
                            'Final Score: $_score',
                            style: const TextStyle(color: Colors.white, fontSize: 20),
                          ),
                          const SizedBox(height: 24),
                        ],
                        ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          ),
                          child: Text(
                            _isGameOver ? 'PLAY AGAIN' : 'START GAME',
                            style: const TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Use Arrow Keys or on-screen buttons to steer',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Obstacle {
  double x;
  double y;
  double speed;

  Obstacle({required this.x, required this.y, required this.speed});
}
