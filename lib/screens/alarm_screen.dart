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

  // Lista vacía al inicio - se llenará cuando crees alarmas
  final List<Map<String, dynamic>> _alarms = [];

  String _nextAlarmText = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBackground(_currentFondoIndex);
    _updateNextAlarm();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _updateNextAlarm()); // Actualiza cada 30 segundos
  }

  void _loadBackground(int index) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.asset(_localFondos[index])
      ..initialize().then((_) {
        _videoController!.play();
        _videoController!.setLooping(true);
        _videoController!.setVolume(0);
        if (mounted) setState(() {});
      }).catchError((error) {
        debugPrint('Error cargando video: $error');
      });
  }

  void _updateNextAlarm() {
    final activeAlarms = _alarms.where((a) => a['active'] == true).toList();

    if (activeAlarms.isEmpty) {
      setState(() {
        _nextAlarmText = '';
      });
      return;
    }

    // Simulación del tiempo restante (puedes mejorarlo con DateTime real más adelante)
    setState(() {
      _nextAlarmText = 'Alarma dentro de 17 horas 49 minutos\nmar. 30 de dic. 8:50 a. m.';
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
        ...List.generate(100, (_) => const BubbleAnimation()),

        SafeArea(
          child: Column(
            children: [
              // Mensaje de tiempo restante (solo si hay alarma activa)
              if (_nextAlarmText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text(
                    _nextAlarmText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, color: Colors.white70),
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

              // Lista de alarmas (solo se muestran las creadas)
              if (_alarms.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                    Text(alarm['time'], style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600)),
                                    if (alarm['icons'] != null)
                                      ...alarm['icons'].map((icon) => Text(icon, style: const TextStyle(fontSize: 28))).toList(),
                                  ],
                                ),
                                if (alarm['subTime'] != null)
                                  Text(alarm['subTime'], style: const TextStyle(fontSize: 32, color: Colors.white70)),
                                if (alarm['sublabel'] != null)
                                  Text(alarm['sublabel'], style: const TextStyle(fontSize: 16, color: Colors.white60, fontStyle: FontStyle.italic)),
                                Text(alarm['label'] ?? '', style: const TextStyle(fontSize: 18, color: Colors.orange)),
                              ],
                            ),
                            Switch(
                              value: alarm['active'] ?? false,
                              onChanged: (v) {
                                setState(() {
                                  alarm['active'] = v;
                                });
                                _updateNextAlarm();
                              },
                              activeColor: Colors.cyan,
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

        // Botón + para crear nueva alarma
        Positioned(
          top: 80,
          right: 30,
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () {
              // Aquí navegarás a la pantalla de configuración cuando la tengas
              // Navigator.push(context, MaterialPageRoute(builder: (_) => ConfigScreen(...)));
            },
            child: const Icon(Icons.add, size: 40, color: Colors.cyanAccent),
          ),
        ),
      ],
    );
  }
}