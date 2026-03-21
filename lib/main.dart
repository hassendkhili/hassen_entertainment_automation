import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart'; // المكتبة الجديدة
import 'dart:async';
import 'dart:convert'; // لتحويل البيانات إلى نصوص

void main() => runApp(const HotelAutomationApp());

class HotelAutomationApp extends StatelessWidget {
  const HotelAutomationApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, primaryColor: Colors.cyanAccent),
      home: const DashboardScreen(),
    );
  }
}

class ActivitySchedule {
  String name;
  String time;
  String? filePath;
  bool hasPlayed;

  ActivitySchedule({required this.name, required this.time, this.filePath, this.hasPlayed = false});

  // تحويل الكائن إلى Map ليتم حفظه
  Map<String, dynamic> toMap() => {
    'name': name,
    'time': time,
    'filePath': filePath,
  };

  // استرجاع الكائن من Map
  factory ActivitySchedule.fromMap(Map<String, dynamic> map) => ActivitySchedule(
    name: map['name'],
    time: map['time'],
    filePath: map['filePath'],
  );
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

  @override
  void initState() {
    super.initState();
    _loadData(); // تحميل البيانات عند فتح التطبيق
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
      _checkAndPlayAudio();
    });
  }

  // --- دالات الحفظ والتحميل ---
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
    for (var activity in _schedules) {
      if (activity.time == nowFormatted && !activity.hasPlayed && activity.filePath != null) {
        _playMusic(activity.filePath!);
        activity.hasPlayed = true;
      } else if (activity.time != nowFormatted) {
        activity.hasPlayed = false;
      }
    }
  }

  Future<void> _playMusic(String path) async {
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e) {
      print("Error: $e");
    }
  }

  void _stopUrgent() async => await _audioPlayer.stop();

  void _openActivityDialog({ActivitySchedule? existingActivity, int? index}) {
    TextEditingController nameController = TextEditingController(text: existingActivity?.name ?? "");
    String selectedTime = existingActivity?.time ?? "08:00";
    String? path = existingActivity?.filePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingActivity == null ? "Add New Schedule" : "Edit Schedule"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: "Activity Name")),
              const SizedBox(height: 15),
              ListTile(
                title: Text("Time: $selectedTime"),
                trailing: const Icon(Icons.access_time),
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
                icon: const Icon(Icons.audio_file),
                label: Text(path == null ? "Select MP3" : "File Selected"),
                onPressed: () async {
                  FilePickerResult? r = await FilePicker.platform.pickFiles(type: FileType.audio);
                  if (r != null) setDialogState(() => path = r.files.single.path);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    if (existingActivity == null) {
                      _schedules.add(ActivitySchedule(name: nameController.text, time: selectedTime, filePath: path));
                    } else {
                      _schedules[index!] = ActivitySchedule(name: nameController.text, time: selectedTime, filePath: path);
                    }
                  });
                  _saveData(); // حفظ بعد الإضافة أو التعديل
                  Navigator.pop(context);
                }
              },
              child: Text(existingActivity == null ? "Add" : "Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Maestro Automation"),
        actions: [IconButton(icon: const Icon(Icons.block, color: Colors.redAccent), onPressed: _stopUrgent)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(_currentTime, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _schedules.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.alarm, color: Colors.cyanAccent),
                title: Text(_schedules[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("At ${_schedules[i].time}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.stop_circle, color: Colors.orange), onPressed: _stopUrgent),
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openActivityDialog(existingActivity: _schedules[i], index: i)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() => _schedules.removeAt(i));
                        _saveData(); // حفظ بعد الحذف
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openActivityDialog(), child: const Icon(Icons.add)),
    );
  }
}