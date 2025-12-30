// lib/screens/timer_screen.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../widgets/bubble_animation.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  Duration _initialDuration = Duration.zero;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;

  late AnimationController _circleController;
  late Animation<double> _circleAnimation;

  static const String _limaZone = 'America/Lima';

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();

    _circleController = AnimationController(vsync: this);
    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.linear),
    );
  }

  void _updateRemaining() {
    setState(() {
      _remaining = Duration(hours: _hours, minutes: _minutes, seconds: _seconds);
      _initialDuration = _remaining;
    });
  }

  void _startTimer() {
    if (_remaining.inSeconds == 0) return;
    _isRunning = true;
    _circleController.duration = _remaining;
    _circleController.forward(from: 0.0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        _stopTimer();
        return;
      }
      setState(() {
        _remaining -= const Duration(seconds: 1);
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _circleController.stop();
    setState(() => _isRunning = false);
  }

  void _resumeTimer() {
    if (_remaining.inSeconds == 0) return;
    _startTimer();
  }

  void _stopTimer() {
    _timer?.cancel();
    _circleController.stop();
    _circleController.reset();
    setState(() {
      _isRunning = false;
      _remaining = Duration.zero;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Temporizador terminado!'),
          backgroundColor: Colors.cyanAccent,
        ),
      );
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    _circleController.reset();
    setState(() {
      _hours = _minutes = _seconds = 0;
      _remaining = Duration.zero;
      _initialDuration = Duration.zero;
      _isRunning = false;
    });
  }

  DateTime get _nowInLima {
    final location = tz.getLocation(_limaZone);
    return tz.TZDateTime.now(location);
  }

  String _getEndTimeText() {
    if (_remaining.inSeconds == 0) return 'Configura el tiempo';
    final DateTime endTime = _nowInLima.add(_remaining);
    return DateFormat('h:mm', 'es_ES').format(endTime);
  }

  String _getPeriodText() {
    if (_remaining.inSeconds == 0) return '';
    final DateTime endTime = _nowInLima.add(_remaining);
    return DateFormat('a', 'es_ES').format(endTime).toLowerCase();
  }

  Future<void> _showNumberPicker(String type) async {
    int initial = type == 'hours' ? _hours : type == 'minutes' ? _minutes : _seconds;
    int max = type == 'hours' ? 99 : 59;

    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => NumberPickerSheet(initial: initial, max: max, title: type),
    );

    if (result != null) {
      setState(() {
        if (type == 'hours') _hours = result;
        if (type == 'minutes') _minutes = result;
        if (type == 'seconds') _seconds = result;
        _updateRemaining();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  String _formatTime(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isSetupMode = _remaining.inSeconds == 0 || !_isRunning;

    return Stack(
      children: [
        // Fondo estático con bnita1.jpg
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bnita1.jpg'),  // ← Tu imagen aquí
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Capa oscura para mejor legibilidad del texto
        Container(color: Colors.black.withOpacity(0.55)),

        // Burbujas animadas
        ...List.generate(80, (_) => const BubbleAnimation()),

        // Contenido principal
        SafeArea(
          child: Column(
            children: [
              if (isSetupMode) ...[
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Text('Horas', style: TextStyle(fontSize: 18, color: Colors.white70)),
                    Text('Minutos', style: TextStyle(fontSize: 18, color: Colors.white70)),
                    Text('Segundos', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _showNumberPicker('hours'),
                      child: Text(
                        _hours.toString().padLeft(2, '0'),
                        style: const TextStyle(fontSize: 78, color: Colors.white70),
                      ),
                    ),
                    const Text(':', style: TextStyle(fontSize: 78, color: Colors.white70)),
                    GestureDetector(
                      onTap: () => _showNumberPicker('minutes'),
                      child: Text(
                        _minutes.toString().padLeft(2, '0'),
                        style: const TextStyle(fontSize: 78, color: Colors.white70),
                      ),
                    ),
                    const Text(':', style: TextStyle(fontSize: 78, color: Colors.white70)),
                    GestureDetector(
                      onTap: () => _showNumberPicker('seconds'),
                      child: Text(
                        _seconds.toString().padLeft(2, '0'),
                        style: const TextStyle(fontSize: 78, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _formatTime(_remaining),
                      style: const TextStyle(fontSize: 32, color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                ElevatedButton(
                  onPressed: _remaining.inSeconds > 0 ? _startTimer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    elevation: 20,
                    shadowColor: Colors.cyanAccent.withOpacity(0.8),
                  ),
                  child: const Text('Iniciar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 70),
              ] else ...[
                const Spacer(),
                SizedBox(
                  width: 340,
                  height: 340,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _circleAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(340, 340),
                            painter: CircleProgressPainter(progress: 1 - _circleAnimation.value),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(_remaining),
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              shadows: [
                                Shadow(color: Colors.cyanAccent, blurRadius: 30),
                                Shadow(color: Colors.cyanAccent, blurRadius: 60),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Termina: ${_getEndTimeText()}',
                            style: const TextStyle(
                              fontSize: 26,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _getPeriodText(),
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _resetTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.cyanAccent,
                            side: const BorderSide(color: Colors.cyanAccent, width: 3),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(50)),
                            ),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isRunning ? _pauseTimer : _resumeTimer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(50)),
                            ),
                            elevation: 20,
                            shadowColor: Colors.cyanAccent.withOpacity(0.9),
                          ),
                          child: Text(
                            _isRunning ? 'Pausar' : 'Reanudar',
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ========================================
// CLASES AUXILIARES (sin cambios)
// ========================================

class CircleProgressPainter extends CustomPainter {
  final double progress;

  CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.amber, Colors.yellowAccent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NumberPickerSheet extends StatefulWidget {
  final int initial;
  final int max;
  final String title;

  const NumberPickerSheet({
    required this.initial,
    required this.max,
    required this.title,
    super.key,
  });

  @override
  State<NumberPickerSheet> createState() => _NumberPickerSheetState();
}

class _NumberPickerSheetState extends State<NumberPickerSheet> {
  late FixedExtentScrollController _controller;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _controller = FixedExtentScrollController(initialItem: _current);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      color: Colors.black87,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          Expanded(
            child: ListWheelScrollView.useDelegate(
              controller: _controller,
              itemExtent: 60,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) => setState(() => _current = index),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.max + 1,
                builder: (context, index) {
                  return Center(
                    child: Text(
                      index.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 48,
                        color: index == _current ? Colors.cyanAccent : Colors.white54,
                        fontWeight: index == _current ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.orange, fontSize: 18)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _current),
                  child: const Text('Aceptar', style: TextStyle(color: Colors.cyanAccent, fontSize: 18)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}