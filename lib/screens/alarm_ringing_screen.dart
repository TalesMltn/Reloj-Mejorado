// lib/screens/alarm_ringing_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../widgets/bubble_animation.dart';

class AlarmRingingScreen extends StatefulWidget {
  final String alarmLabel;
  final VoidCallback onStop;   // Función para detener la alarma y el sonido
  final VoidCallback onSnooze; // Función para aplazar 5 minutos

  const AlarmRingingScreen({
    super.key,
    required this.alarmLabel,
    required this.onStop,
    required this.onSnooze,
  });

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  VideoPlayerController? _videoController;

  static const String _backgroundVideo = 'assets/videos/fox_autumn_5.mp4';

  late tz.Location _limaLocation;
  Timer? _timeTimer;
  String _currentTime = '';
  String _currentPeriod = '';

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _limaLocation = tz.getLocation('America/Lima');

    _loadBackground();
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _loadBackground() {
    _videoController = VideoPlayerController.asset(_backgroundVideo)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _videoController!
            ..setLooping(true)
            ..setVolume(0.0)
            ..play();
        });
      }).catchError((error) {
        debugPrint('Error cargando fondo de alarma: $error');
      });
  }

  void _updateTime() {
    final now = tz.TZDateTime.now(_limaLocation);
    final timeStr = DateFormat('h:mm').format(now);
    final period = DateFormat('a').format(now).toLowerCase();

    setState(() {
      _currentTime = timeStr;
      _currentPeriod = period;
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo negro por seguridad
          Container(color: Colors.black),

          // Video de fondo: fox_autumn_5.mp4
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

          // Capa oscura suave
          Container(color: Colors.black.withOpacity(0.4)),

          // Muchas burbujas mágicas
          ...List.generate(120, (_) => const BubbleAnimation()),

          // Contenido principal
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(height: 40),

                // Hora grande y brillante
                Column(
                  children: [
                    Text(
                      _currentTime,
                      style: TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent,
                        shadows: const [
                          Shadow(color: Colors.cyanAccent, blurRadius: 20),
                          Shadow(color: Colors.cyanAccent, blurRadius: 40),
                          Shadow(color: Colors.cyanAccent, blurRadius: 60),
                        ],
                      ),
                    ),
                    Text(
                      _currentPeriod,
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),

                // Nombre de la alarma
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.alarmLabel.isNotEmpty ? widget.alarmLabel : '¡Es hora!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Botones grandes y bonitos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    children: [
                      // Botón Aplazar (estilo secundario)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onSnooze,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange, width: 3),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 10,
                            shadowColor: Colors.orange.withOpacity(0.5),
                          ),
                          child: const Text(
                            'Aplazar 5 min',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      const SizedBox(width: 30),

                      // Botón Detener (estilo principal cyan neon)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onStop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 20,
                            shadowColor: Colors.cyanAccent.withOpacity(0.9),
                          ),
                          child: const Text(
                            'Detener',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}