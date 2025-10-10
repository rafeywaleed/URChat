import 'package:flutter/material.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:urchat_back_testing/utils/animated_emoji_mapper.dart';

class AnimatedEmojiPickerScreen extends StatefulWidget {
  final Function(String emoji) onEmojiSelected;

  const AnimatedEmojiPickerScreen({
    Key? key,
    required this.onEmojiSelected,
  }) : super(key: key);

  @override
  State<AnimatedEmojiPickerScreen> createState() =>
      _AnimatedEmojiPickerScreenState();
}

class _AnimatedEmojiPickerScreenState extends State<AnimatedEmojiPickerScreen> {
  String? _selectedEmoji;
  final ScrollController _scrollController = ScrollController();

  // Group emojis by category for better organization
  final Map<String, List<String>> _emojiCategories = {
    'Smileys & Emotions': [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😭',
      '😉',
      '😗',
      '😙',
      '😚',
      '😘',
      '🥰',
      '😍',
      '🤩',
      '🥳',
      '🫠',
      '🙃',
      '🙂',
      '🥲',
      '🫣',
      '😊',
      '☺️',
      '😌',
      '😏',
      '🤤',
      '😋',
      '😛',
      '😜',
      '😝',
      '🤪',
      '🥴',
      '😔',
      '🥺',
      '😬',
      '😑',
      '😐',
      '😶',
      '🤐',
      '🫡',
      '🤔',
      '🤫',
      '🫢',
      '🤭',
      '🥱',
      '🤗',
      '🫣',
      '😱',
      '🤨',
      '🧐',
      '😒',
      '🙄',
      '😤',
      '😠',
      '😡',
      '🤬',
      '😞',
      '😓',
      '😟',
      '😥',
      '😢',
      '☹️',
      '🙁',
      '🫤',
      '😕',
      '😰',
      '😨',
      '😧',
      '😦',
      '😮',
      '😯',
      '😲',
      '😳',
      '🤯',
      '😖',
      '😣',
      '😩',
      '😫',
      '😵',
      '🫨',
      '🥶',
      '🥵',
      '🤢',
      '🤮',
      '😴',
      '😪',
      '🤧',
      '🤒',
      '🤕',
      '😷',
      '🤥',
      '😇',
      '🤠',
      '🤑',
      '🤓',
      '😎',
      '🥸',
      '🤡',
    ],
    'Hearts & Love': [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '🩵',
      '💙',
      '💜',
      '🤎',
      '🖤',
      '🩶',
      '🤍',
      '🩷',
      '💘',
      '💝',
      '💖',
      '💗',
      '💓',
      '💞',
      '💕',
      '💌',
      '💟',
      '❣️',
      '💔',
      '❤️‍🔥',
      '💋',
    ],
    'Hand Gestures': [
      '👏',
      '👍',
      '👎',
      '🫶',
      '🙌',
      '👐',
      '🤲',
      '🤞',
      '🤙',
      '✊',
      '👊',
      '🫳',
      '🫴',
      '🫱',
      '🫲',
      '🫸',
      '🫷',
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '🤘',
      '✌️',
      '🤌',
      '🤏',
      '👌',
      '🫵',
      '👉',
      '👈',
      '☝️',
      '👆',
      '👇',
      '🖕',
      '✍️',
      '🤳',
      '🙏',
      '💅',
      '🤝',
    ],
    'Animals & Nature': [
      '🐮',
      '🦄',
      '🦎',
      '🐉',
      '🦖',
      '🦕',
      '🐢',
      '🐊',
      '🐍',
      '🐸',
      '🐇',
      '🐀',
      '🐩',
      '🐕',
      '🦮',
      '🐕‍🦺',
      '🐖',
      '🐎',
      '🫏',
      '🐂',
      '🐐',
      '🦘',
      '🐅',
      '🐒',
      '🦍',
      '🦧',
      '🐿️',
      '🦦',
      '🦇',
      '🐦',
      '🐦‍⬛',
      '🐓',
      '🐣',
      '🐤',
      '🐥',
      '🦅',
      '🦉',
      '🕊️',
      '🪿',
      '🦚',
      '🐦‍🔥',
      '🦭',
      '🦈',
      '🐬',
      '🐋',
      '🐟',
      '🐡',
      '🦞',
      '🦀',
      '🐙',
      '🪼',
      '🦂',
      '🕷️',
      '🐌',
      '🐜',
      '🦟',
      '🪳',
      '🪰',
      '🐝',
      '🐞',
      '🦋',
      '🐛',
      '🪱',
      '🐾',
    ],
    'Food & Drink': [
      '🍅',
      '🫚',
      '🍳',
      '🌯',
      '🍝',
      '🍜',
      '🍿',
      '☕',
      '🍻',
      '🥂',
      '🍾',
      '🍷',
      '🫗',
      '🍹',
    ],
    'Activities & Sports': [
      '⚽',
      '⚾',
      '🥎',
      '🎾',
      '🏸',
      '🥍',
      '🏏',
      '🏑',
      '🏒',
      '⛸️',
      '🛼',
      '🩰',
      '🛹',
      '⛳',
      '🎯',
      '🥏',
      '🪃',
      '🪁',
      '🎣',
      '🥋',
      '🎱',
      '🏓',
      '🎳',
      '🎲',
      '🎰',
      '🪄',
    ],
    'Objects & Symbols': [
      '💐',
      '🌹',
      '🥀',
      '🍂',
      '🌱',
      '🍃',
      '🍀',
      '🪹',
      '❄️',
      '🌋',
      '🌅',
      '🌄',
      '🌈',
      '🫧',
      '🌊',
      '💧',
      '🌍',
      '🌎',
      '🌏',
      '☄️',
      '🎈',
      '🎂',
      '🎁',
      '🎆',
      '🪅',
      '🪩',
      '🥇',
      '🥈',
      '🥉',
      '🏆',
      '🚧',
      '🚨',
      '🚲',
      '🚗',
      '🏎️',
      '🚕',
      '🚌',
      '⛵',
      '🛶',
      '🛸',
      '🚀',
      '🛫',
      '🛬',
      '🎢',
      '🎡',
      '🏕️',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Choose Animated Emoji'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Selected emoji preview
          if (_selectedEmoji != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Selected Emoji',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: AnimatedEmoji(
                      AnimatedEmojiMapper.getAnimatedEmoji(_selectedEmoji!)!,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedEmoji!,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            ),
          ],

          // Emoji grid
          Expanded(
            child: _buildEmojiGrid(),
          ),

          // Send button
          if (_selectedEmoji != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onEmojiSelected(_selectedEmoji!);
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Send Emoji',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmojiGrid() {
    return DefaultTabController(
      length: _emojiCategories.keys.length,
      child: Column(
        children: [
          // Category tabs
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: _emojiCategories.keys
                  .map((category) => Tab(text: category))
                  .toList(),
            ),
          ),

          // Emoji grid for each category
          Expanded(
            child: TabBarView(
              children: _emojiCategories.entries.map((category) {
                return _buildCategoryGrid(category.value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<String> emojis) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        final isSelected = _selectedEmoji == emoji;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedEmoji = emoji;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedEmoji(
                  AnimatedEmojiMapper.getAnimatedEmoji(emoji)!,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
