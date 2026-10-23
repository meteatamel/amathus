import 'dart:math' as math;

import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/podcast_audio_player.dart';
import 'package:flutter/material.dart';

class PageIntroBanner extends StatelessWidget {
  final String text;
  final String emoji;

  const PageIntroBanner({
    super.key,
    required this.text,
    this.emoji = '✨',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2942), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(
              fontSize: 18,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.94),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PodcastPlaybackController extends ChangeNotifier {
  static final PodcastPlaybackController instance =
      PodcastPlaybackController._();

  static const List<String> voicePresetPool = <String>[
    'chirp_aoede_puck',
    'chirp_sulafat_achird',
    'chirp_callirrhoe_umbriel',
    'chirp_zephyr_charon',
    'chirp_kore_fenrir',
    'chirp_leda_orus',
  ];

  static const List<String> musicPresetPool = <String>[
    'warm_podcast',
    'mediterranean',
    'ambient_lounge',
    'broadcast_news',
  ];

  static const List<String> chimePresetPool = <String>[
    'soft_marimba',
    'glass_bell',
    'vibraphone_chord',
    'harp_pluck',
    'news_pulse',
  ];

  final math.Random _random = math.Random();
  final PodcastAudioPlayer _player = PodcastAudioPlayer();

  NewsOverview? _overview;
  String _defaultLanguage = 'en';
  String? _selectedLanguage;
  int _currentTurnIndex = 0;
  double _withinTurnFraction = 0.0;
  double? _draggingOverallFraction;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _needsReloadOnResume = false;
  int _playSessionId = 0;
  double _playbackRate = 1.0;

  String _voicePreset = voicePresetPool.first;
  String _musicPreset = musicPresetPool.first;
  String _chimePreset = chimePresetPool.first;

  PodcastPlaybackController._() {
    _randomizeSessionPresets();
    _player.onEnded = _handleTurnEnded;
    _player.onError = _handleTurnError;
    _player.onPositionFractionChanged = (fraction) {
      if (_draggingOverallFraction != null) return;
      _withinTurnFraction = fraction.clamp(0.0, 1.0);
      notifyListeners();
    };
  }

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get playbackRate => _playbackRate;
  double? get draggingOverallFraction => _draggingOverallFraction;
  String get voicePreset => _voicePreset;
  String get musicPreset => _musicPreset;
  String get chimePreset => _chimePreset;

  String _pickDifferentRandom(List<String> pool, String current) {
    if (pool.length <= 1) return pool.first;
    String candidate = current;
    for (int i = 0; i < 6 && candidate == current; i++) {
      candidate = pool[_random.nextInt(pool.length)];
    }
    return candidate;
  }

  void _randomizeSessionPresets() {
    _voicePreset = _pickDifferentRandom(voicePresetPool, _voicePreset);
    _musicPreset = _pickDifferentRandom(musicPresetPool, _musicPreset);
    _chimePreset = _pickDifferentRandom(chimePresetPool, _chimePreset);
  }

  void attachOverview(NewsOverview overview, String defaultLanguage) {
    final prevOverview = _overview;
    final prevDefaultLang = _defaultLanguage;
    _overview = overview;
    _defaultLanguage = defaultLanguage;

    if (prevOverview != null && prevOverview.generatedAt != overview.generatedAt) {
      if (!_isPlaying) {
        _currentTurnIndex = 0;
        _withinTurnFraction = 0.0;
      }
    }

    if (prevDefaultLang != defaultLanguage) {
      _selectedLanguage = null;
      if (_isPlaying && !_isPaused) {
        _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
      } else if (_isPlaying && _isPaused) {
        _needsReloadOnResume = true;
        _player.stop();
      }
    }
  }

  String get effectiveLanguage {
    final lang = _selectedLanguage ?? _defaultLanguage;
    if (lang == 'el' || lang == 'tr' || lang == 'en') {
      return lang;
    }
    return 'en';
  }

  String get effectiveEdition {
    return _overview?.effectiveEdition ?? NewsOverview.currentCyprusEdition();
  }

  List<PodcastDialogueTurn> get turns {
    final ov = _overview;
    if (ov == null) return const [];
    return ov.turnsForEdition(effectiveEdition);
  }

  double get overallProgress {
    if (_draggingOverallFraction != null) {
      return _draggingOverallFraction!.clamp(0.0, 1.0);
    }
    final list = turns;
    if (list.isEmpty) return 0.0;
    final safeIdx = _currentTurnIndex.clamp(0, list.length - 1);
    return ((safeIdx + _withinTurnFraction.clamp(0.0, 1.0)) / list.length)
        .clamp(0.0, 1.0);
  }

  String _buildAudioUrl(PodcastDialogueTurn turn, String lang) {
    final text = turn.textFor(lang);
    final speaker = turn.isHostA ? 'A' : 'B';
    return '${Constants.URL_PODCAST_AUDIO}'
        '?lang=${Uri.encodeQueryComponent(lang)}'
        '&speaker=${Uri.encodeQueryComponent(speaker)}'
        '&voicePreset=${Uri.encodeQueryComponent(_voicePreset)}'
        '&text=${Uri.encodeQueryComponent(text)}';
  }

  bool _shouldPlayChimeBetween(
    PodcastDialogueTurn prevTurn,
    PodcastDialogueTurn nextTurn,
    int nextIndex,
    int totalTurns,
  ) {
    final prevStory = prevTurn.storyId;
    final nextStory = nextTurn.storyId;
    if (nextStory != null && nextStory.isNotEmpty && nextStory != prevStory) {
      return true;
    }
    // Fallback if storyId was not populated: even turns 2..totalTurns-3 start a new story
    if ((nextStory == null || nextStory.isEmpty) &&
        (prevStory == null || prevStory.isEmpty) &&
        nextIndex >= 2 &&
        nextIndex <= totalTurns - 3 &&
        nextIndex.isEven) {
      return true;
    }
    return false;
  }

  Future<void> _handleTurnEnded() async {
    if (!_isPlaying) return;
    final list = turns;
    if (_currentTurnIndex + 1 < list.length) {
      final prevTurn = list[_currentTurnIndex];
      final nextIndex = _currentTurnIndex + 1;
      final nextTurn = list[nextIndex];
      final playChime = _shouldPlayChimeBetween(
        prevTurn,
        nextTurn,
        nextIndex,
        list.length,
      );

      _currentTurnIndex = nextIndex;
      _withinTurnFraction = 0.0;
      notifyListeners();
      await _playCurrentTurn(withStoryChime: playChime);
    } else {
      await _player.playOutroJingle(
        playbackRate: _playbackRate,
        style: _musicPreset,
      );
      _isPlaying = false;
      _isPaused = false;
      _currentTurnIndex = 0;
      _withinTurnFraction = 0.0;
      notifyListeners();
    }
  }

  void _handleTurnError() {
    _isPlaying = false;
    _isPaused = false;
    notifyListeners();
  }

  Future<void> _playCurrentTurn({
    bool withIntroJingle = false,
    bool withStoryChime = false,
    double initialSeekFraction = 0.0,
  }) async {
    final list = turns;
    if (list.isEmpty) return;
    if (_currentTurnIndex < 0 || _currentTurnIndex >= list.length) {
      _currentTurnIndex = 0;
    }

    final sessionId = ++_playSessionId;
    _needsReloadOnResume = false;

    final currentTurn = list[_currentTurnIndex];
    final lang = effectiveLanguage;
    final url = _buildAudioUrl(currentTurn, lang);

    if (withIntroJingle) {
      _player.prefetchUrl(url);
      await _player.playIntroJingle(
        playbackRate: _playbackRate,
        style: _musicPreset,
      );
      if (!_isPlaying || _isPaused || sessionId != _playSessionId) {
        return;
      }
    } else if (withStoryChime) {
      _player.prefetchUrl(url);
      await _player.playStoryChime(
        playbackRate: _playbackRate,
        style: _chimePreset,
      );
      if (!_isPlaying || _isPaused || sessionId != _playSessionId) {
        return;
      }
    }

    await _player.playUrl(
      url,
      playbackRate: _playbackRate,
      fallbackText: currentTurn.textFor(lang),
      fallbackLang: lang,
      isHostA: currentTurn.isHostA,
      initialSeekFraction: initialSeekFraction,
    );

    if (!_isPlaying || sessionId != _playSessionId) return;

    if (_currentTurnIndex + 1 < list.length) {
      final nextTurn = list[_currentTurnIndex + 1];
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!_isPlaying || sessionId != _playSessionId) return;
        _player.prefetchUrl(_buildAudioUrl(nextTurn, effectiveLanguage));
      });
    }
  }

  void togglePlayPause() {
    final list = turns;
    if (list.isEmpty) return;

    if (_isPlaying && !_isPaused) {
      _playSessionId++;
      _player.pause();
      _isPaused = true;
      notifyListeners();
    } else if (_isPlaying && _isPaused) {
      _isPaused = false;
      notifyListeners();
      if (_needsReloadOnResume || !_player.hasActiveAudio) {
        _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
      } else {
        _player.resume().then((resumed) {
          if (!resumed && _isPlaying && !_isPaused) {
            _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
          }
        });
      }
    } else {
      final startingFromBeginning =
          _currentTurnIndex == 0 && _withinTurnFraction < 0.05;
      if (startingFromBeginning) {
        _randomizeSessionPresets();
      }
      _isPlaying = true;
      _isPaused = false;
      notifyListeners();
      _playCurrentTurn(
        withIntroJingle: startingFromBeginning,
        initialSeekFraction: _withinTurnFraction,
      );
    }
  }

  void setDraggingFraction(double value) {
    _draggingOverallFraction = value;
    notifyListeners();
  }

  void seekToOverallFraction(double overallFraction) {
    final list = turns;
    if (list.isEmpty) return;

    final clamped = overallFraction.clamp(0.0, 0.999);
    final scaled = clamped * list.length;
    final targetTurn = scaled.floor().clamp(0, list.length - 1);
    final targetWithinTurn = (scaled - targetTurn).clamp(0.0, 0.98);

    final sameTurn = targetTurn == _currentTurnIndex;
    _draggingOverallFraction = null;
    _currentTurnIndex = targetTurn;
    _withinTurnFraction = targetWithinTurn;
    notifyListeners();

    if (_isPlaying && !_isPaused) {
      if (sameTurn && _player.hasActiveAudio) {
        _player.seekWithinTurn(targetWithinTurn);
      } else {
        _playCurrentTurn(initialSeekFraction: targetWithinTurn);
      }
    } else if (_isPlaying && _isPaused) {
      if (sameTurn && _player.hasActiveAudio) {
        _player.seekWithinTurn(targetWithinTurn);
      } else {
        _needsReloadOnResume = true;
        _player.stop();
      }
    } else {
      _needsReloadOnResume = true;
      final turn = list[targetTurn];
      _player.prefetchUrl(_buildAudioUrl(turn, effectiveLanguage));
    }
  }

  void cycleSpeed() {
    final nextRate = _playbackRate == 1.0
        ? 1.25
        : (_playbackRate == 1.25 ? 1.5 : 1.0);
    _playbackRate = nextRate;
    _player.setPlaybackRate(nextRate);
    notifyListeners();
  }

  void selectLanguage(String lang) {
    if (effectiveLanguage == lang) return;
    _selectedLanguage = lang;
    notifyListeners();
    if (_isPlaying && !_isPaused) {
      _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
    } else if (_isPlaying && _isPaused) {
      _needsReloadOnResume = true;
      _player.stop();
    }
  }
}

class TopStoriesPodcastCard extends StatefulWidget {
  final NewsOverview overview;
  final String defaultLanguage;
  final bool isColumnists;

  const TopStoriesPodcastCard({
    super.key,
    required this.overview,
    required this.defaultLanguage,
    this.isColumnists = false,
  });

  @override
  State<TopStoriesPodcastCard> createState() => _TopStoriesPodcastCardState();
}

class _TopStoriesPodcastCardState extends State<TopStoriesPodcastCard>
    with AutomaticKeepAliveClientMixin {
  final PodcastPlaybackController _controller =
      PodcastPlaybackController.instance;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.attachOverview(widget.overview, widget.defaultLanguage);
  }

  @override
  void didUpdateWidget(covariant TopStoriesPodcastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overview != widget.overview ||
        oldWidget.defaultLanguage != widget.defaultLanguage) {
      _controller.attachOverview(widget.overview, widget.defaultLanguage);
    }
  }

  String _editionEmoji(String edition) {
    switch (edition) {
      case 'morning':
        return '☀️';
      case 'midday':
        return '🌤️';
      default:
        return '🌙';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final turns = _controller.turns;
        if (turns.isEmpty) {
          return const SizedBox.shrink();
        }

        final lang = _controller.effectiveLanguage;
        final edition = _controller.effectiveEdition;
        final isPlayingNow = _controller.isPlaying && !_controller.isPaused;

        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFCD34D),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F2942).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        _editionEmoji(edition),
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Constants.podcastEditionTitleFor(
                              edition,
                              lang,
                              isColumnists: widget.isColumnists,
                            ),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F2942),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            Constants.podcastSubtitleFor(edition, lang),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2942),
                          foregroundColor: const Color(0xFFFBBF24),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        onPressed: _controller.togglePlayPause,
                        child: Icon(
                          isPlayingNow
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: const Color(0xFF0F2942),
                          inactiveTrackColor: const Color(0xFF0F2942)
                              .withValues(alpha: 0.16),
                          thumbColor: const Color(0xFF0F2942),
                          overlayColor: const Color(0xFF0F2942)
                              .withValues(alpha: 0.12),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: _controller.overallProgress,
                          min: 0.0,
                          max: 1.0,
                          onChanged: _controller.setDraggingFraction,
                          onChangeEnd: _controller.seekToOverallFraction,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _controller.cycleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0F2942).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_controller.playbackRate}x',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F2942),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
