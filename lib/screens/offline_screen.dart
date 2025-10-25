// Flutter Maze Chase Game — Fully Responsive & Professional
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MazeGamePage extends StatefulWidget {
  const MazeGamePage({Key? key}) : super(key: key);

  @override
  State<MazeGamePage> createState() => _MazeGamePageState();
}

class _MazeGamePageState extends State<MazeGamePage> {
  static const int rows = 13;
  static const int cols = 13;

  late Maze _maze;
  late int playerR, playerC;
  late int chaserR, chaserC;
  Timer? _chaseTimer;
  final Random _rnd = Random();
  bool _gameOver = false;
  bool _won = false;
  int _score = 0;
  int _highScore = 0;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _newMaze();
    _startChaserLoop();
  }

  // Load high score from SharedPreferences
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('maze_chase_high_score') ?? 0;
    });
  }

  // Save high score to SharedPreferences
  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maze_chase_high_score', _highScore);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _chaseTimer?.cancel();
    super.dispose();
  }

  void _newMaze() {
    _maze = Maze(rows: rows, cols: cols, rng: _rnd);
    _maze.generate();
    playerR = 0;
    playerC = 0;
    _placePhantomAtGoodDistance();
    _gameOver = false;
    _won = false;
    setState(() {});
  }

  void _placePhantomAtGoodDistance() {
    final minDistance = 8;
    final maxAttempts = 30;
    var attempts = 0;

    do {
      chaserR = (rows ~/ 2) + _rnd.nextInt(rows ~/ 2);
      chaserC = _rnd.nextInt(cols);
      attempts++;

      if (attempts > maxAttempts) {
        chaserR = max(rows - 3, rows ~/ 2);
        chaserC = max(2, cols ~/ 3);
        break;
      }
    } while (
        (chaserR - playerR).abs() + (chaserC - playerC).abs() < minDistance ||
            (chaserR == playerR && chaserC == playerC) ||
            (chaserR == rows - 1 && chaserC == cols - 1));
  }

  void _startChaserLoop() {
    _chaseTimer?.cancel();
    _chaseTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (_gameOver) return;
      _moveChaserTowardsPlayer();
    });
  }

  void _moveChaserTowardsPlayer() {
    if (_rnd.nextDouble() < 0.2) {
      final directions = [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ];
      final dir = directions[_rnd.nextInt(directions.length)];
      final nr = chaserR + dir[0];
      final nc = chaserC + dir[1];
      if (nr >= 0 &&
          nr < rows &&
          nc >= 0 &&
          nc < cols &&
          _maze.canMove(chaserR, chaserC, nr, nc)) {
        chaserR = nr;
        chaserC = nc;
      }
    } else {
      final next = _maze.nextStepTowards(
          startR: chaserR, startC: chaserC, targetR: playerR, targetC: playerC);
      if (next != null) {
        chaserR = next[0];
        chaserC = next[1];
      }
    }
    _checkState();
    setState(() {});
  }

  void _checkState() {
    if (playerR == chaserR && playerC == chaserC) {
      _gameOver = true;
      _score = 0;
      HapticFeedback.heavyImpact();
      // Add a slight delay for a more dramatic effect
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.mediumImpact();
      });
      _showDialog('GAME OVER', 'The Phantom caught you! Score reset.');
    } else if (playerR == rows - 1 && playerC == cols - 1) {
      _gameOver = true;
      _won = true;
      _score++;
      if (_score > _highScore) {
        _highScore = _score;
        _saveHighScore(); // Save new high score
      }
      HapticFeedback.mediumImpact();
      _showDialog('LEVEL CLEAR!', 'You escaped the maze! +1 Score');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => NesContainer(
        child: AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(0),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          actions: [
            NesButton(
              onPressed: () {
                Navigator.pop(context);
                _newMaze();
              },
              type: NesButtonType.primary,
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      ),
    );
  }

  void _movePlayer(int dr, int dc) {
    if (_gameOver) return;
    final nr = playerR + dr;
    final nc = playerC + dc;
    if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) return;
    if (_maze.canMove(playerR, playerC, nr, nc)) {
      playerR = nr;
      playerC = nc;
      _checkState();
      setState(() {});
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _movePlayer(-1, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _movePlayer(1, 0);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA) {
        _movePlayer(0, -1);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        _movePlayer(0, 1);
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _newMaze();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        if (_gameOver) _newMaze();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > constraints.maxHeight;
              // final isMobile ;
              // final isDesktop = constraints.maxWidth >= 800;
              // final isMobile = constraints.maxWidth < 800;

              return SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 600 ? 8.0 : 16.0,
                    vertical: 8.0,
                  ),
                  child: isDesktop
                      ? _buildDesktopLayout(constraints)
                      : _buildMobileLayout(constraints),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    final screenWidth = constraints.maxWidth;
    final availableWidth = screenWidth - 32; // Increased padding
    final cellSize = (availableWidth / cols).clamp(20.0, 35.0);
    final mazeSize = cellSize * cols;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(true, constraints.maxWidth),
        const SizedBox(height: 12),
        _buildGameStatus(constraints.maxWidth < 400),
        const SizedBox(height: 12),
        Center(
          child: NesContainer(
            padding: const EdgeInsets.all(6),
            child: Container(
              width: mazeSize + 6, // Fixed width to prevent overflow
              height: mazeSize + 6, // Fixed height to prevent overflow
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
              ),
              padding: const EdgeInsets.all(3),
              child: CustomPaint(
                size: Size(mazeSize, mazeSize),
                painter: MazePainter(
                  maze: _maze,
                  cellSize: cellSize,
                  playerR: playerR,
                  playerC: playerC,
                  chaserR: chaserR,
                  chaserC: chaserC,
                  exitR: rows - 1,
                  exitC: cols - 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDPadControls(true),
        const SizedBox(height: 12),
        _buildInstructions(true, constraints.maxWidth),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    final availableHeight = constraints.maxHeight - 32;
    final cellSize = (availableHeight * 0.7 / rows).clamp(30.0, 50.0);
    final mazeSize = cellSize * cols;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(false, constraints.maxWidth),
                const SizedBox(height: 16),
                _buildGameStatus(false),
                const SizedBox(height: 16),
                Center(
                  child: NesContainer(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: mazeSize + 12,
                      height: mazeSize + 12,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: CustomPaint(
                        size: Size(mazeSize, mazeSize),
                        painter: MazePainter(
                          maze: _maze,
                          cellSize: cellSize,
                          playerR: playerR,
                          playerC: playerC,
                          chaserR: chaserR,
                          chaserC: chaserC,
                          exitR: rows - 1,
                          exitC: cols - 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                _buildDPadControls(false),
                const SizedBox(height: 24),
                _buildInstructions(false, constraints.maxWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile, double screenWidth) {
    if (isMobile && screenWidth < 380) {
      return Column(
        children: [
          // Back button row for small mobile
          Row(
            children: [
              NesButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                type: NesButtonType.normal,
                child: const Text('BACK'),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          NesContainer(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: const Text(
              'MAZE CHASER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              NesContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'SCORE: $_score',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              NesContainer(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'HIGH: $_highScore',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                height: 36,
                child: NesIconButton(
                  icon: NesIcons.rotate,
                  onPress: _newMaze,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button row for larger screens
          Row(
            children: [
              NesButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                type: NesButtonType.normal,
                child: const Text('BACK'),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: NesContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'MAZE CHASER',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    NesContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        'SCORE: $_score',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    NesContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        'HIGH: $_highScore',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 14,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    NesIconButton(
                      icon: NesIcons.rotate,
                      onPress: _newMaze,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildGameStatus(bool isVerySmall) {
    return NesContainer(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 8 : 12,
        vertical: isVerySmall ? 8 : 12,
      ),
      child: Text(
        _gameOver ? (_won ? 'LEVEL CLEAR!' : 'CAUGHT!') : 'ESCAPE THE PHANTOM!',
        style: TextStyle(
          fontSize: isVerySmall ? 13 : 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDPadControls(bool isMobile) {
    final buttonSize = isMobile ? 50.0 : 40.0;
    final spacing = isMobile ? 6.0 : 8.0;

    // Helper function for vibration + movement
    void _vibrateAndMove(int dx, int dy) {
      HapticFeedback.lightImpact();
      _movePlayer(dx, dy);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Up button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: pi / 2,
              child: NesIconButton(
                icon: NesIcons.leftArrowIndicator,
                primaryColor: Colors.transparent,
                size: Size(buttonSize, buttonSize),
              ),
            ),
            Transform.rotate(
              angle: pi / 2,
              child: NesIconButton(
                icon: NesIcons.leftArrowIndicator,
                onPress: () => _vibrateAndMove(-1, 0),
                size: Size(buttonSize, buttonSize),
              ),
            ),
            Transform.rotate(
              angle: pi / 2,
              child: NesIconButton(
                icon: NesIcons.leftArrowIndicator,
                primaryColor: Colors.transparent,
                size: Size(buttonSize, buttonSize),
              ),
            ),
          ],
        ),

        SizedBox(height: spacing),

        // Middle row (Left and Right)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NesIconButton(
              onPress: () => _vibrateAndMove(0, -1),
              icon: NesIcons.leftArrowIndicator,
              size: Size(buttonSize, buttonSize),
            ),
            Transform.rotate(
              angle: pi / 2,
              child: NesIconButton(
                icon: NesIcons.leftArrowIndicator,
                primaryColor: Colors.transparent,
                size: Size(buttonSize, buttonSize),
              ),
            ),
            NesIconButton(
              icon: NesIcons.rightArrowIndicator,
              onPress: () => _vibrateAndMove(0, 1),
              size: Size(buttonSize, buttonSize),
            ),
          ],
        ),

        SizedBox(height: spacing),

        // Down button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: pi / 2,
              child: NesIconButton(
                icon: NesIcons.leftArrowIndicator,
                primaryColor: Colors.transparent,
                size: Size(buttonSize, buttonSize),
              ),
            ),
            Transform.rotate(
              angle: -pi / 2,
              child: NesIconButton(
                icon: NesIcons.leftArrowIndicator,
                onPress: () => _vibrateAndMove(1, 0),
                size: Size(buttonSize, buttonSize),
              ),
            ),
            Transform.rotate(
              angle: pi / 2,
              child: NesIconButton(
                icon: NesIcons.leftArrowIndicator,
                primaryColor: Colors.transparent,
                size: Size(buttonSize, buttonSize),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstructions(bool isMobile, double screenWidth) {
    final isVerySmall = screenWidth < 380;

    return NesContainer(
      padding: EdgeInsets.all(isVerySmall ? 10 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO PLAY',
            style: TextStyle(
              fontSize: isVerySmall ? 13 : (isMobile ? 14 : 16),
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: isVerySmall ? 8 : 12),
          _buildInstructionRow(
              'Controls', 'D-Pad/Arrow Keys/WASD', isMobile, isVerySmall),
          _buildInstructionRow(
              'Phantom', 'Avoid being caught', isMobile, isVerySmall),
          _buildInstructionRow(
              'Exit', 'Green door to win', isMobile, isVerySmall),
          _buildInstructionRow(
              'Restart', 'R key or button', isMobile, isVerySmall),
          SizedBox(height: isVerySmall ? 10 : 16),
          Text(
            'Tip: The phantom moves slower and sometimes takes random paths!',
            style: TextStyle(
              fontSize: isVerySmall ? 10 : (isMobile ? 11 : 13),
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow(
      String action, String description, bool isMobile, bool isVerySmall) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isVerySmall ? 4.0 : 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              action,
              style: TextStyle(
                fontSize: isVerySmall ? 10 : (isMobile ? 11 : 13),
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              description,
              style: TextStyle(
                fontSize: isVerySmall ? 10 : (isMobile ? 11 : 13),
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Maze {
  final int rows;
  final int cols;
  final Random rng;
  late List<List<Cell>> grid;

  Maze({required this.rows, required this.cols, Random? rng})
      : rng = rng ?? Random();

  void generate() {
    for (int attempt = 0; attempt < 5; attempt++) {
      grid = List.generate(rows, (r) => List.generate(cols, (c) => Cell(r, c)));
      _generateRecursiveBacktracker();
      if (_isGoodMaze()) return;
    }
    _ensureSolvability();
  }

  void _generateRecursiveBacktracker() {
    final stack = <Cell>[];
    final start = grid[0][0];
    start.visited = true;
    stack.add(start);

    while (stack.isNotEmpty) {
      final current = stack.last;
      final neighbors = _unvisitedNeighbors(current);

      if (neighbors.isNotEmpty) {
        final next = _chooseBestNeighbor(neighbors, current);
        _removeWall(current, next);
        next.visited = true;
        stack.add(next);
      } else {
        stack.removeLast();
      }
    }

    for (var row in grid) {
      for (var c in row) {
        c.visited = false;
      }
    }

    _createExtraOpenings();
  }

  Cell _chooseBestNeighbor(List<Cell> neighbors, Cell current) {
    neighbors.sort((a, b) {
      final scoreA = (rows - 1 - a.r) + (cols - 1 - a.c);
      final scoreB = (rows - 1 - b.r) + (cols - 1 - b.c);
      return scoreB.compareTo(scoreA);
    });

    return rng.nextDouble() < 0.7
        ? neighbors.first
        : neighbors[rng.nextInt(neighbors.length)];
  }

  void _createExtraOpenings() {
    final extraOpenings = (rows * cols) ~/ 10;
    for (int i = 0; i < extraOpenings; i++) {
      final r = rng.nextInt(rows - 1);
      final c = rng.nextInt(cols - 1);
      if (rng.nextBool()) {
        grid[r][c].bottom = false;
      } else {
        grid[r][c].right = false;
      }
    }
  }

  bool _isGoodMaze() {
    final path = findPath(0, 0, rows - 1, cols - 1);
    return path != null && path.length <= (rows + cols) * 2;
  }

  void _ensureSolvability() {
    final exitCell = grid[rows - 1][cols - 1];
    if (rows > 1) exitCell.bottom = false;
    if (cols > 1) exitCell.right = false;
    grid[0][0].right = false;
    if (rows > 1) grid[0][0].bottom = false;
  }

  List<Cell> _unvisitedNeighbors(Cell c) {
    final n = <Cell>[];
    final r = c.r;
    final col = c.c;
    if (r > 0 && !grid[r - 1][col].visited) n.add(grid[r - 1][col]);
    if (r < rows - 1 && !grid[r + 1][col].visited) n.add(grid[r + 1][col]);
    if (col > 0 && !grid[r][col - 1].visited) n.add(grid[r][col - 1]);
    if (col < cols - 1 && !grid[r][col + 1].visited) n.add(grid[r][col + 1]);
    return n;
  }

  void _removeWall(Cell a, Cell b) {
    if (a.r == b.r) {
      if (a.c < b.c) {
        a.right = false;
      } else {
        b.right = false;
      }
    } else if (a.c == b.c) {
      if (a.r < b.r) {
        a.bottom = false;
      } else {
        b.bottom = false;
      }
    }
  }

  bool canMove(int fromR, int fromC, int toR, int toC) {
    if (fromR == toR && fromC == toC) return false;
    if (toR < 0 || toR >= rows || toC < 0 || toC >= cols) return false;
    if (fromR == toR) {
      if (toC == fromC + 1) return !grid[fromR][fromC].right;
      if (toC == fromC - 1) return !grid[fromR][toC].right;
    } else if (fromC == toC) {
      if (toR == fromR + 1) return !grid[fromR][fromC].bottom;
      if (toR == fromR - 1) return !grid[toR][fromC].bottom;
    }
    return false;
  }

  List<int>? nextStepTowards({
    required int startR,
    required int startC,
    required int targetR,
    required int targetC,
  }) {
    final path = findPath(startR, startC, targetR, targetC);
    return path?.isNotEmpty == true ? path![0] : null;
  }

  List<List<int>>? findPath(int startR, int startC, int targetR, int targetC) {
    final q = <List<int>>[];
    final visited =
        List.generate(rows, (_) => List.generate(cols, (_) => false));
    final parent =
        List.generate(rows, (_) => List.generate(cols, (_) => <int>[]));
    q.add([startR, startC]);
    visited[startR][startC] = true;

    final dirs = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ];

    while (q.isNotEmpty) {
      final cur = q.removeAt(0);
      final r = cur[0];
      final c = cur[1];

      if (r == targetR && c == targetC) {
        final path = <List<int>>[];
        var cr = r, cc = c;
        while (!(cr == startR && cc == startC)) {
          path.add([cr, cc]);
          final p = parent[cr][cc];
          cr = p[0];
          cc = p[1];
        }
        return path.reversed.toList();
      }

      for (var d in dirs) {
        final nr = r + d[0];
        final nc = c + d[1];
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        if (visited[nr][nc]) continue;
        if (!canMove(r, c, nr, nc)) continue;
        visited[nr][nc] = true;
        parent[nr][nc] = [r, c];
        q.add([nr, nc]);
      }
    }
    return null;
  }
}

class Cell {
  final int r;
  final int c;
  bool right = true;
  bool bottom = true;
  bool visited = false;
  Cell(this.r, this.c);
}

class MazePainter extends CustomPainter {
  final Maze maze;
  final double cellSize;
  final int playerR, playerC, chaserR, chaserC, exitR, exitC;

  MazePainter({
    required this.maze,
    required this.cellSize,
    required this.playerR,
    required this.playerC,
    required this.chaserR,
    required this.chaserC,
    required this.exitR,
    required this.exitC,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wall = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    for (var r = 0; r < maze.rows; r++) {
      for (var c = 0; c < maze.cols; c++) {
        final x = c * cellSize;
        final y = r * cellSize;

        if (r == 0) {
          canvas.drawLine(Offset(x, y), Offset(x + cellSize, y), wall);
        }
        if (c == 0) {
          canvas.drawLine(Offset(x, y), Offset(x, y + cellSize), wall);
        }

        final cell = maze.grid[r][c];
        if (cell.right) {
          canvas.drawLine(
            Offset(x + cellSize, y),
            Offset(x + cellSize, y + cellSize),
            wall,
          );
        }
        if (cell.bottom) {
          canvas.drawLine(
            Offset(x, y + cellSize),
            Offset(x + cellSize, y + cellSize),
            wall,
          );
        }
      }
    }

    final exitPaint = Paint()
      ..color = const Color(0xFF00AA00)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        exitC * cellSize + 2,
        exitR * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      ),
      exitPaint,
    );

    final exitBorder = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(
        exitC * cellSize + 2,
        exitR * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      ),
      exitBorder,
    );

    final playerPaint = Paint()
      ..color = const Color(0xFF0066FF)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        playerC * cellSize + cellSize * 0.15,
        playerR * cellSize + cellSize * 0.15,
        cellSize * 0.7,
        cellSize * 0.7,
      ),
      playerPaint,
    );

    final playerOutline = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(
        playerC * cellSize + cellSize * 0.15,
        playerR * cellSize + cellSize * 0.15,
        cellSize * 0.7,
        cellSize * 0.7,
      ),
      playerOutline,
    );

    final chaserPaint = Paint()
      ..color = const Color(0xFFFF4444)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        chaserC * cellSize + cellSize * 0.2,
        chaserR * cellSize + cellSize * 0.2,
        cellSize * 0.6,
        cellSize * 0.6,
      ),
      chaserPaint,
    );

    final eyePaint = Paint()..color = Colors.black;
    final eyeSize = cellSize * 0.15;
    canvas.drawRect(
      Rect.fromLTWH(
        chaserC * cellSize + cellSize * 0.3,
        chaserR * cellSize + cellSize * 0.35,
        eyeSize,
        eyeSize,
      ),
      eyePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        chaserC * cellSize + cellSize * 0.55,
        chaserR * cellSize + cellSize * 0.35,
        eyeSize,
        eyeSize,
      ),
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
