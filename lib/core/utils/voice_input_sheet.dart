import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:kutchina/core/constants/app_theme.dart';

class _Lang {
  final String label;
  final String locale; // speech recognizer locale
  final TranslateLanguage ml; // ML Kit translate language
  const _Lang(this.label, this.locale, this.ml);
}

// Add more here if needed (must be supported by ML Kit translate).
const _langs = <_Lang>[
  _Lang('English', 'en_IN', TranslateLanguage.english),
  _Lang('हिंदी', 'hi_IN', TranslateLanguage.hindi),
  _Lang('বাংলা', 'bn_IN', TranslateLanguage.bengali),
  _Lang('தமிழ்', 'ta_IN', TranslateLanguage.tamil),
  _Lang('తెలుగు', 'te_IN', TranslateLanguage.telugu),
  _Lang('मराठी', 'mr_IN', TranslateLanguage.marathi),
  _Lang('ગુજરાતી', 'gu_IN', TranslateLanguage.gujarati),
  _Lang('ಕನ್ನಡ', 'kn_IN', TranslateLanguage.kannada),
  _Lang('اردو', 'ur_PK', TranslateLanguage.urdu),
];

int _lastLangIndex = 1; // remember last choice (default Hindi)

/// Returns English text, or null if cancelled.
Future<String?> showVoiceInputSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => const _VoiceInputSheet(),
  );
}

enum _VoiceState { listening, translating, error }

class _VoiceInputSheet extends StatefulWidget {
  const _VoiceInputSheet();

  @override
  State<_VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<_VoiceInputSheet> {
  static const _barCount = 30;

  final SpeechToText _speech = SpeechToText();
  final List<double> _bars = List.filled(_barCount, 0.05);
  _VoiceState _state = _VoiceState.listening;
  String _error = '';
  String _heard = '';
  int _langIndex = _lastLangIndex;
  bool _ready = false;

  _Lang get _lang => _langs[_langIndex];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _ready = await _speech.initialize(
        onError: (e) {
          // "no match" / timeout are common; just show retry
          if (_state == _VoiceState.listening)
            _fail('Could not hear. Try again.');
        },
      );
      if (!_ready) {
        _fail('Microphone / speech permission denied');
        return;
      }
      await _listen();
    } catch (_) {
      _fail('Could not start voice input');
    }
  }

  Future<void> _listen() async {
    _heard = '';
    setState(() => _state = _VoiceState.listening);
    await _speech.listen(
      localeId: _lang.locale,
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 8),
      onSoundLevelChange: (level) {
        // Android ~ -2..10, iOS ~ -50..0 → normalise to 0..1
        final v = level < -10 ? (level + 50) / 50 : (level + 2) / 12;
        if (!mounted) return;
        setState(() {
          _bars.removeAt(0);
          _bars.add(v.clamp(0.05, 1.0));
        });
      },
      onResult: (r) {
        if (!mounted) return;
        setState(() => _heard = r.recognizedWords);
      },
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> _changeLang(int i) async {
    if (i == _langIndex) return;
    await _speech.cancel();
    setState(() => _langIndex = i);
    _lastLangIndex = i;
    await _listen();
  }

  Future<void> _done() async {
    await _speech.stop();
    // give recognizer a moment to deliver the final result
    await Future.delayed(const Duration(milliseconds: 500));
    final spoken = _heard.trim();
    if (spoken.isEmpty) return _fail('Could not hear anything. Try again.');

    // English already → no translate needed
    if (_lang.ml == TranslateLanguage.english) {
      if (mounted) Navigator.pop(context, spoken);
      return;
    }

    setState(() => _state = _VoiceState.translating);
    OnDeviceTranslator? translator;
    try {
      // First time per language: downloads small model (~30MB), needs internet once.
      final manager = OnDeviceTranslatorModelManager();
      for (final l in [_lang.ml, TranslateLanguage.english]) {
        if (!await manager.isModelDownloaded(l.bcpCode)) {
          await manager.downloadModel(l.bcpCode);
        }
      }
      translator = OnDeviceTranslator(
        sourceLanguage: _lang.ml,
        targetLanguage: TranslateLanguage.english,
      );
      final english = (await translator.translateText(spoken)).trim();
      if (english.isEmpty) return _fail('Translation empty. Try again.');
      if (mounted) Navigator.pop(context, english);
    } catch (_) {
      _fail(
        'Translate failed. Check internet for first-time language download.',
      );
    } finally {
      translator?.close();
    }
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() {
      _state = _VoiceState.error;
      _error = msg;
    });
  }

  Future<void> _cancel() async {
    await _speech.cancel();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            switch (_state) {
              _VoiceState.listening => 'Listening…',
              _VoiceState.translating => 'Translating to English…',
              _VoiceState.error => 'Oops',
            },
            style: const TextStyle(
              fontFamily: 'Sora',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // language chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _langs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChoiceChip(
                label: Text(
                  _langs[i].label,
                  style: const TextStyle(fontSize: 12),
                ),
                selected: i == _langIndex,
                selectedColor: AppColors.redLight,
                onSelected: _state == _VoiceState.translating
                    ? null
                    : (_) => _changeLang(i),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 70,
            child: switch (_state) {
              _VoiceState.translating => const Center(
                child: CircularProgressIndicator(color: AppColors.red),
              ),
              _VoiceState.error => Center(
                child: Text(_error, textAlign: TextAlign.center),
              ),
              _VoiceState.listening => _Wave(bars: _bars),
            },
          ),

          // live heard text
          if (_heard.isNotEmpty && _state != _VoiceState.error) ...[
            const SizedBox(height: 8),
            Text(
              _heard,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.steel),
            ),
          ],
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _state == _VoiceState.translating ? null : _cancel,
                  child: Text(_state == _VoiceState.error ? 'Close' : 'Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                  onPressed: switch (_state) {
                    _VoiceState.listening => _done,
                    _VoiceState.error => () {
                      _ready ? _listen() : _init();
                    },
                    _VoiceState.translating => null,
                  },
                  icon: Icon(
                    _state == _VoiceState.error
                        ? Icons.refresh
                        : Icons.stop_rounded,
                  ),
                  label: Text(_state == _VoiceState.error ? 'Retry' : 'Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Wave extends StatelessWidget {
  final List<double> bars;
  const _Wave({required this.bars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final b in bars)
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 5,
            height: 6 + b * 60,
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
