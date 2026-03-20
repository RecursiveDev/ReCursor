import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputSheet extends StatefulWidget {
  final void Function(String text) onSend;

  const VoiceInputSheet({super.key, required this.onSend});

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  final _speech = stt.SpeechToText();
  bool _listening = false;
  String _transcript = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startListening();
  }

  Future<void> _startListening() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
          _pulseController.stop();
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
        _pulseController.stop();
      },
    );
    if (!available) return;

    await _speech.listen(
      onResult: (result) {
        if (mounted) {
          setState(() => _transcript = result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    if (mounted) setState(() => _listening = true);
    unawaited(_pulseController.repeat(reverse: true));
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    _pulseController.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF252526),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Transform.scale(
              scale: _listening ? _pulseAnimation.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _listening
                    ? const Color(0xFF569CD6).withValues(alpha: 0.2)
                    : const Color(0xFF3C3C3C),
                border: Border.all(
                  color: _listening ? const Color(0xFF569CD6) : Colors.grey,
                  width: 2,
                ),
              ),
              child: Icon(
                _listening ? Icons.mic : Icons.mic_off,
                color: _listening ? const Color(0xFF569CD6) : Colors.grey,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _listening ? 'Listening…' : 'Tap mic to start',
            style: TextStyle(
              color: _listening ? const Color(0xFF569CD6) : Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _transcript.isEmpty
                  ? 'Your words will appear here…'
                  : _transcript,
              style: TextStyle(
                color: _transcript.isEmpty ? Colors.grey : Colors.white,
                fontStyle:
                    _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _transcript.isEmpty
                      ? null
                      : () {
                          _stopListening();
                          widget.onSend(_transcript);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF569CD6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
