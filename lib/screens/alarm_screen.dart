// lib/screens/alarm_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'alarm_ringing_screen.dart';
import '../widgets/bubble_animation.dart';
import '../alarm_service.dart'; // ← Tu nuevo servicio de alarma

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  VideoPlayerController? _videoController;

  static const String _mainBackground = 'assets/videos/fox_autumn_5.mp4';

  final List<String> _randomBackgrounds = [
    'assets/videos/fox_autumn_1.mp4',
    'assets/videos/fox_autumn_2.mp4',
    'assets/videos/fox_autumn_3.mp4',
    'assets/videos/fox_autumn_4.mp4',
  ];

  late String _currentBackground;
  Timer? _backgroundTimer;

  final List<Map<String, dynamic>> _alarms = [];

  String _nextAlarmText = '';
  Timer? _updateTimer;

  final Random _random = Random();

  static const String _limaZone = 'America/Lima';
  late tz.Location _limaLocation;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _limaLocation = tz.getLocation(_limaZone);

    _currentBackground = _mainBackground;
    _loadBackground(_currentBackground);

    _backgroundTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final String newRandom = _randomBackgrounds[_random.nextInt(_randomBackgrounds.length)];
      if (newRandom != _currentBackground) {
        setState(() => _currentBackground = newRandom);
        _loadBackground(_currentBackground);
      }
    });

    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateNextAlarm());
    _updateNextAlarm();
  }

  void _loadBackground(String videoPath) {
    _videoController?.dispose();
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
        debugPrint('Error cargando video: $error');
      });
  }

  void _updateNextAlarm() {
    final now = tz.TZDateTime.now(_limaLocation);
    final activeAlarms = _alarms.where((a) => a['active'] == true).toList();

    if (activeAlarms.isEmpty) {
      setState(() => _nextAlarmText = '');
      return;
    }

    DateTime? nearestAlarm;
    Duration? shortestDuration;

    for (var alarm in activeAlarms) {
      final hour = alarm['hour'] as int;
      final minute = alarm['minute'] as int;

      DateTime candidate = tz.TZDateTime(_limaLocation, now.year, now.month, now.day, hour, minute);

      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }

      final duration = candidate.difference(now);

      if (shortestDuration == null || duration < shortestDuration) {
        shortestDuration = duration;
        nearestAlarm = candidate;
      }
    }

    if (nearestAlarm != null && shortestDuration != null) {
      final hours = shortestDuration.inHours;
      final minutes = shortestDuration.inMinutes % 60;
      final timeText = hours > 0 ? '$hours horas $minutes minutos' : '$minutes minutos';
      final dateText = DateFormat('EEE. d MMM. h:mm a', 'es_ES').format(nearestAlarm).toLowerCase();

      setState(() {
        _nextAlarmText = 'Alarma dentro de $timeText\n$dateText';
      });
    }
  }

  void _showAddAlarmDialog([Map<String, dynamic>? existingAlarm, int? index]) {
    final bool isEditing = existingAlarm != null;

    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      existingAlarm != null
          ? DateTime(2025, 1, 1, existingAlarm['hour'], existingAlarm['minute'])
          : DateTime.now(),
    );

    String label = existingAlarm?['label'] ?? '';
    List<bool> repeatDays = List.from(existingAlarm?['repeatDays'] ?? List.filled(7, false));
    String sound = existingAlarm?['sound'] ?? 'Aud1.mp3';
    bool vibrate = existingAlarm?['vibrate'] ?? true;
    String snooze = existingAlarm?['snooze'] ?? '5 minutos, 3 veces';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 6,
                          shadowColor: Colors.orange.withOpacity(0.3),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Text(
                        isEditing ? 'Editar alarma' : 'Nueva alarma',
                        style: TextStyle(fontSize: 20, color: Colors.cyanAccent.withOpacity(0.7), fontWeight: FontWeight.w500),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final newAlarm = {
                            'time': selectedTime.format(context),
                            'hour': selectedTime.hour,
                            'minute': selectedTime.minute,
                            'label': label,
                            'repeatDays': repeatDays,
                            'sound': sound,
                            'vibrate': vibrate,
                            'snooze': snooze,
                            'active': true,
                          };

                          if (index != null) {
                            setState(() => _alarms[index] = newAlarm);
                          } else {
                            setState(() => _alarms.add(newAlarm));
                          }
                          _updateNextAlarm();

                          DateTime scheduledDate = DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          if (scheduledDate.isBefore(DateTime.now())) {
                            scheduledDate = scheduledDate.add(const Duration(days: 1));
                          }

                          final int alarmId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

                          await AndroidAlarmManager.oneShotAt(
                            scheduledDate,
                            alarmId,
                            alarmCallback,
                            exact: true,
                            wakeup: true,
                            alarmClock: true,
                            allowWhileIdle: true,
                            rescheduleOnReboot: true,
                            params: {
                              'sound': sound,
                              'label': label,
                            },
                          );

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                          shadowColor: Colors.cyanAccent.withOpacity(0.7),
                        ),
                        child: const Text('Guardar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              primaryColor: Colors.cyanAccent,
                              colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setSheetState(() => selectedTime = picked);
                      },
                      child: Text(
                        selectedTime.format(context),
                        style: const TextStyle(fontSize: 72, color: Colors.white, fontWeight: FontWeight.w300),
                      ),
                    ),
                  ),
                ),

                const Divider(color: Colors.white24),

                Expanded(
                  flex: 3,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      ListTile(
                        title: const Text('Nombre de alarma', style: TextStyle(color: Colors.white70)),
                        subtitle: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Despertar, Trabajo, etc.',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                          onChanged: (value) => label = value,
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      ListTile(
                        title: const Text('Repetir', style: TextStyle(color: Colors.white)),
                        subtitle: Text(_getRepeatText(repeatDays)),
                        onTap: () => _showRepeatDialog(setSheetState, repeatDays),
                      ),
                      const Divider(color: Colors.white24),
                      ListTile(
                        title: const Text('Sonido de alarma', style: TextStyle(color: Colors.white)),
                        subtitle: Text(sound.replaceAll('.mp3', '')),
                        onTap: () => _showSoundPicker(setSheetState, (newSound) => sound = newSound),
                      ),
                      const Divider(color: Colors.white24),
                      ListTile(
                        title: const Text('Vibración', style: TextStyle(color: Colors.white)),
                        trailing: Switch(
                          value: vibrate,
                          onChanged: (val) => setSheetState(() => vibrate = val),
                          activeColor: Colors.cyanAccent,
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      ListTile(
                        title: const Text('Aplazar', style: TextStyle(color: Colors.white)),
                        subtitle: Text(snooze),
                        onTap: () => _showSnoozeOptions(setSheetState, (val) => snooze = val),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getRepeatText(List<bool> days) {
    const dayNames = ['D', 'L', 'M', 'X', 'J', 'V', 'S'];
    if (days.every((d) => !d)) return 'Una vez';
    if (days.every((d) => d)) return 'Diariamente';
    return days.asMap().entries.where((e) => e.value).map((e) => dayNames[e.key]).join(', ');
  }

  void _showRepeatDialog(StateSetter setSheetState, List<bool> days) {
    const dayNames = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Repetir', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (i) => CheckboxListTile(
            title: Text(dayNames[i], style: const TextStyle(color: Colors.white70)),
            value: days[i],
            onChanged: (val) => setSheetState(() => days[i] = val!),
            activeColor: Colors.cyanAccent,
          )),
        ),
      ),
    );
  }

  void _showSoundPicker(StateSetter setSheetState, Function(String) onSelected) {
    final sounds = List.generate(15, (i) => 'Aud${i + 1}.mp3');
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      builder: (context) => ListView.builder(
        itemCount: sounds.length,
        itemBuilder: (context, i) => ListTile(
          title: Text(sounds[i].replaceAll('.mp3', ''), style: const TextStyle(color: Colors.white)),
          onTap: () {
            setSheetState(() => onSelected(sounds[i]));
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showSnoozeOptions(StateSetter setSheetState, Function(String) onSelected) {
    final options = ['Sin aplazar', '5 minutos, 3 veces', '10 minutos, 5 veces', '15 minutos, ilimitado'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      builder: (context) => ListView.builder(
        itemCount: options.length,
        itemBuilder: (context, i) => ListTile(
          title: Text(options[i], style: const TextStyle(color: Colors.white)),
          onTap: () {
            setSheetState(() => onSelected(options[i]));
            Navigator.pop(context);
          },
        ),
      ),
    );
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
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
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
          ...List.generate(80, (_) => const BubbleAnimation()),
          SafeArea(
            child: Column(
              children: [
                if (_nextAlarmText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Text(_nextAlarmText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, color: Colors.white70, height: 1.5)),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: _alarms.isEmpty
                      ? const Center(child: Text('No hay alarmas configuradas', style: TextStyle(fontSize: 22, color: Colors.white60)))
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _alarms.length,
                    itemBuilder: (context, index) {
                      final alarm = _alarms[index];
                      return Card(
                        color: Colors.white.withOpacity(0.12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          title: Text(alarm['time'], style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.w300)),
                          subtitle: alarm['label'].isNotEmpty ? Text(alarm['label'], style: const TextStyle(color: Colors.orange, fontSize: 18)) : null,
                          trailing: Switch(
                            value: alarm['active'],
                            onChanged: (val) {
                              setState(() => alarm['active'] = val);
                              _updateNextAlarm();
                            },
                            activeColor: Colors.cyanAccent,
                          ),
                          onTap: () => _showAddAlarmDialog(alarm, index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 100,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.cyanAccent.withOpacity(0.9),
              elevation: 10,
              child: const Icon(Icons.add, size: 36),
              onPressed: () => _showAddAlarmDialog(),
            ),
          ),
          // Botón de prueba (temporal)
         /* Positioned(
            bottom: 180,
            right: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.volume_up),
              onPressed: () async {
                final String testPayload = jsonEncode({
                  'sound': 'Aud5.mp3',
                  'label': '¡Prueba de alarma!',
                });

                await AndroidAlarmManager.oneShot(
                  const Duration(seconds: 15),
                  999,
                  alarmCallback,
                  exact: true,
                  wakeup: true,
                  alarmClock: true,
                  allowWhileIdle: true,
                  rescheduleOnReboot: true,
                  params: {
                    'sound': 'assets/sounds/Aud5.mp3',
                    'label': '¡Prueba de alarma!',
                  },
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prueba: alarma en 15 segundos')),
                );
              },
            ),
          ),*/
        ],
      ),
    );
  }
}