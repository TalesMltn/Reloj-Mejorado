// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'screens/alarm_screen.dart';
import 'screens/world_clock_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/timer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa formato de fecha en español
  await initializeDateFormatting('es_ES');

  // Inicializa zonas horarias
  tz.initializeTimeZones();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Despertador Náutico 🦊🍂',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Empieza en Reloj Mundial (índice 1)

  // Lista de pantallas (se crean una sola vez)
  static const List<Widget> _screens = [
    AlarmScreen(),
    WorldClockScreen(),
    StopwatchScreen(),
    TimerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(  // ← CAMBIO CLAVE: IndexedStack en vez de PageView
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarma'),
            BottomNavigationBarItem(icon: Icon(Icons.language), label: 'Reloj Mundial'),
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Cronómetro'),
            BottomNavigationBarItem(icon: Icon(Icons.hourglass_bottom), label: 'Temporizador'),
          ],
        ),
      ),
    );
  }
}