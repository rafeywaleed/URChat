import 'package:flutter/material.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

// Special text for @mentions
class MentionText extends SpecialText {
  static const String flag = "@";
  final int start;
  final BuildContext context;
  final bool isGroupChat;

  MentionText(
    TextStyle textStyle,
    SpecialTextGestureTapCallback onTap, {
    required this.start,
    required this.context,
    required this.isGroupChat,
  }) : super(flag, " ", textStyle, onTap: onTap);

  @override
  InlineSpan finishText() {
    final String mentionText = toString();
    final String username = mentionText.substring(1).trim();

    return SpecialTextSpan(
      text: mentionText,
      actualText: mentionText,
      start: start,
      style: textStyle?.copyWith(
        color: Colors.blue,
        fontWeight: FontWeight.w600,
        backgroundColor: Colors.blue.withOpacity(0.1),
      ),
      recognizer: (TapGestureRecognizer()
        ..onTap = () {
          // Show a snackbar when @mention is tapped
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mentioned: @$username'),
              duration: const Duration(seconds: 2),
            ),
          );
        }),
    );
  }
}

// Special text for URLs
class UrlText extends SpecialText {
  static const String flag = "http";
  final int start;

  UrlText(TextStyle textStyle, SpecialTextGestureTapCallback onTap,
      {required this.start})
      : super(flag, " ", textStyle, onTap: onTap);

  @override
  bool isEnd(String value) {
    // Simple URL detection - ends with space or end of string
    return value.contains(RegExp(r'\s|$'));
  }

  @override
  InlineSpan finishText() {
    final String urlText = toString().trim();

    return SpecialTextSpan(
      text: urlText,
      actualText: urlText,
      start: start,
      style: textStyle?.copyWith(
        color: Colors.blue,
        decoration: TextDecoration.underline,
      ),
      recognizer: (TapGestureRecognizer()
        ..onTap = () async {
          final uri = Uri.parse(urlText);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }),
    );
  }
}

// Custom text span builder for chat
class ChatSpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  final BuildContext context;
  final bool isGroupChat;

  ChatSpecialTextSpanBuilder({
    required this.context,
    required this.isGroupChat,
  });

  @override
  TextSpan build(String data,
      {TextStyle? textStyle, SpecialTextGestureTapCallback? onTap}) {
    return super.build(data, textStyle: textStyle, onTap: onTap) as TextSpan;
  }

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      int? index}) {
    if (flag == null || flag.isEmpty) return null;

    // Handle @mentions (only in group chats)
    if (isGroupChat && isStart(flag, MentionText.flag)) {
      return MentionText(
        textStyle!,
        onTap!,
        start: index! - (MentionText.flag.length - 1),
        context: context,
        isGroupChat: isGroupChat,
      );
    }

    // Handle URLs
    if (flag.startsWith('http') || flag.startsWith('www.')) {
      return UrlText(
        textStyle!,
        onTap!,
        start: index! - (flag.length - 1),
      );
    }

    return null;
  }
}

// Enhanced chat input field
class EnhancedChatInput extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  final bool isSending;
  final Function() onTypingStart;
  final Function() onTypingStop;
  final bool isGroupChat;

  const EnhancedChatInput({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.onTypingStart,
    required this.onTypingStop,
    required this.isGroupChat,
  }) : super(key: key);

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends State<EnhancedChatInput> {
  late ChatSpecialTextSpanBuilder _spanBuilder;

  final List<String> _emojiList = [
    '😀',
    '😂',
    '🥰',
    '😎',
    '😍',
    '🤔',
    '👍',
    '❤️',
    '🔥',
    '🎉',
    '🙏',
    '😊',
    '🤗',
    '😇',
    '🥳',
    '😭',
    '😡',
    '🤯',
    '😴',
    '🤩'
  ];

  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _spanBuilder = ChatSpecialTextSpanBuilder(
      context: context,
      isGroupChat: widget.isGroupChat,
    );
  }

  void _sendMessage() {
    final message = widget.controller.text.trim();
    if (message.isNotEmpty && !widget.isSending) {
      widget.onSend(message);
      widget.controller.clear();
      setState(() {
        _showEmojiPicker = false;
      });
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    widget.controller.text = newText;
    widget.controller.selection = selection.copyWith(
      baseOffset: selection.start + emoji.length,
      extentOffset: selection.start + emoji.length,
    );
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      widget.onTypingStart();
    } else {
      widget.onTypingStop();
    }
  }

  Widget _buildEmojiPicker() {
    if (!_showEmojiPicker) return const SizedBox.shrink();

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: _emojiList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _insertEmoji(_emojiList[index]),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.background,
              ),
              child: Text(
                _emojiList[index],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Emoji picker button
              IconButton(
                icon: Icon(
                  _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _toggleEmojiPicker,
              ),
              const SizedBox(width: 4),

              // Enhanced text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    maxHeight: 120,
                  ),
                  child: ExtendedTextField(
                    controller: widget.controller,
                    specialTextSpanBuilder: _spanBuilder,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: widget.isSending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              FloatingActionButton(
                onPressed: widget.isSending ? null : _sendMessage,
                child: widget.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),

        // Emoji picker
        _buildEmojiPicker(),
      ],
    );
  }
}
