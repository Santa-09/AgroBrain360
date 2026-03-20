import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/ai_case_chat_args.dart';
import '../../services/ai_chat_service.dart';
import '../../services/language_service.dart';
import '../../services/voice_service.dart';

class AiCaseChatScreen extends StatefulWidget {
  final AiCaseChatArgs args;
  const AiCaseChatScreen({super.key, required this.args});

  @override
  State<AiCaseChatScreen> createState() => _AiCaseChatScreenState();
}

class _AiCaseChatScreenState extends State<AiCaseChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatBubbleData> _messages = [];
  bool _sending = false;
  bool _listening = false;

  String tr(String key, String fallback) {
    final value = LangSvc().t(key);
    return value == key ? fallback : value;
  }

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatBubbleData.bot(
        tr(
          'aiHelpWelcome',
          'I can explain this case in simple steps. Ask about the problem, treatment, prevention, or next action.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    unawaited(VoiceSvc().stop());
    super.dispose();
  }

  Future<void> _send() async {
    final question = _inputCtrl.text.trim();
    if (question.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatBubbleData.user(question));
      _sending = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    final response = await AiChatSvc().askCase(
      module: widget.args.module,
      question: question,
      context: {
        ...widget.args.context,
        'conversation_history': _messages
            .map(
              (msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'text': msg.text,
              },
            )
            .toList(),
      },
      language: LangSvc().lang,
    );

    if (!mounted) return;

    if (response.ok && response.data != null) {
      final payload =
          response.data!['data'] as Map<String, dynamic>? ?? response.data!;
      final answer = (payload['ai_response'] ?? '').toString().trim();
      setState(() {
        _messages.add(
          _ChatBubbleData.bot(
            answer.isEmpty
                ? tr('analysisFailedRetry', 'Analysis failed. Try again.')
                : answer,
          ),
        );
        _sending = false;
      });
      _scrollToBottom();
    } else {
      setState(() {
        _messages.add(
          _ChatBubbleData.bot(
            response.error ??
                tr('analysisFailedRetry', 'Analysis failed. Try again.'),
          ),
        );
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await VoiceSvc().stop();
      if (mounted) {
        setState(() => _listening = false);
      }
      return;
    }

    setState(() => _listening = true);
    final started = await VoiceSvc().listen(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _inputCtrl.text = text;
          _listening = false;
        });
      },
      lang: LangSvc().lang,
    );

    if (!started && mounted) {
      setState(() => _listening = false);
      H.snack(
        context,
        tr('voiceUnavailable', 'Voice input is unavailable right now'),
        error: true,
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _summaryLines() {
    final summary = <String>[];
    widget.args.context.forEach((key, value) {
      if (value == null) return;
      final text = value is List ? value.join(', ') : value.toString();
      if (text.trim().isEmpty) return;
      if (key == 'image_url') return;
      summary.add('${key.replaceAll('_', ' ')}: $text');
    });
    return summary.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.args.imagePath;
    final summary = _summaryLines();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          tr(
            widget.args.module == 'assistant' ? 'aiHelpCenter' : 'aiAdvisory',
            widget.args.module == 'assistant' ? 'AI Help Center' : 'AI Advisory',
          ),
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.args.title,
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (imagePath != null && imagePath.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(imagePath),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summary
                        .map(
                          (line) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFaint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              line,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _Bubble(
                    text: tr('loading', 'Thinking...'),
                    isUser: false,
                  );
                }
                final msg = _messages[index];
                return _Bubble(text: msg.text, isUser: msg.isUser);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: tr(
                        'aiHelpHint',
                        'Ask about problem, treatment, or prevention',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleVoice,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color:
                          _listening ? AppColors.danger : AppColors.primaryFaint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _listening ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _messages.any((msg) => !msg.isUser)
          ? FloatingActionButton.small(
              backgroundColor: AppColors.amber,
              onPressed: () async {
                final botText = _messages.lastWhere((m) => !m.isUser).text;
                await VoiceSvc().setLang(LangSvc().lang);
                await VoiceSvc().speak(botText);
              },
              child: const Icon(Icons.volume_up_rounded),
            )
          : null,
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const _Bubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: isUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.5,
            color: isUser ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ChatBubbleData {
  final String text;
  final bool isUser;

  const _ChatBubbleData._(this.text, this.isUser);

  factory _ChatBubbleData.user(String text) => _ChatBubbleData._(text, true);
  factory _ChatBubbleData.bot(String text) => _ChatBubbleData._(text, false);
}
