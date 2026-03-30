import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:win32audio/win32audio.dart';
import 'dart:async';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Stream<void> get onPlayerComplete => _audioPlayer.onPlayerComplete;

  final Map<int, double> _originalVolumes = {};
  bool _isRestoring = false;
  bool _isFadingOut = false;
  StreamSubscription? _positionSubscription;

  AudioService() {
    // ⬅️ السحر هنا: مراقبة الوقت المتبقي للإعلان لعمل Fade-out آلي قبل النهاية
    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) async {
      if (_audioPlayer.state == PlayerState.playing && !_isFadingOut) {
        Duration? totalDuration = await _audioPlayer.getDuration();
        
        // إذا كان الملف أطول من 5 ثواني، نبدأ النزول قبل 4 ثواني من نهايته
        if (totalDuration != null && totalDuration.inSeconds > 5) {
          if (totalDuration.inMilliseconds - pos.inMilliseconds <= 4000) {
            _isFadingOut = true;
            _autoFadeOutAndRestore();
          }
        }
      }
    });

    // في حالة انتهى الملف فجأة (أو كان قصيراً جداً)
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!_isFadingOut) {
        _restoreExternalApps();
      }
    });
  }

  // 1️⃣ Youtube/Spotify -> ينزل في 4 ثواني
  Future<void> _duckExternalApps() async {
    try {
      _originalVolumes.clear();
      var mixerList = await Audio.enumAudioMixer() ?? [];
      
      for (var process in mixerList) {
        if (!process.processPath.toLowerCase().contains('hassen_entertainment_automation')) {
          _originalVolumes[process.processId] = process.maxVolume;
        }
      }

      // النزول لـ 1% في 4 ثواني
      for (int i = 1; i <= 40; i++) {
        for (var process in mixerList) {
          if (_originalVolumes.containsKey(process.processId)) {
            double startVol = _originalVolumes[process.processId]!;
            double targetVol = startVol * 0.01; // ⬅️ نزلنا لـ 1% لضمان نقاء صوت الإعلان
            double currentVol = startVol - ((startVol - targetVol) * (i / 40.0));
            await Audio.setAudioMixerVolume(process.processId, currentVol);
          }
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint("Ducking Error: $e");
    }
  }

  // 4️⃣ Youtube/Spotify -> يرجع في 4 ثواني
  Future<void> _restoreExternalApps() async {
    if (_isRestoring) return;
    _isRestoring = true;

    try {
      // 4 ثواني تدرج (40 خطوة)
      for (int i = 1; i <= 40; i++) {
        var mixerList = await Audio.enumAudioMixer() ?? [];
        for (var process in mixerList) {
          if (_originalVolumes.containsKey(process.processId)) {
            double originalVol = _originalVolumes[process.processId]!;
            double startVol = originalVol * 0.01; // القيمة اللي نزلنالها (1%)
            
            double currentVol = startVol + ((originalVol - startVol) * (i / 40.0));
            await Audio.setAudioMixerVolume(process.processId, currentVol.clamp(0.0, 1.0));
          }
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // ⬅️ الضربة القاضية: تأكيد نهائي (Loop تأكيدي)
      // ساعات الويندوز "يغفل" على آخر خطوة، هنا نرجعوا القيم الأصلية بالسيف
      var finalMixer = await Audio.enumAudioMixer() ?? [];
      for (var process in finalMixer) {
        if (_originalVolumes.containsKey(process.processId)) {
          await Audio.setAudioMixerVolume(process.processId, _originalVolumes[process.processId]!);
        }
      }
      
    } catch (e) {
      debugPrint("Restore Error: $e");
    } finally {
      _originalVolumes.clear();
      _isRestoring = false;
    }
  }

  // دالة النزول الآلي (عند قرب انتهاء الإعلان)
  Future<void> _autoFadeOutAndRestore() async {
    // 3️⃣ الإعلان -> ينزل في 4 ثواني
    for (int i = 39; i >= 0; i--) {
      if (_audioPlayer.state != PlayerState.playing) break;
      await _audioPlayer.setVolume(i / 40.0);
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await _audioPlayer.stop();
    await _restoreExternalApps(); // ترجيع اليوتيوب
  }

  // 2️⃣ الإعلان -> يطلع في 3 ثواني
  Future<void> playWithFade(String path) async {
    _isFadingOut = false; // تصفير العداد
    
    // 1- طيح اليوتيوب (4 ثواني)
    await _duckExternalApps(); 
    
    await _audioPlayer.setVolume(0.0);
    await _audioPlayer.play(DeviceFileSource(path));

    // 2- طلع الإعلان (30 خطوة * 100ms = 3 ثواني)
    for (int i = 1; i <= 30; i++) {
      if (_audioPlayer.state != PlayerState.playing) break;
      await _audioPlayer.setVolume(i / 30.0);
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // الإيقاف اليدوي (زر Stop)
  Future<void> stopWithFade() async {
    if (_isFadingOut) return; // إذا كان الإعلان ينزل بطبيعته، لا تتدخل
    _isFadingOut = true;

    if (_audioPlayer.state == PlayerState.playing) {
      // 3️⃣ الإعلان -> ينزل في 4 ثواني (40 خطوة)
      for (int i = 39; i >= 0; i--) {
        await _audioPlayer.setVolume(i / 40.0);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    await _audioPlayer.stop();
    await _restoreExternalApps(); // ترجيع اليوتيوب
  }

  void dispose() {
    _positionSubscription?.cancel();
    _audioPlayer.dispose();
  }
}