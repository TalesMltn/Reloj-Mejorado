// lib/screens/stopwatch_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../widgets/bubble_animation.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen>
    with AutomaticKeepAliveClientMixin {  // ← AÑADIDO

  @override
  bool get wantKeepAlive => true;  // ← MANTIENE EL ESTADO VIVO

  VideoPlayerController? _videoController;

  final List<String> _localFondos = [
    'assets/videos/🦊🍂1.mp4',
    'assets/videos/🦊🍂2.mp4',
    'assets/videos/🦊🍂3.mp4',
    'assets/videos/🦊🍂4.mp4',
    'assets/videos/🦊🍂5.mp4',
    'assets/videos/🦊🍂6.mp4',
    'assets/videos/🦊🍂7.mp4',
  ];

  int _currentFondoIndex = 0;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  String _mainTime = '00:00.00';
  bool _isRunning = false;

  final List<Map<String, String>> _laps = [];

  @override
  void initState() {
    super.initState();
    _loadBackground(_currentFondoIndex);
  }

  void _loadBackground(int index) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.asset(_localFondos[index])
      ..initialize().then((_) {
        if (!mounted) return;
        _videoController!.play();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0);
        setState(() {});
      });
  }

  void _updateTime() {
    final ms = _stopwatch.elapsedMilliseconds;
    final minutes = (ms / 60000).floor().toString().padLeft(2, '0');
    final seconds = ((ms / 1000) % 60).floor().toString().padLeft(2, '0');
    final millis = (ms % 1000 ~/ 10).toString().padLeft(2, '0');

    setState(() {
      _mainTime = '$minutes:$seconds.$millis';
    });
  }

  void _startStopwatch() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) => _updateTime());
    setState(() => _isRunning = true);
  }

  void _pauseStopwatch() {
    _stopwatch.stop();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetStopwatch() {
    _stopwatch.reset();
    _timer?.cancel();
    setState(() {
      _mainTime = '00:00.00';
      _isRunning = false;
      _laps.clear();
    });
  }

  void _addLap() {
    if (!_stopwatch.isRunning) return;

    final ms = _stopwatch.elapsedMilliseconds;
    final minutes = (ms / 60000).floor().toString().padLeft(2, '0');
    final seconds = ((ms / 1000) % 60).floor().toString().padLeft(2, '0');
    final millis = (ms % 1000 ~/ 10).toString().padLeft(2, '0');
    final lapTime = '$minutes:$seconds.$millis';

    setState(() {
      _laps.insert(0, {
        'lapNumber': '${_laps.length + 1}'.padLeft(2, '0'),
        'lapTime': lapTime,
        'totalTime': lapTime,
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);  // ← REQUERIDO por AutomaticKeepAliveClientMixin

    return Stack(
      children: [
        Container(color: Colors.black),
        if (_videoController != null && _videoController!.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
        Container(color: Colors.black.withOpacity(0.5)),
        ...List.generate(120, (_) => const BubbleAnimation()),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 100),
              Text(
                _mainTime,
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.cyanAccent, blurRadius: 20),
                    Shadow(color: Colors.cyanAccent, blurRadius: 40),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (_laps.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Vuelta', style: TextStyle(fontSize: 16, color: Colors.white70)),
                            Text('Tiempos parciales', style: TextStyle(fontSize: 16, color: Colors.white70)),
                            Text('Tiempo total', style: TextStyle(fontSize: 16, color: Colors.white70)),
                          ],
                        ),
                        const Divider(color: Colors.white30),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _laps.length,
                            itemBuilder: (context, index) {
                              final lap = _laps[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(lap['lapNumber']!, style: const TextStyle(fontSize: 18, color: Colors.cyanAccent)),
                                    Text(lap['lapTime']!, style: const TextStyle(fontSize: 18)),
                                    Text(lap['totalTime']!, style: const TextStyle(fontSize: 18)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isRunning ? _addLap : _resetStopwatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.cyanAccent,
                      side: const BorderSide(color: Colors.cyanAccent, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 8,
                      shadowColor: Colors.cyanAccent.withOpacity(0.5),
                    ),
                    child: Text(
                      _isRunning ? 'Vuelta' : 'Restablecer',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 40),
                  ElevatedButton(
                    onPressed: _isRunning ? _pauseStopwatch : _startStopwatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 12,
                      shadowColor: Colors.cyanAccent,
                    ),
                    child: Text(
                      _isRunning ? 'Pausar' : 'Iniciar',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}