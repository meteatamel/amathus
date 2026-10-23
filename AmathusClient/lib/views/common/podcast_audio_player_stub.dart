import 'dart:async';
import 'package:flutter/foundation.dart';

class PodcastAudioPlayer {
  VoidCallback? onEnded;
  VoidCallback? onError;
  ValueChanged<double>? onPositionFractionChanged;
  Timer? _simulatedTimer;
  bool _isPaused = false;

  Future<void> playIntroJingle({double playbackRate = 1.0}) async {}

  Future<void> playOutroJingle({double playbackRate = 1.0}) async {}

  Future<void> playUrl(
    String url, {
    required double playbackRate,
    required String fallbackText,
    required String fallbackLang,
    required bool isHostA,
    double initialSeekFraction = 0.0,
  }) async {
    stop();
    _isPaused = false;
    onPositionFractionChanged?.call(initialSeekFraction.clamp(0.0, 1.0));
    _simulatedTimer = Timer(const Duration(seconds: 4), () {
      if (!_isPaused) {
        onPositionFractionChanged?.call(1.0);
        onEnded?.call();
      }
    });
  }

  void seekWithinTurn(double fraction) {
    onPositionFractionChanged?.call(fraction.clamp(0.0, 1.0));
  }

  void prefetchUrl(String url) {}

  void pause() {
    _isPaused = true;
    _simulatedTimer?.cancel();
  }

  Future<void> resume() async {
    _isPaused = false;
    _simulatedTimer?.cancel();
    _simulatedTimer = Timer(const Duration(seconds: 3), () {
      if (!_isPaused) {
        onEnded?.call();
      }
    });
  }

  void setPlaybackRate(double rate) {}

  void stop() {
    _isPaused = false;
    _simulatedTimer?.cancel();
    _simulatedTimer = null;
  }

  void dispose() {
    stop();
  }
}
