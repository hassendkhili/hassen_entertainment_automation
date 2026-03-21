import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';

void main() {
  runApp(const HotelAutomationApp());
}

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

// Model لتمثيل الفعالية الصباحية
class ActivitySchedule {
  String name;
  String time;
  String? filePath;

  ActivitySchedule({required this.name, required this.time, this.filePath});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentTime = "";
  String _currentDay = "";
  List<ActivitySchedule> _schedules = []; // قائمة المواعيد

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentDay = DateFormat('EEEE').format(now);
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  // وظيفة لفتح نافذة إضافة موعد جديد
  void _addNewActivity() {
    String name = "";
    String time = "";
    String? path;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Activity"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: "Activity Name (e.g. Yoga)"),
              onChanged: (value) => name = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: "Time (HH:mm)"),
              onChanged: (value) => time = value,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.audio_file),
              label: const Text("Select MP3 File"),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
                if (result != null) path = result.files.single.path;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty && time.isNotEmpty) {
                setState(() {
                  _schedules.add(ActivitySchedule(name: name, time: time, filePath: path));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Maestro Hotel Automation")),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(_currentDay, style: const TextStyle(fontSize: 22, color: Colors.cyanAccent)),
                Text(_currentTime, style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final item = _schedules[index];
                return ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.cyanAccent),
                  title: Text(item.name),
                  subtitle: Text("Time: ${item.time}"),
                  trailing: Icon(item.filePath != null ? Icons.check_circle : Icons.warning,
                      color: item.filePath != null ? Colors.green : Colors.orange),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewActivity,
        child: const Icon(Icons.add),
      ),
    );
  }
}