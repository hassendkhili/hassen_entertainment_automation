import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'dart:convert';

import '../models/activity_model.dart';

class GoldGradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const GoldGradientText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          Color(0xFFBF953F),
          Color(0xFFFCF6BA),
          Color(0xFFB38728),
          Color(0xFFFBF5B7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: Text(
        text,
        style: style?.copyWith(color: Colors.white) ?? const TextStyle(color: Colors.white),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentTime = "";
  List<ActivitySchedule> _schedules = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _loadData();

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playingIndex = null;
        });
      }
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
        _checkAndPlayAudio();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = _schedules.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList('hotel_schedules', data);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? data = prefs.getStringList('hotel_schedules');
    if (data != null) {
      setState(() {
        _schedules = data.map((item) => ActivitySchedule.fromMap(jsonDecode(item))).toList();
      });
    }
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  void _checkAndPlayAudio() {
    String nowFormatted = DateFormat('HH:mm').format(DateTime.now());
    for (int i = 0; i < _schedules.length; i++) {
      var activity = _schedules[i];
      if (activity.time == nowFormatted && !activity.hasPlayed && activity.filePath != null) {
        _playMusic(activity.filePath!, i);
        activity.hasPlayed = true;
      } else if (activity.time != nowFormatted) {
        activity.hasPlayed = false;
      }
    }
  }

  Future<void> _playMusic(String path, int index) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
      if (mounted) {
        setState(() {
          _playingIndex = index;
        });
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  void _stopUrgent() async {
    await _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _playingIndex = null;
      });
    }
  }

  void _openActivityDialog({ActivitySchedule? existingActivity, int? index}) {
    TextEditingController nameController = TextEditingController(text: existingActivity?.name ?? "");
    String selectedTime = existingActivity?.time ?? "08:00";
    String? path = existingActivity?.filePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: GoldGradientText(
            existingActivity == null ? "Add New Schedule" : "Edit Schedule",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Activity Name",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 15),
              ListTile(
                title: GoldGradientText("Time: $selectedTime", style: const TextStyle(fontSize: 16)),
                trailing: const Icon(Icons.access_time, color: Color(0xFFD4AF37)),
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedTime = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                    });
                  }
                },
              ),
              ElevatedButton.icon(
                icon: Lottie.asset('assets/lottie/add_song.json', width: 30, height: 30),
                label: Text(path == null ? "Select MP3" : "File Selected", style: const TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                onPressed: () async {
                  FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (r != null) setDialogState(() => path = r.files.single.path);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.white54))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    if (existingActivity == null) {
                      _schedules.add(ActivitySchedule(name: nameController.text, time: selectedTime, filePath: path));
                    } else {
                      _schedules[index!] = ActivitySchedule(name: nameController.text, time: selectedTime, filePath: path);
                    }
                  });
                  _saveData();
                  Navigator.pop(context);
                }
              },
              child: Text(existingActivity == null ? "Add" : "Save", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const GoldGradientText(
            "H@sSen_Automation",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)
        ),
      ),
      body: Column(
        children: [
          // ⬅️ الهيكل المدمج والمنظف لساعة الـ Dashboard والـ Visualizer
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: _playingIndex != null
                      ? Lottie.asset('assets/lottie/Audio visualizer.json', height: 150, repeat: true)
                      : null,
                ),
                GoldGradientText(
                    _currentTime,
                    style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold)
                ),
                const SizedBox(width: 150),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: ListView.builder(
              itemCount: _schedules.length,
              itemBuilder: (context, i) => ListTile(
                leading: Lottie.asset('assets/lottie/alarm.json', width: 45, height: 45),
                title: GoldGradientText(_schedules[i].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text("At ${_schedules[i].time}", style: const TextStyle(color: Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Lottie.asset('assets/lottie/stop.json', width: 35, height: 35),
                      onPressed: _stopUrgent,
                    ),
                    IconButton(
                      icon: Lottie.asset('assets/lottie/edit.json', width: 35, height: 35),
                      onPressed: () => _openActivityDialog(existingActivity: _schedules[i], index: i),
                    ),
                    IconButton(
                      icon: Lottie.asset('assets/lottie/remove.json', width: 35, height: 35),
                      onPressed: () {
                        if (_playingIndex == i) _stopUrgent();
                        setState(() => _schedules.removeAt(i));
                        _saveData();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openActivityDialog(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Lottie.asset('assets/lottie/add_activity.json', width: 70, height: 70),
      ),
    );
  }
}