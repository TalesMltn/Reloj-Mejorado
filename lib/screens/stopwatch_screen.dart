// lib/screens/stopwatch_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/bubble_animation.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  String _mainTime = '00:00.00';
  bool _isRunning = false;

  final List<Map<String, String>> _laps = [];

  @override
  void initState() {
    super.initState();
    // Ya no cargamos video → fondo es imagen estática
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin

    return Stack(
      children: [
        // Fondo estático con bnita2.jpg
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bnita2.jpg'),  // ← Tu imagen aquí
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Capa oscura para mejor legibilidad
        Container(color: Colors.black.withOpacity(0.5)),

        // Burbujas animadas
        ...List.generate(120, (_) => const BubbleAnimation()),

        // Contenido principal
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 100),

              // Tiempo principal grande
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

              // Lista de vueltas (indicadores)
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
                            Text('Indicador', style: TextStyle(fontSize: 16, color: Colors.white70)),
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

              // Botones
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
                      _isRunning ? 'Indicador' : 'Restablecer',
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