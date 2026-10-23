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

  static final Map<String, String> _cachedJingleUris = <String, String>{};
  static final Map<String, String> _cachedChimeUris = <String, String>{};

  bool get hasActiveAudio => _audio != null;

  Future<void> playIntroJingle({
    double playbackRate = 1.0,
    String style = 'warm_podcast',
  }) async {
    if (style == 'none') return;
    final key = 'intro:$style';
    final uri = _cachedJingleUris[key] ??= _buildMusicJingleDataUri(
      style: style,
      isIntro: true,
    );
    await _playJingleDataUri(uri, timeoutMs: 2800);
  }

  Future<void> playOutroJingle({
    double playbackRate = 1.0,
    String style = 'warm_podcast',
  }) async {
    if (style == 'none') return;
    final key = 'outro:$style';
    final uri = _cachedJingleUris[key] ??= _buildMusicJingleDataUri(
      style: style,
      isIntro: false,
    );
    await _playJingleDataUri(uri, timeoutMs: 2800);
  }

  Future<void> playStoryChime({
    double playbackRate = 1.0,
    String style = 'soft_marimba',
  }) async {
    if (style == 'none') return;
    final uri = _cachedChimeUris[style] ??= _buildStoryChimeDataUri(
      style: style,
    );
    await _playJingleDataUri(uri, timeoutMs: 1200);
  }

  Future<void> _playJingleDataUri(
    String dataUri, {
    int timeoutMs = 2600,
  }) async {
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
      Duration(milliseconds: timeoutMs),
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

  static String _buildMusicJingleDataUri({
    required String style,
    required bool isIntro,
  }) {
    switch (style) {
      case 'mediterranean':
        return _buildMediterraneanGuitarDataUri(isIntro: isIntro);
      case 'ambient_lounge':
        return _buildAmbientLoungeDataUri(isIntro: isIntro);
      case 'broadcast_news':
        return _buildNewsJingleDataUri(isIntro: isIntro);
      case 'warm_podcast':
      default:
        return _buildWarmPodcastMarimbaDataUri(isIntro: isIntro);
    }
  }

  /// Warm Podcast Marimba & Electric Piano (The Daily / NotebookLM / Morning Brew style)
  static String _buildWarmPodcastMarimbaDataUri({required bool isIntro}) {
    const sampleRate = 22050;
    const durationSeconds = 2.35;
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);

    void addRhodesPad(double freq, double startSec, double durSec, double amp) {
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.06) ? (t / 0.06) : 1.0;
        final decay = math.exp(-t * 1.35);
        final fadeOut = ((durSec - t) < 0.35)
            ? ((durSec - t) / 0.35).clamp(0.0, 1.0)
            : 1.0;
        final tremolo = 1.0 + 0.08 * math.sin(2 * math.pi * 4.5 * t);
        final env = attack * decay * fadeOut * tremolo * amp;
        final sig = math.sin(2 * math.pi * freq * t) +
            0.28 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t * 3.0) +
            0.08 * math.sin(2 * math.pi * freq * 3.0 * t) * math.exp(-t * 5.0);
        samples[i] += env * sig;
      }
    }

    void addMarimbaNote(double freq, double startSec, double amp) {
      const durSec = 0.42;
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.004) ? (t / 0.004) : 1.0;
        final env = attack * math.exp(-t * 9.5) * amp;
        // Marimba has a characteristic 4th harmonic overtone that decays quickly
        final sig = math.sin(2 * math.pi * freq * t) +
            0.35 * math.sin(2 * math.pi * freq * 4.0 * t) * math.exp(-t * 28.0);
        samples[i] += env * sig;
      }
    }

    // Warm Fmaj7 -> G6 -> Cmaj9 chord bed
    for (final f in [174.61, 261.63, 329.63, 440.00]) {
      addRhodesPad(f, 0.0, 1.05, 0.13);
    }
    for (final f in [130.81, 261.63, 329.63, 392.00, 493.88]) {
      addRhodesPad(f, 0.90, 1.45, 0.13);
    }

    if (isIntro) {
      // Uplifting conversational marimba melody: C4 -> E4 -> G4 -> A4 -> C5 -> E5
      addMarimbaNote(261.63, 0.06, 0.25); // C4
      addMarimbaNote(329.63, 0.24, 0.26); // E4
      addMarimbaNote(392.00, 0.42, 0.27); // G4
      addMarimbaNote(440.00, 0.60, 0.27); // A4
      addMarimbaNote(523.25, 0.82, 0.30); // C5
      addMarimbaNote(659.25, 1.04, 0.32); // E5
      addMarimbaNote(587.33, 1.04, 0.16); // D5 harmony
    } else {
      // Relaxed resolving marimba cadence: E5 -> D5 -> C5 -> A4 -> G4 -> C4
      addMarimbaNote(659.25, 0.08, 0.27); // E5
      addMarimbaNote(587.33, 0.28, 0.26); // D5
      addMarimbaNote(523.25, 0.48, 0.26); // C5
      addMarimbaNote(440.00, 0.68, 0.25); // A4
      addMarimbaNote(392.00, 0.88, 0.28); // G4
      addMarimbaNote(261.63, 1.08, 0.30); // C4
      addMarimbaNote(523.25, 1.08, 0.22); // C5
    }

    return _encodeSamplesToWavDataUri(samples, sampleRate);
  }

  /// Sunny Mediterranean Acoustic Pluck (Nylon guitar / harp arpeggio)
  static String _buildMediterraneanGuitarDataUri({required bool isIntro}) {
    const sampleRate = 22050;
    const durationSeconds = 2.4;
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);

    void addPluck(double freq, double startSec, double durSec, double amp) {
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.005) ? (t / 0.005) : 1.0;
        final decay = math.exp(-t * 3.8);
        final env = attack * decay * amp;
        final sig = math.sin(2 * math.pi * freq * t) +
            0.50 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t * 4.5) +
            0.22 * math.sin(2 * math.pi * freq * 3.0 * t) * math.exp(-t * 8.0) +
            0.10 * math.sin(2 * math.pi * freq * 4.0 * t) * math.exp(-t * 12.0);
        samples[i] += env * sig;
      }
    }

    if (isIntro) {
      // Warm Aegean Am9 -> G6 -> Fmaj7 arpeggio
      final notes = <(double, double, double)>[
        (110.00, 0.00, 0.24), // A2
        (220.00, 0.14, 0.22), // A3
        (261.63, 0.28, 0.23), // C4
        (329.63, 0.42, 0.24), // E4
        (493.88, 0.56, 0.25), // B4
        (440.00, 0.74, 0.26), // A4
        (392.00, 0.92, 0.24), // G4
        (523.25, 1.10, 0.28), // C5
        (659.25, 1.18, 0.26), // E5
      ];
      for (final (freq, start, amp) in notes) {
        addPluck(freq, start, 1.15, amp);
      }
    } else {
      final notes = <(double, double, double)>[
        (659.25, 0.00, 0.24), // E5
        (523.25, 0.16, 0.23), // C5
        (493.88, 0.32, 0.23), // B4
        (440.00, 0.48, 0.24), // A4
        (329.63, 0.66, 0.24), // E4
        (261.63, 0.84, 0.24), // C4
        (110.00, 1.02, 0.26), // A2
        (220.00, 1.05, 0.24), // A3
        (440.00, 1.08, 0.26), // A4
      ];
      for (final (freq, start, amp) in notes) {
        addPluck(freq, start, 1.25, amp);
      }
    }

    return _encodeSamplesToWavDataUri(samples, sampleRate);
  }

  /// Soft Lo-Fi Ambient Lounge Rhodes & Shimmer
  static String _buildAmbientLoungeDataUri({required bool isIntro}) {
    const sampleRate = 22050;
    const durationSeconds = 2.3;
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);

    void addSilkPad(double freq, double startSec, double durSec, double amp) {
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.22) ? (t / 0.22) : 1.0;
        final fadeOut = ((durSec - t) < 0.55)
            ? ((durSec - t) / 0.55).clamp(0.0, 1.0)
            : 1.0;
        final env = attack * fadeOut * amp;
        final sig = math.sin(2 * math.pi * freq * t) +
            0.35 * math.sin(2 * math.pi * (freq * 1.003) * t) +
            0.15 * math.sin(2 * math.pi * (freq * 2.0) * t);
        samples[i] += env * sig;
      }
    }

    void addBellShimmer(double freq, double startSec, double amp) {
      const durSec = 0.95;
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.01) ? (t / 0.01) : 1.0;
        final env = attack * math.exp(-t * 4.2) * amp;
        samples[i] += env *
            (math.sin(2 * math.pi * freq * t) +
                0.25 * math.sin(2 * math.pi * freq * 2.0 * t));
      }
    }

    // Lush EbMaj9 -> BbMaj7 lounge chords
    for (final f in [155.56, 233.08, 293.66, 349.23, 392.00]) {
      addSilkPad(f, 0.0, 2.2, 0.13);
    }

    if (isIntro) {
      addBellShimmer(587.33, 0.20, 0.18); // D5
      addBellShimmer(698.46, 0.50, 0.19); // F5
      addBellShimmer(783.99, 0.80, 0.20); // G5
      addBellShimmer(1046.50, 1.10, 0.18); // C6
    } else {
      addBellShimmer(1046.50, 0.18, 0.18); // C6
      addBellShimmer(783.99, 0.48, 0.19); // G5
      addBellShimmer(698.46, 0.78, 0.19); // F5
      addBellShimmer(587.33, 1.08, 0.20); // D5
    }

    return _encodeSamplesToWavDataUri(samples, sampleRate);
  }

  /// Generates a short, musical between-story transition chime (~0.5s - 0.65s).
  static String _buildStoryChimeDataUri({required String style}) {
    const sampleRate = 22050;
    const durationSeconds = 0.68;
    final numSamples = (sampleRate * durationSeconds).toInt();
    final samples = Float64List(numSamples);

    void addNote(
      double freq,
      double startSec,
      double durSec,
      double amp, {
      double decayRate = 8.5,
      double harmonic2 = 0.25,
      double harmonic4 = 0.0,
    }) {
      final startIdx = (startSec * sampleRate).toInt();
      final endIdx = math.min(
        numSamples,
        ((startSec + durSec) * sampleRate).toInt(),
      );
      for (var i = startIdx; i < endIdx; i++) {
        final t = (i - startIdx) / sampleRate;
        final attack = (t < 0.005) ? (t / 0.005) : 1.0;
        final env = attack * math.exp(-t * decayRate) * amp;
        final sig = math.sin(2 * math.pi * freq * t) +
            harmonic2 *
                math.sin(2 * math.pi * freq * 2.0 * t) *
                math.exp(-t * 12.0) +
            harmonic4 *
                math.sin(2 * math.pi * freq * 4.0 * t) *
                math.exp(-t * 25.0);
        samples[i] += env * sig;
      }
    }

    switch (style) {
      case 'glass_bell':
        // Single pure crystal celesta ding (E5 + soft B5 fifth shimmer)
        addNote(659.25, 0.02, 0.62, 0.28, decayRate: 6.2, harmonic2: 0.35);
        addNote(987.77, 0.04, 0.55, 0.12, decayRate: 7.5, harmonic2: 0.20);
        break;
      case 'vibraphone_chord':
        // Rolled warm vibraphone Fmaj7 chord (F4 -> A4 -> C5 -> E5)
        addNote(349.23, 0.00, 0.62, 0.18, decayRate: 5.5, harmonic2: 0.15);
        addNote(440.00, 0.05, 0.58, 0.18, decayRate: 5.5, harmonic2: 0.15);
        addNote(523.25, 0.10, 0.54, 0.19, decayRate: 5.5, harmonic2: 0.15);
        addNote(659.25, 0.15, 0.50, 0.22, decayRate: 5.5, harmonic2: 0.18);
        break;
      case 'harp_pluck':
        // Gentle two-note Mediterranean harp harmonic pluck (D5 -> A5)
        addNote(587.33, 0.02, 0.55, 0.26, decayRate: 6.5, harmonic2: 0.45);
        addNote(880.00, 0.16, 0.50, 0.26, decayRate: 6.0, harmonic2: 0.45);
        break;
      case 'news_pulse':
        // Crisp broadcast double-tick (A4 -> D5)
        addNote(440.00, 0.02, 0.20, 0.24, decayRate: 22.0, harmonic2: 0.30);
        addNote(587.33, 0.13, 0.35, 0.28, decayRate: 14.0, harmonic2: 0.30);
        break;
      case 'soft_marimba':
      default:
        // Warm two-note wooden marimba interval (C5 -> G5)
        addNote(
          523.25,
          0.02,
          0.35,
          0.28,
          decayRate: 11.0,
          harmonic2: 0.12,
          harmonic4: 0.32,
        );
        addNote(
          783.99,
          0.14,
          0.48,
          0.30,
          decayRate: 9.0,
          harmonic2: 0.12,
          harmonic4: 0.30,
        );
        break;
    }

    return _encodeSamplesToWavDataUri(samples, sampleRate);
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

    return _encodeSamplesToWavDataUri(samples, sampleRate);
  }

  static String _encodeSamplesToWavDataUri(
    Float64List samples,
    int sampleRate,
  ) {
    final numSamples = samples.length;
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
