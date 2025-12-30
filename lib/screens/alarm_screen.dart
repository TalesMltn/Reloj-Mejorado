// lib/screens/alarm_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../widgets/bubble_animation.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  VideoPlayerController? _videoController;

  // ¡Nombres seguros sin emojis!
  final List<String> _localFondos = [
    'assets/videos/fox_autumn_1.mp4',
    'assets/videos/fox_autumn_2.mp4',
    'assets/videos/fox_autumn_3.mp4',
    'assets/videos/fox_autumn_4.mp4',
    'assets/videos/fox_autumn_5.mp4',
    'assets/videos/fox_autumn_6.mp4',
    'assets/videos/fox_autumn_7.mp4',
  ];

  int _currentFondoIndex = 0;
  Timer? _backgroundTimer;

  final List<Map<String, dynamic>> _alarms = [];

  String _nextAlarmText = '';
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _loadBackground(_currentFondoIndex);

    // Cambia de fondo cada 30 segundos
    _backgroundTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {
        _currentFondoIndex = (_currentFondoIndex + 1) % _localFondos.length;
      });
      _loadBackground(_currentFondoIndex);
    });

    // Actualiza texto de próxima alarma cada 30 segundos
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateNextAlarm());
    _updateNextAlarm();
  }

  void _loadBackground(int index) {
    _videoController?.dispose();
    final String videoPath = _localFondos[index];

    _videoController = VideoPlayerController.asset(videoPath)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _videoController!
            ..setLooping(true)
            ..setVolume(0.0)
            ..play();
        });
      }).catchError((error) {
        debugPrint('Error cargando video $videoPath: $error');
        // Si falla un video, pasa al siguiente
        if (mounted) {
          setState(() {
            _currentFondoIndex = (_currentFondoIndex + 1) % _localFondos.length;
          });
          _loadBackground(_currentFondoIndex);
        }
      });
  }

  void _updateNextAlarm() {
    final activeAlarms = _alarms.where((a) => a['active'] == true).toList();

    if (activeAlarms.isEmpty) {
      setState(() => _nextAlarmText = '');
      return;
    }

    // Aquí más adelante pondrás el cálculo real con DateTime.now()
    setState(() {
      _nextAlarmText = 'Alarma dentro de 17 horas 49 minutos\nmar. 30 dic. 8:50 a.m.';
    });
  }

  void _addTestAlarm() {
    setState(() {
      _alarms.add({
        'time': '8:50',
        'subTime': 'AM',
        'label': 'Despertar para el día',
        'sublabel': 'Todos los días',
        'icons': ['🌅', '☀️'],
        'active': true,
      });
    });
    _updateNextAlarm();
  }

  @override
  void dispose() {
    _backgroundTimer?.cancel();
    _updateTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo negro por defecto
          Container(color: Colors.black),

          // Video de fondo (solo si está inicializado)
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

          // Capa oscura semi-transparente
          Container(color: Colors.black.withOpacity(0.5)),

          // Burbujas animadas
          ...List.generate(60, (_) => const BubbleAnimation()), // Bajado a 60 para mejor rendimiento

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Texto de próxima alarma
                if (_nextAlarmText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Text(
                      _nextAlarmText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),

                // Mensaje cuando no hay alarmas
                if (_alarms.isEmpty && _nextAlarmText.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No hay alarmas configuradas',
                        style: TextStyle(fontSize: 24, color: Colors.white60),
                      ),
                    ),
                  ),

                // Lista de alarmas
                if (_alarms.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: _alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        alarm['time'] ?? '??:??',
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (alarm['icons'] != null)
                                        ...List<Widget>.from(
                                          (alarm['icons'] as List).map(
                                                (icon) => Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Text(icon, style: const TextStyle(fontSize: 28)),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (alarm['subTime'] != null)
                                    Text(
                                      alarm['subTime'],
                                      style: const TextStyle(fontSize: 32, color: Colors.white70),
                                    ),
                                  if (alarm['sublabel'] != null)
                                    Text(
                                      alarm['sublabel'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white60,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  Text(
                                    alarm['label'] ?? '',
                                    style: const TextStyle(fontSize: 18, color: Colors.orange),
                                  ),
                                ],
                              ),
                              Switch(
                                value: alarm['active'] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    alarm['active'] = value;
                                  });
                                  _updateNextAlarm();
                                },
                                activeColor: Colors.cyan,
                                inactiveTrackColor: Colors.grey.withOpacity(0.5),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Botón + funcional (agrega alarma de prueba)
          Positioned(
            top: 80,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              onPressed: _addTestAlarm, // ¡Ahora sí agrega alarmas!
              child: const Icon(Icons.add, size: 40, color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }
}