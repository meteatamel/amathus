// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

class PodcastAudioPlayer {
  VoidCallback? onEnded;
  VoidCallback? onError;
  ValueChanged<double>? onPositionFractionChanged;

  html.AudioElement? _audio;
  html.AudioElement? _jingleAudio;
  html.AudioElement? _prefetchedAudio;
  String? _prefetchedUrl;
  StreamSubscription<html.Event>? _endedSub;
  StreamSubscription<html.Event>? _errorSub;
  StreamSubscription<html.Event>? _timeUpdateSub;
  double _playbackRate = 1.0;

  static String? _cachedIntroDataUri;
  static String? _cachedOutroDataUri;

  bool get hasActiveAudio => _audio != null;

  Future<void> playIntroJingle({double playbackRate = 1.0}) async {
    _cachedIntroDataUri ??= _buildNewsJingleDataUri(isIntro: true);
    await _playJingleDataUri(_cachedIntroDataUri!);
  }

  Future<void> playOutroJingle({double playbackRate = 1.0}) async {
    _cachedOutroDataUri ??= _buildNewsJingleDataUri(isIntro: false);
    await _playJingleDataUri(_cachedOutroDataUri!);
  }

  Future<void> _playJingleDataUri(String dataUri) async {
    _stopJingle();
    final completer = Completer<void>();
    final element = html.AudioElement(dataUri)..preload = 'auto';
    _jingleAudio = element;

    StreamSubscription<html.Event>? endSub;
    StreamSubscription<html.Event>? errSub;

    void finish() {
      endSub?.cancel();
      errSub?.cancel();
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    endSub = element.onEnded.listen((_) => finish());
    errSub = element.onError.listen((_) => finish());

    try {
      await element.play();
    } catch (_) {
      finish();
    }

    await completer.future.timeout(
      const Duration(milliseconds: 2600),
      onTimeout: () {},
    );
  }

  void _stopJingle() {
    if (_jingleAudio != null) {
      try {
        _jingleAudio!.pause();
        _jingleAudio!.src = '';
      } catch (_) {}
      _jingleAudio = null;
    }
  }

  Future<void> playUrl(
    String url, {
    required double playbackRate,
    required String fallbackText,
    required String fallbackLang,
    required bool isHostA,
    double initialSeekFraction = 0.0,
  }) async {
    stop();
    _playbackRate = playbackRate;

    html.AudioElement element;
    if (_prefetchedAudio != null && _prefetchedUrl == url) {
      element = _prefetchedAudio!;
      _prefetchedAudio = null;
      _prefetchedUrl = null;
    } else {
      element = html.AudioElement(url)..preload = 'auto';
    }

    _audio = element;
    element.playbackRate = _playbackRate;
    element.defaultPlaybackRate = _playbackRate;

    void applyInitialSeek() {
      if (_audio != element) return;
      final dur = element.duration;
      if (dur.isFinite && dur > 0) {
        try {
          element.currentTime = (dur * initialSeekFraction.clamp(0.0, 0.98));
        } catch (_) {}
      }
    }

    if (initialSeekFraction > 0.01) {
      if (element.readyState >= 1) {
        applyInitialSeek();
      } else {
        element.onLoadedMetadata.first.then((_) => applyInitialSeek());
      }
    }

    _timeUpdateSub = element.onTimeUpdate.listen((_) {
      if (_audio != element) return;
      final dur = element.duration;
      final cur = element.currentTime;
      if (dur.isFinite && dur > 0) {
        onPositionFractionChanged?.call((cur / dur).clamp(0.0, 1.0));
      }
    });

    _endedSub = element.onEnded.listen((_) {
      if (_audio != element) return;
      onPositionFractionChanged?.call(1.0);
      onEnded?.call();
    });

    _errorSub = element.onError.listen((_) {
      if (_audio != element) return;
      onError?.call();
    });

    try {
      await element.play();
    } catch (_) {
      if (_audio != element) return;
      onError?.call();
    }
  }

  void seekWithinTurn(double fraction) {
    final element = _audio;
    if (element == null) return;
    final dur = element.duration;
    if (dur.isFinite && dur > 0) {
      try {
        element.currentTime = dur * fraction.clamp(0.0, 0.99);
        onPositionFractionChanged?.call(fraction.clamp(0.0, 1.0));
      } catch (_) {}
    }
  }

  void prefetchUrl(String url) {
    if (url.isEmpty || _prefetchedUrl == url) return;
    _prefetchedUrl = url;
    _prefetchedAudio = html.AudioElement(url)..preload = 'auto';
    _prefetchedAudio!.load();
  }

  void pause() {
    _stopJingle();
    _audio?.pause();
  }

  Future<bool> resume() async {
    final element = _audio;
    if (element != null) {
      try {
        element.playbackRate = _playbackRate;
        await element.play();
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  void setPlaybackRate(double rate) {
    _playbackRate = rate;
    if (_audio != null) {
      _audio!.playbackRate = rate;
      _audio!.defaultPlaybackRate = rate;
    }
  }

  void stop() {
    _stopJingle();
    _endedSub?.cancel();
    _endedSub = null;
    _errorSub?.cancel();
    _errorSub = null;
    _timeUpdateSub?.cancel();
    _timeUpdateSub = null;
    final oldAudio = _audio;
    _audio = null;
    if (oldAudio != null) {
      try {
        oldAudio.pause();
        oldAudio.src = '';
      } catch (_) {}
    }
  }

  void dispose() {
    stop();
    _prefetchedAudio = null;
    _prefetchedUrl = null;
  }

  /// Generates an authentic broadcast radio news bulletin stinger (BBC/Euronews style):
  /// warm D-minor/suspended orchestral pad + rhythmic newsroom teletype pulse + news headline chimes.
  static String _buildNewsJingleDataUri({required bool isIntro}) {
    const sampleRate = 22050;
    const durationSeconds = 2.0;
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);

    // 1. Warm low broadcast pad swell (D2 = 73.42 Hz, A2 = 110.00 Hz, D3 = 146.83 Hz, A3 = 220.00 Hz)
    void addWarmPad(double freq, double startSec, double durSec, double amp) {
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.18) ? (t / 0.18) : 1.0;
        final fadeOut = ((durSec - t) < 0.45)
            ? ((durSec - t) / 0.45).clamp(0.0, 1.0)
            : 1.0;
        final env = attack * fadeOut * amp;
        final sig = math.sin(2 * math.pi * freq * t) +
            0.4 * math.sin(2 * math.pi * (freq * 1.002) * t) +
            0.2 * math.sin(2 * math.pi * (freq * 2.0) * t);
        samples[i] += env * sig;
      }
    }

    // 2. Rhythmic 16th-note newsroom pulse (percussive muted synth tick at 133 BPM -> 0.1125s per 16th)
    void addNewsTickerPulse(double startSec, double freq, double amp) {
      const durSec = 0.085;
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.004) ? (t / 0.004) : 1.0;
        final decay = math.exp(-t * 42.0);
        final env = attack * decay * amp;
        samples[i] += env *
            (math.sin(2 * math.pi * freq * t) +
                0.3 * math.sin(2 * math.pi * freq * 2.0 * t));
      }
    }

    // 3. Broadcast news brass/bell stinger note
    void addStingerNote(
      double freq,
      double startSec,
      double durSec,
      double amp,
    ) {
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.008) ? (t / 0.008) : 1.0;
        final decay = math.exp(-t * 3.8);
        final env = attack * decay * amp;
        final tone = math.sin(2 * math.pi * freq * t) +
            0.45 * math.sin(2 * math.pi * freq * 2.0 * t) +
            0.18 * math.sin(2 * math.pi * freq * 3.0 * t);
        samples[i] += env * tone;
      }
    }

    // Warm newsroom foundation fifths (D2 + A2 + D3)
    addWarmPad(73.42, 0.0, 1.95, 0.16);
    addWarmPad(110.00, 0.0, 1.95, 0.13);
    addWarmPad(146.83, 0.0, 1.95, 0.11);

    // Urgent 16th-note newsroom rhythm (12 pulses)
    final patternFreqs = [
      293.66, // D4
      293.66,
      440.00, // A4
      293.66,
      329.63, // E4
      293.66,
      440.00, // A4
      293.66,
      293.66,
      440.00,
      329.63,
      440.00,
    ];
    for (var s = 0; s < patternFreqs.length; s++) {
      final accent = (s % 4 == 0) ? 0.20 : 0.11;
      addNewsTickerPulse(s * 0.11, patternFreqs[s], accent);
    }

    if (isIntro) {
      // Iconic two-chime broadcast news headline call: A4 -> D5 -> E5 -> A5/D5
      addStingerNote(440.00, 0.22, 0.45, 0.22); // A4
      addStingerNote(587.33, 0.44, 0.50, 0.25); // D5
      addStingerNote(659.25, 0.77, 0.45, 0.24); // E5
      addStingerNote(587.33, 0.99, 0.95, 0.26); // D5
      addStingerNote(880.00, 0.99, 0.95, 0.20); // A5
    } else {
      // Authoritative broadcast news sign-off cadence: E5 -> A4 -> D4/A4/D5
      addStingerNote(659.25, 0.22, 0.45, 0.22); // E5
      addStingerNote(440.00, 0.55, 0.45, 0.24); // A4
      addStingerNote(293.66, 0.88, 1.05, 0.24); // D4
      addStingerNote(440.00, 0.88, 1.05, 0.20); // A4
      addStingerNote(587.33, 0.88, 1.05, 0.26); // D5
    }

    final dataSize = numSamples * 2;
    final wav = ByteData(44 + dataSize);

    final riff = [0x52, 0x49, 0x46, 0x46];
    for (var i = 0; i < 4; i++) {
      wav.setUint8(i, riff[i]);
    }
    wav.setUint32(4, 36 + dataSize, Endian.little);
    final wave = [0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20];
    for (var i = 0; i < 8; i++) {
      wav.setUint8(8 + i, wave[i]);
    }
    wav.setUint32(16, 16, Endian.little);
    wav.setUint16(20, 1, Endian.little);
    wav.setUint16(22, 1, Endian.little);
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate * 2, Endian.little);
    wav.setUint16(32, 2, Endian.little);
    wav.setUint16(34, 16, Endian.little);
    final dataHeader = [0x64, 0x61, 0x74, 0x61];
    for (var i = 0; i < 4; i++) {
      wav.setUint8(36 + i, dataHeader[i]);
    }
    wav.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < numSamples; i++) {
      final clamped = samples[i].clamp(-0.95, 0.95);
      final pcm = (clamped * 32767).toInt();
      wav.setInt16(44 + i * 2, pcm, Endian.little);
    }

    final base64Wav = base64Encode(wav.buffer.asUint8List());
    return 'data:audio/wav;base64,$base64Wav';
  }
}
