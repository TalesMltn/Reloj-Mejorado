// lib/alarm_service.dart
import 'dart:convert';

import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import 'screens/alarm_ringing_screen.dart';

final AudioPlayer _audioPlayer = AudioPlayer();

// Callback principal que se ejecuta cuando suena la alarma
@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  // params siempre tiene valores por defecto si no vienen
  final String soundPath = params['sound'] ?? 'assets/sounds/Aud1.mp3';
  final String label = params['label'] ?? '¡Es hora!';

  // Reproducir sonido en loop
  await _audioPlayer.setAsset(soundPath);
  _audioPlayer.setLoopMode(LoopMode.one);
  await _audioPlayer.play();

  // Abrir la pantalla personalizada inmediatamente
  await AndroidAlarmManager.oneShot(
    const Duration(seconds: 0),
    id + 100000,
    showRingingScreen,
    exact: true,
    wakeup: true,
    alarmClock: true,
    allowWhileIdle: true,
    params: {
      'label': label,
      'originalId': id,
      'sound': soundPath,
    },
  );
}

// Función que lanza tu pantalla mágica
@pragma('vm:entry-point')
void showRingingScreen(int id, Map<String, dynamic> params) {
  WidgetsFlutterBinding.ensureInitialized();

  final String label = params['label'] ?? '¡Es hora!';
  final int originalId = params['originalId'] ?? id;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: AlarmRingingScreen(
        alarmLabel: label,
        onStop: () async {
          await _audioPlayer.stop();
        },
        onSnooze: () async {
          await _audioPlayer.stop();
          final newTime = DateTime.now().add(const Duration(minutes: 5));
          await AndroidAlarmManager.oneShotAt(
            newTime,
            originalId,
            alarmCallback,
            exact: true,
            wakeup: true,
            alarmClock: true,
            allowWhileIdle: true,
            params: params,
          );
        },
      ),
    ),
  );
}

// Funciones auxiliares
Future<void> stopAlarm() async {
  await _audioPlayer.stop();
}

Future<void> snoozeAlarm(int originalId, Map<String, dynamic> params) async {
  await _audioPlayer.stop();
  final newTime = DateTime.now().add(const Duration(minutes: 5));
  await AndroidAlarmManager.oneShotAt(
    newTime,
    originalId,
    alarmCallback,
    exact: true,
    wakeup: true,
    alarmClock: true,
    allowWhileIdle: true,
    params: params,
  );
}