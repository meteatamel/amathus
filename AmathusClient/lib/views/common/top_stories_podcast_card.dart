import 'dart:math' as math;

import 'package:amathus/controllers/translate_controller.dart';
import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/podcast_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class PageIntroBanner extends StatelessWidget {
  final String text;
  final IconData icon;

  const PageIntroBanner({
    super.key,
    required this.text,
    this.icon = Icons.auto_awesome_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: const Color(0xFFFBBF24),
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
  bool _isLoadingAudio = false;
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
    _player.onLoadingChanged = (loading) {
      if (_isLoadingAudio != loading) {
        _isLoadingAudio = loading;
        notifyListeners();
      }
    };
    _player.onPositionFractionChanged = (fraction) {
      if (_draggingOverallFraction != null) return;
      _withinTurnFraction = fraction.clamp(0.0, 1.0);
      notifyListeners();
    };
    _player.onRemotePlay = () {
      if (!_isPlaying || _isPaused) {
        togglePlayPause();
      }
    };
    _player.onRemotePause = () {
      if (_isPlaying && !_isPaused) {
        togglePlayPause();
      }
    };
    _player.onRemoteNext = () {
      final list = turns;
      if (list.isEmpty) return;
      final nextIdx = (_currentTurnIndex + 1).clamp(0, list.length - 1);
      seekToOverallFraction(nextIdx / list.length);
    };
    _player.onRemotePrevious = () {
      final list = turns;
      if (list.isEmpty) return;
      final prevIdx = _withinTurnFraction > 0.25
          ? _currentTurnIndex
          : (_currentTurnIndex - 1).clamp(0, list.length - 1);
      seekToOverallFraction(prevIdx / list.length);
    };
    Constants.languageNotifier.addListener(() {
      final newLang = Constants.languageNotifier.value;
      if (newLang != _defaultLanguage || _selectedLanguage != null) {
        _defaultLanguage = newLang;
        _selectedLanguage = null;
        _stopAndReset();
        _prefetchInitialTurns();
      }
    });
  }

  void _syncMediaSession() {
    final lang = effectiveLanguage;
    final edition = effectiveEdition;
    final title = Constants.podcastEditionTitleFor(edition, lang);
    final subtitle = Constants.podcastSubtitleFor(edition, lang);
    _player.updateMediaSession(
      title: title,
      subtitle: subtitle,
      isPlaying: _isPlaying && !_isPaused,
    );
  }

  void _stopAndReset() {
    _playSessionId++;
    _player.stopKeepAlive();
    _player.stop();
    _isPlaying = false;
    _isPaused = false;
    _isLoadingAudio = false;
    _needsReloadOnResume = false;
    _currentTurnIndex = 0;
    _withinTurnFraction = 0.0;
    _draggingOverallFraction = null;
    _syncMediaSession();
    notifyListeners();
  }

  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isLoadingAudio => _isLoadingAudio && _isPlaying && !_isPaused;
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
    _voicePreset = voicePresetPool.first;
    _musicPreset = _pickDifferentRandom(musicPresetPool, _musicPreset);
    _chimePreset = _pickDifferentRandom(chimePresetPool, _chimePreset);
  }

  void _prefetchInitialTurns() {
    final ov = _overview;
    if (ov == null) return;
    final lang = effectiveLanguage;
    if (ov.podcastTurns.isEmpty &&
        ov.podcastStories.any((s) => s.needsTranslationFor(lang))) {
      return;
    }
    final list = turns;
    if (list.isEmpty) return;
    _player.prefetchUrl(_buildAudioUrl(list[0], lang));
    if (list.length > 1) {
      _player.prefetchUrl(_buildAudioUrl(list[1], lang));
    }
  }

  void onStoriesUpdated() {
    if (!_isPlaying) {
      _prefetchInitialTurns();
    }
    notifyListeners();
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
      _stopAndReset();
    }

    _prefetchInitialTurns();
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

  double _estimateTurnDurationSeconds(PodcastDialogueTurn turn, String lang) {
    final text = turn.textFor(lang).trim();
    if (text.isEmpty) return 5.0;
    return (text.length / 14.5).clamp(4.0, 26.0);
  }

  int get remainingSeconds {
    final list = turns;
    if (list.isEmpty) return 0;
    final lang = effectiveLanguage;
    final progress = overallProgress.clamp(0.0, 1.0);
    final scaled = progress * list.length;
    final activeTurnIdx = scaled.floor().clamp(0, list.length - 1);
    final activeWithinTurn = (scaled - activeTurnIdx).clamp(0.0, 1.0);

    var remaining = 0.0;
    for (var i = activeTurnIdx; i < list.length; i++) {
      final turnSeconds = _estimateTurnDurationSeconds(list[i], lang);
      if (i == activeTurnIdx) {
        remaining += turnSeconds * (1.0 - activeWithinTurn);
      } else {
        remaining += turnSeconds + 0.35;
      }
    }
    final adjusted = remaining / (_playbackRate <= 0 ? 1.0 : _playbackRate);
    return adjusted.ceil().clamp(0, 3599);
  }

  String get formattedRemainingTime {
    final totalSec = remainingSeconds;
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    final mm = mins.toString().padLeft(2, '0');
    final ss = secs.toString().padLeft(2, '0');
    return '-$mm:$ss';
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
      if (!_player.isInBackground) {
        await _player.playOutroJingle(
          playbackRate: _playbackRate,
          style: _musicPreset,
        );
      }
      _player.stopKeepAlive();
      _isPlaying = false;
      _isPaused = false;
      _isLoadingAudio = false;
      _currentTurnIndex = 0;
      _withinTurnFraction = 0.0;
      _randomizeSessionPresets();
      _syncMediaSession();
      notifyListeners();
    }
  }

  void _handleTurnError() {
    _player.stopKeepAlive();
    _isPlaying = false;
    _isPaused = false;
    _isLoadingAudio = false;
    _syncMediaSession();
    notifyListeners();
  }

  Future<void> _playCurrentTurn({
    bool withIntroJingle = false,
    bool withStoryChime = false,
    double initialSeekFraction = 0.0,
  }) async {
    final sessionId = ++_playSessionId;
    _needsReloadOnResume = false;
    _withinTurnFraction = initialSeekFraction.clamp(0.0, 0.98);
    // Only stop if audio is currently active; when transitioning naturally on
    // `ended`, the element is already paused at the end of the track, and
    // calling stop() needlessly resets the element before playUrl swaps src.
    if (_player.hasActiveAudio) {
      _player.stop();
    }
    _player.startKeepAlive();
    _syncMediaSession();
    final lang = effectiveLanguage;

    final ov = _overview;
    if (ov != null) {
      final top8 = ov.podcastStories;
      if (top8.any((s) => s.needsTranslationFor(lang))) {
        _isLoadingAudio = true;
        notifyListeners();
        await TranslateController.ensureOverviewStoriesTranslated(top8, lang);
        if (!_isPlaying || _isPaused || sessionId != _playSessionId) {
          return;
        }
      }
    }

    final list = turns;
    if (list.isEmpty) return;
    if (_currentTurnIndex < 0 || _currentTurnIndex >= list.length) {
      _currentTurnIndex = 0;
    }

    final currentTurn = list[_currentTurnIndex];
    final url = _buildAudioUrl(currentTurn, lang);

    // If the current turn audio is not cached yet, show the loading spinner
    // while downloading so there is no silent gap after the intro jingle/chime.
    if (!_player.isUrlCached(url)) {
      _isLoadingAudio = true;
      notifyListeners();
      await _player.prefetchUrl(url);
      if (!_isPlaying || _isPaused || sessionId != _playSessionId) {
        return;
      }
      _isLoadingAudio = false;
      notifyListeners();
    }

    // Skip synthesized jingle/chime when the browser tab is in the background
    // or the device screen is locked, so the main <audio> element transitions
    // directly from turn N to turn N+1 without any timer delay.
    if (withIntroJingle && !_player.isInBackground) {
      await _player.playIntroJingle(
        playbackRate: _playbackRate,
        style: _musicPreset,
      );
      if (!_isPlaying || _isPaused || sessionId != _playSessionId) {
        return;
      }
    } else if (withStoryChime && !_player.isInBackground) {
      await _player.playStoryChime(
        playbackRate: _playbackRate,
        style: _chimePreset,
      );
      if (!_isPlaying || _isPaused || sessionId != _playSessionId) {
        return;
      }
    }

    // Kick off sequential prefetching of all remaining turns in the background
    // so the entire episode is cached in memory before the device sleeps.
    _prefetchUpcomingTurns(sessionId, _currentTurnIndex + 1, lang);

    await _player.playUrl(
      url,
      playbackRate: _playbackRate,
      fallbackText: currentTurn.textFor(lang),
      fallbackLang: lang,
      isHostA: currentTurn.isHostA,
      initialSeekFraction: initialSeekFraction,
    );
  }

  Future<void> _prefetchUpcomingTurns(
    int sessionId,
    int startIndex,
    String lang,
  ) async {
    final list = turns;
    for (var i = startIndex; i < list.length; i++) {
      if (!_isPlaying || sessionId != _playSessionId) return;
      final turnUrl = _buildAudioUrl(list[i], lang);
      if (!_player.isUrlCached(turnUrl)) {
        await _player.prefetchUrl(turnUrl);
      }
    }
  }

  void togglePlayPause() {
    final list = turns;
    if (list.isEmpty) return;

    if (_isPlaying && !_isPaused) {
      _playSessionId++;
      _player.stopKeepAlive();
      _player.pause();
      _isPaused = true;
      _isLoadingAudio = false;
      _syncMediaSession();
      notifyListeners();
    } else if (_isPlaying && _isPaused) {
      _player.unlockAudio();
      _player.startKeepAlive();
      _isPaused = false;
      _syncMediaSession();
      notifyListeners();
      if (_needsReloadOnResume || !_player.hasActiveAudio) {
        _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
      } else {
        final sessionId = ++_playSessionId;
        _prefetchUpcomingTurns(
          sessionId,
          _currentTurnIndex + 1,
          effectiveLanguage,
        );
        _player.resume().then((resumed) {
          if (!resumed && _isPlaying && !_isPaused) {
            _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
          }
        });
      }
    } else {
      _player.unlockAudio();
      _player.startKeepAlive();
      final startingFromBeginning =
          _currentTurnIndex == 0 && _withinTurnFraction < 0.05;
      _isPlaying = true;
      _isPaused = false;
      _syncMediaSession();
      notifyListeners();
      _playCurrentTurn(
        withIntroJingle: startingFromBeginning,
        initialSeekFraction: _withinTurnFraction,
      );
    }
  }

  void setDraggingFraction(double value) {
    _draggingOverallFraction = value.clamp(0.0, 1.0);
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
      if (sameTurn && _player.hasActiveAudio && !_isLoadingAudio) {
        _player.seekWithinTurn(targetWithinTurn);
      } else {
        _playCurrentTurn(initialSeekFraction: targetWithinTurn);
      }
    } else if (_isPlaying && _isPaused) {
      if (sameTurn && _player.hasActiveAudio && !_isLoadingAudio) {
        _player.seekWithinTurn(targetWithinTurn);
      } else {
        _needsReloadOnResume = true;
        _player.stop();
        final turn = list[targetTurn];
        _player.prefetchUrl(_buildAudioUrl(turn, effectiveLanguage));
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
    _stopAndReset();
    _prefetchInitialTurns();
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

  IconData _editionIcon(String edition, {required bool isPlaying}) {
    if (isPlaying) {
      return Icons.graphic_eq_rounded;
    }
    switch (edition) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'midday':
        return Icons.light_mode_rounded;
      default:
        return Icons.nights_stay_rounded;
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
        final updatedAgo = timeago.format(
          widget.overview.generatedAt,
          locale: lang,
        );
        final updatedLabel =
            Constants.podcastLastUpdatedLabelFor(updatedAgo, lang);

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
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _editionIcon(edition, isPlaying: isPlayingNow),
                        size: 20,
                        color: const Color(0xFF0F2942),
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
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 12.5,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  updatedLabel,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2942), Color(0xFF1E3A5F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color(0xFFFBBF24),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F2942).withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: const Color(0xFFFBBF24),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        onPressed: _controller.togglePlayPause,
                        child: _controller.isLoadingAudio
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFFBBF24),
                                  ),
                                ),
                              )
                            : Icon(
                                isPlayingNow
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 30,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.5,
                          activeTrackColor: const Color(0xFF0F2942),
                          inactiveTrackColor: const Color(0xFF0F2942)
                              .withValues(alpha: 0.16),
                          thumbColor: const Color(0xFF0F2942),
                          overlayColor: const Color(0xFF0F2942)
                              .withValues(alpha: 0.12),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7.0,
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
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2942).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _controller.formattedRemainingTime,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F2942),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _controller.cycleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0F2942).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF0F2942)
                                .withValues(alpha: 0.16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.speed_rounded,
                              size: 13,
                              color: Color(0xFF0F2942),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${_controller.playbackRate}x',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F2942),
                              ),
                            ),
                          ],
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
