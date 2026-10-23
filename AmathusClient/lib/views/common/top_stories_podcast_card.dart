import 'package:amathus/models/overview.dart';
import 'package:amathus/utils/constants.dart' as Constants;
import 'package:amathus/views/common/flag_icon.dart';
import 'package:amathus/views/common/podcast_audio_player.dart';
import 'package:flutter/material.dart';

class TopStoriesPodcastCard extends StatefulWidget {
  final NewsOverview overview;
  final String defaultLanguage;
  final bool isColumnists;
  final void Function(OverviewStory story)? onOpenStory;

  const TopStoriesPodcastCard({
    super.key,
    required this.overview,
    required this.defaultLanguage,
    this.isColumnists = false,
    this.onOpenStory,
  });

  @override
  State<TopStoriesPodcastCard> createState() => _TopStoriesPodcastCardState();
}

class _TopStoriesPodcastCardState extends State<TopStoriesPodcastCard>
    with AutomaticKeepAliveClientMixin {
  final PodcastAudioPlayer _player = PodcastAudioPlayer();

  @override
  bool get wantKeepAlive => true;

  String? _selectedLanguage;
  int _currentTurnIndex = 0;
  double _withinTurnFraction = 0.0;
  double? _draggingOverallFraction;
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _needsReloadOnResume = false;
  int _playSessionId = 0;
  double _playbackRate = 1.0;

  @override
  void initState() {
    super.initState();
    _player.onEnded = _handleTurnEnded;
    _player.onError = _handleTurnError;
    _player.onPositionFractionChanged = (fraction) {
      if (!mounted || _draggingOverallFraction != null) return;
      setState(() {
        _withinTurnFraction = fraction.clamp(0.0, 1.0);
      });
    };
  }

  @override
  void didUpdateWidget(covariant TopStoriesPodcastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultLanguage != widget.defaultLanguage) {
      _selectedLanguage = null;
      if (_isPlaying && !_isPaused) {
        _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String get _effectiveLanguage {
    final lang = _selectedLanguage ?? widget.defaultLanguage;
    if (lang == 'el' || lang == 'tr' || lang == 'en') {
      return lang;
    }
    return 'en';
  }

  String get _effectiveEdition {
    return widget.overview.effectiveEdition;
  }

  List<PodcastDialogueTurn> get _turns {
    return widget.overview.turnsForEdition(_effectiveEdition);
  }

  double get _overallProgress {
    if (_draggingOverallFraction != null) {
      return _draggingOverallFraction!.clamp(0.0, 1.0);
    }
    final turns = _turns;
    if (turns.isEmpty) return 0.0;
    final safeIdx = _currentTurnIndex.clamp(0, turns.length - 1);
    return ((safeIdx + _withinTurnFraction.clamp(0.0, 1.0)) / turns.length)
        .clamp(0.0, 1.0);
  }

  String _buildAudioUrl(PodcastDialogueTurn turn, String lang) {
    final text = turn.textFor(lang);
    final speaker = turn.isHostA ? 'A' : 'B';
    return '${Constants.URL_PODCAST_AUDIO}'
        '?lang=${Uri.encodeQueryComponent(lang)}'
        '&speaker=${Uri.encodeQueryComponent(speaker)}'
        '&text=${Uri.encodeQueryComponent(text)}';
  }

  Future<void> _handleTurnEnded() async {
    if (!mounted || !_isPlaying) return;
    final turns = _turns;
    if (_currentTurnIndex + 1 < turns.length) {
      setState(() {
        _currentTurnIndex++;
        _withinTurnFraction = 0.0;
      });
      await _playCurrentTurn();
    } else {
      // Play broadcast news outro jingle at the end of the podcast
      await _player.playOutroJingle(playbackRate: _playbackRate);
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _isPaused = false;
        _currentTurnIndex = 0;
        _withinTurnFraction = 0.0;
      });
    }
  }

  void _handleTurnError() {
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _isPaused = false;
    });
  }

  Future<void> _playCurrentTurn({
    bool withIntroJingle = false,
    double initialSeekFraction = 0.0,
  }) async {
    final turns = _turns;
    if (turns.isEmpty) return;
    if (_currentTurnIndex < 0 || _currentTurnIndex >= turns.length) {
      _currentTurnIndex = 0;
    }

    final sessionId = ++_playSessionId;
    _needsReloadOnResume = false;

    final currentTurn = turns[_currentTurnIndex];
    final lang = _effectiveLanguage;
    final url = _buildAudioUrl(currentTurn, lang);

    if (withIntroJingle) {
      // Prefetch Turn 0 while the 2.0s news intro jingle plays so speech starts with zero delay
      _player.prefetchUrl(url);
      await _player.playIntroJingle(playbackRate: _playbackRate);
      if (!mounted ||
          !_isPlaying ||
          _isPaused ||
          sessionId != _playSessionId) {
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

    if (!mounted || !_isPlaying || sessionId != _playSessionId) return;

    // Prefetch the next turn slightly after current turn starts so we never open concurrent WebSockets
    if (_currentTurnIndex + 1 < turns.length) {
      final nextTurn = turns[_currentTurnIndex + 1];
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || !_isPlaying || sessionId != _playSessionId) return;
        _player.prefetchUrl(_buildAudioUrl(nextTurn, _effectiveLanguage));
      });
    }
  }

  void _togglePlayPause() {
    final turns = _turns;
    if (turns.isEmpty) return;

    if (_isPlaying && !_isPaused) {
      _playSessionId++;
      _player.pause();
      setState(() {
        _isPaused = true;
      });
    } else if (_isPlaying && _isPaused) {
      setState(() {
        _isPaused = false;
      });
      if (_needsReloadOnResume || !_player.hasActiveAudio) {
        _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
      } else {
        _player.resume().then((resumed) {
          if (!resumed && mounted && _isPlaying && !_isPaused) {
            _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
          }
        });
      }
    } else {
      final startingFromBeginning =
          _currentTurnIndex == 0 && _withinTurnFraction < 0.05;
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
      _playCurrentTurn(
        withIntroJingle: startingFromBeginning,
        initialSeekFraction: _withinTurnFraction,
      );
    }
  }

  void _seekToOverallFraction(double overallFraction) {
    final turns = _turns;
    if (turns.isEmpty) return;

    final clamped = overallFraction.clamp(0.0, 0.999);
    final scaled = clamped * turns.length;
    final targetTurn = scaled.floor().clamp(0, turns.length - 1);
    final targetWithinTurn = (scaled - targetTurn).clamp(0.0, 0.98);

    final sameTurn = targetTurn == _currentTurnIndex;
    setState(() {
      _draggingOverallFraction = null;
      _currentTurnIndex = targetTurn;
      _withinTurnFraction = targetWithinTurn;
    });

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
      // Not playing yet: prefetch the target turn so clicking Play starts immediately
      _needsReloadOnResume = true;
      final turn = turns[targetTurn];
      _player.prefetchUrl(_buildAudioUrl(turn, _effectiveLanguage));
    }
  }

  void _cycleSpeed() {
    final nextRate = _playbackRate == 1.0
        ? 1.25
        : (_playbackRate == 1.25 ? 1.5 : 1.0);
    setState(() {
      _playbackRate = nextRate;
    });
    _player.setPlaybackRate(nextRate);
  }

  void _selectLanguage(String lang) {
    if (_effectiveLanguage == lang) return;
    setState(() {
      _selectedLanguage = lang;
    });
    if (_isPlaying && !_isPaused) {
      _playCurrentTurn(initialSeekFraction: _withinTurnFraction);
    } else if (_isPlaying && _isPaused) {
      _needsReloadOnResume = true;
      _player.stop();
    }
  }

  IconData _editionIcon(String edition) {
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
    final turns = _turns;
    if (turns.isEmpty) {
      return const SizedBox.shrink();
    }

    final lang = _effectiveLanguage;
    final edition = _effectiveEdition;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2942), Color(0xFF1E3A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2942).withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFBBF24).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          _editionIcon(edition),
                          size: 20,
                          color: const Color(0xFFFBBF24),
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
                                color: Colors.white,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              Constants.podcastSubtitleFor(edition, lang),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.84),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _PodcastLanguageDropdown(
                  selectedLanguage: lang,
                  onSelected: _selectLanguage,
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
                      backgroundColor: const Color(0xFFFBBF24),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    onPressed: _togglePlayPause,
                    child: Icon(
                      (_isPlaying && !_isPaused)
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
                      activeTrackColor: const Color(0xFFFBBF24),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.22),
                      thumbColor: const Color(0xFFFBBF24),
                      overlayColor:
                          const Color(0xFFFBBF24).withValues(alpha: 0.18),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6.5,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: Slider(
                      value: _overallProgress,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (value) {
                        setState(() {
                          _draggingOverallFraction = value;
                        });
                      },
                      onChangeEnd: _seekToOverallFraction,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_playbackRate}x',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
  }
}

class _PodcastLanguageDropdown extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onSelected;

  const _PodcastLanguageDropdown({
    required this.selectedLanguage,
    required this.onSelected,
  });

  static const List<(String, String)> _languages = [
    ('el', 'Ελληνικά'),
    ('tr', 'Türkçe'),
    ('en', 'English'),
  ];

  String _labelFor(String code) {
    for (final entry in _languages) {
      if (entry.$1 == code) return entry.$2;
    }
    return 'English';
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: Constants.READ_IN_BUTTON,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final entry in _languages)
          PopupMenuItem<String>(
            value: entry.$1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlagIcon(languageCode: entry.$1, width: 20, height: 14),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.$2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedLanguage == entry.$1
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (selectedLanguage == entry.$1) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Color(0xFF1D4ED8),
                  ),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlagIcon(languageCode: selectedLanguage, width: 18, height: 13),
            const SizedBox(width: 6),
            Text(
              _labelFor(selectedLanguage),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}
