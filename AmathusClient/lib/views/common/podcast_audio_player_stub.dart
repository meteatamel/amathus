import 'dart:async';
import 'package:flutter/foundation.dart';

class PodcastAudioPlayer {
  VoidCallback? onEnded;
  VoidCallback? onError;
  ValueChanged<double>? onPositionFractionChanged;
  ValueChanged<bool>? onLoadingChanged;
  Timer? _simulatedTimer;
  bool _isPaused = false;

  Future<void> playIntroJingle({
    double playbackRate = 1.0,
    String style = 'warm_podcast',
  }) async {}

  Future<void> playOutroJingle({
    double playbackRate = 1.0,
    String style = 'warm_podcast',
  }) async {}

  Future<void> playStoryChime({
    double playbackRate = 1.0,
    String style = 'soft_marimba',
  }) async {}

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

  bool isUrlCached(String url) => true;

  void unlockAudio() {}

  Future<void> prefetchUrl(String url) async {}

  void pause() {
    _isPaused = true;
    _simulatedTimer?.cancel();
  }

  bool get hasActiveAudio => _simulatedTimer != null || _isPaused;

  Future<bool> resume() async {
    _isPaused = false;
    _simulatedTimer?.cancel();
    _simulatedTimer = Timer(const Duration(seconds: 3), () {
      if (!_isPaused) {
        onEnded?.call();
      }
    });
    return true;
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
