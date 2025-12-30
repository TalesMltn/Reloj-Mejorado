// lib/screens/world_clock_screen.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/bubble_animation.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;  // ← Mantiene viva la pantalla

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

  late final List<String> _allZones;
  String _searchQuery = '';

  List<Map<String, String>> _addedCities = [
    {'name': 'Lima', 'zone': 'America/Lima'},
  ];

  late SharedPreferences _prefs;

  Timer? _timer;
  String _mainTime = '';
  String _mainPeriod = '';

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _allZones = tz.timeZoneDatabase.locations.keys.toList()..sort();

    _loadBackground(_currentFondoIndex);
    _loadCitiesFromPreferences();
    _updateMainTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateMainTime());
  }

  // Cargar ciudades guardadas
  Future<void> _loadCitiesFromPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final String? citiesJson = _prefs.getString('added_cities');

    if (citiesJson != null && citiesJson.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(citiesJson);
      setState(() {
        _addedCities = decoded.map((e) => {
          'name': e['name'] as String,
          'zone': e['zone'] as String,
        }).toList();
      });
    }
    // Si por algún motivo está vacío, aseguramos tener al menos Lima
    if (_addedCities.isEmpty) {
      _addedCities = [{'name': 'Lima', 'zone': 'America/Lima'}];
      await _saveCitiesToPreferences();
    }
  }

  // Guardar ciudades cada vez que cambien
  Future<void> _saveCitiesToPreferences() async {
    final String citiesJson = jsonEncode(_addedCities);
    await _prefs.setString('added_cities', citiesJson);
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

  void _updateMainTime() {
    if (_addedCities.isEmpty) return;
    final location = tz.getLocation(_addedCities.first['zone']!);
    final now = tz.TZDateTime.now(location);

    final timeStr = DateFormat('h:mm:ss').format(now);
    final period = DateFormat('a').format(now).toLowerCase();

    setState(() {
      _mainTime = timeStr;
      _mainPeriod = period;
    });
  }

  String _formatCityTime(String zone) {
    final location = tz.getLocation(zone);
    final time = tz.TZDateTime.now(location);
    return DateFormat('h:mm a').format(time).toLowerCase().replaceAll('.', '');
  }

  void _openCitySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredZones = _allZones.where((zone) {
              final name = zone.split('/').last.replaceAll('_', ' ');
              return name.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              minChildSize: 0.6,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Buscar ciudad o país...',
                          hintStyle: TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.search, color: Colors.cyanAccent),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() => _searchQuery = value);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: filteredZones.length,
                        itemBuilder: (context, index) {
                          final zone = filteredZones[index];
                          final name = zone.split('/').last.replaceAll('_', ' ');
                          final alreadyAdded = _addedCities.any((c) => c['zone'] == zone);

                          return ListTile(
                            title: Text(
                              name,
                              style: const TextStyle(fontSize: 20, color: Colors.cyanAccent),
                            ),
                            subtitle: Text(
                              zone,
                              style: const TextStyle(fontSize: 14, color: Colors.white60),
                            ),
                            trailing: Icon(
                              alreadyAdded ? Icons.remove_circle : Icons.add_circle,
                              color: alreadyAdded ? Colors.redAccent : Colors.cyanAccent,
                              size: 30,
                            ),
                            onTap: () async {
                              setState(() {
                                if (alreadyAdded) {
                                  _addedCities.removeWhere((c) => c['zone'] == zone);
                                } else {
                                  _addedCities.add({'name': name, 'zone': zone});
                                }
                              });
                              await _saveCitiesToPreferences();  // Guardar inmediatamente
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ).whenComplete(() => setState(() => _searchQuery = ''));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);  // ← REQUERIDO por KeepAlive

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
        Container(color: Colors.black.withOpacity(0.6)),
        ...List.generate(120, (_) => const BubbleAnimation()),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Text(
                      _mainTime,
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
                      _mainPeriod,
                      style: const TextStyle(fontSize: 40, color: Colors.cyanAccent, fontWeight: FontWeight.w300),
                    ),
                    Text(
                      'hora estándar de ${_addedCities.isNotEmpty ? _addedCities.first['name'] : 'Lima'}',
                      style: const TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _openCitySelector,
                    child: const Text('+', style: TextStyle(fontSize: 42, color: Colors.cyanAccent)),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _addedCities.length,
                  itemBuilder: (context, index) {
                    final city = _addedCities[index];
                    final cityTime = _formatCityTime(city['zone']!);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            city['name']!,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              Text(
                                cityTime,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 30),
                                onPressed: () async {
                                  setState(() {
                                    _addedCities.removeAt(index);
                                  });
                                  await _saveCitiesToPreferences();  // Guardar al eliminar
                                },
                              ),
                            ],
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
      ],
    );
  }
}