import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:urchat_back_testing/utils/animated_emoji_mapper.dart';

class NesEmojiColorPicker extends StatefulWidget {
  final String initialEmoji;
  final Color initialColor;
  final ValueChanged<String> onEmojiChanged;
  final ValueChanged<Color> onColorChanged;
  final double emojiSize;

  const NesEmojiColorPicker({
    Key? key,
    required this.initialEmoji,
    required this.initialColor,
    required this.onEmojiChanged,
    required this.onColorChanged,
    this.emojiSize = 48.0,
  }) : super(key: key);

  @override
  _NesEmojiColorPickerState createState() => _NesEmojiColorPickerState();
}

class _NesEmojiColorPickerState extends State<NesEmojiColorPicker> {
  late String _selectedEmoji;
  late Color _selectedColor;

  // Popular emojis - using static emojis for selection
  final List<String> emojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '🙃',
    '😉',
    '😌',
    '😍',
    '🥰',
    '😘',
    '😗',
    '😙',
    '😚',
    '😋',
    '😛',
    '😝',
    '😜',
    '🤪',
    '🤨',
    '🧐',
    '🤓',
    '😎',
    '🥸',
    '🤩',
    '🥳',
    '😏',
    '😒',
    '😞',
    '😔',
    '😟',
    '😕',
    '🙁',
    '☹️',
    '😣',
    '😖',
    '😫',
    '😩',
    '🥺',
    '😢',
    '😭',
    '😤',
    '😠',
    '😡',
    '🤬',
    '🤯',
    '😳',
    '🥵',
    '🥶',
    '😱',
    '😨',
    '😰',
    '😥',
    '😓',
    '🤗',
    '🤔',
    '🤭',
    '🤫',
    '🤥',
    '😶',
    '😐',
    '😑',
    '😬',
    '🙄',
    '😯',
    '😦',
    '😧',
    '😮',
    '😲',
    '🥱',
    '😴',
    '🤤',
    '😪',
    '😵',
    '🤐',
    '🥴',
    '🤢',
    '🤮',
    '🤧',
    '😷',
    '🤒',
    '🤕',
    '🤑',
    '🤠',
    '😈',
    '👿',
    '👹',
    '👺',
    '🤡',
    '💩',
    '👻',
    '💀',
    '☠️',
    '👽',
    '👾',
    '🤖',
    '🎃',
    '😺',
    '😸',
    '😹',
    '😻',
    '😼',
    '😽',
    '🙀',
    '😿',
    '😾',
    '🙈',
    '🙉',
    '🙊',
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '💯',
    '💢',
    '💥',
    '💫',
    '💦',
    '💨',
    '🎈',
    '🎉',
    '🎊',
    '🎁',
    '🏆',
    '🥇',
    '🥈',
    '🥉',
    '⚽',
    '🏀',
    '🏈',
    '⚾',
    '🥎',
    '🎾',
    '🏐',
    '🏉',
    '🥏',
    '🎱',
    '🪀',
    '🏓',
    '🏸',
    '🏒',
    '🏑',
    '🥍',
    '🎿',
    '⛷️',
    '🏂',
    '🪂',
    '🧘',
    '🏄',
    '🏊',
    '🚣',
    '🧗',
    '🚴',
    '🎯',
    '🎮',
    '🎲',
    '🎰',
    '🎳',
    '🤹',
    '🎭',
    '🩰',
    '🎨',
    '🎬',
    '🎤',
    '🎧',
    '🎼',
    '🎹',
    '🥁',
    '🪘',
    '🎷',
    '🎺',
    '🪗',
    '🎸',
    '🪕',
    '🎻',
    '🐵',
    '🐒',
    '🦍',
    '🦧',
    '🐶',
    '🐕',
    '🦮',
    '🐕‍🦺',
    '🐩',
    '🐺',
    '🦊',
    '🦝',
    '🐱',
    '🐈',
    '🐈‍⬛',
    '🦁',
    '🐯',
    '🐅',
    '🐆',
    '🐴',
    '🐎',
    '🦄',
    '🦓',
    '🦌',
    '🐮',
    '🐂',
    '🐃',
    '🐄',
    '🐷',
    '🐖',
    '🐗',
    '🐏',
    '🐑',
    '🐐',
    '🐪',
    '🐫',
    '🦙',
    '🦒',
    '🐘',
    '🦏',
    '🦛',
    '🐭',
    '🐁',
    '🐀',
    '🐹',
    '🐰',
    '🐇',
    '🐿️',
    '🦫',
    '🦔',
    '🦇',
    '🐻',
    '🐻‍❄️',
    '🐨',
    '🐼',
    '🦥',
    '🦦',
    '🦨',
    '🦘',
    '🦡',
    '🐾',
    '🦃',
    '🐔',
    '🐓',
    '🐣',
    '🐤',
    '🐥',
    '🐦',
    '🐧',
    '🕊️',
    '🦅',
    '🦆',
    '🦢',
    '🦉',
    '🦩',
    '🦚',
    '🦜',
    '🐸',
    '🐊',
    '🐢',
    '🦎',
    '🐍',
    '🐲',
    '🐉',
    '🦕',
    '🦖',
    '🐳',
    '🐋',
    '🐬',
    '🦭',
    '🐟',
    '🐠',
    '🐡',
    '🦈',
    '🐙',
    '🐚',
    '🐌',
    '🦋',
    '🐛',
    '🐜',
    '🐝',
    '🪲',
    '🐞',
    '🦗',
    '🪳',
    '🕷️',
    '🕸️',
    '🦂',
    '🦟',
    '🪰',
    '🪱',
    '🦠',
    '💐',
    '🌸',
    '💮',
    '🏵️',
    '🌹',
    '🥀',
    '🌺',
    '🌻',
    '🌼',
    '🌷',
    '🌱',
    '🪴',
    '🌲',
    '🌳',
    '🌴',
    '🌵',
    '🌾',
    '🌿',
    '☘️',
    '🍀',
    '🍁',
    '🍂',
    '🍃',
    '🍇',
    '🍈',
    '🍉',
    '🍊',
    '🍋',
    '🍌',
    '🍍',
    '🥭',
    '🍎',
    '🍏',
    '🍐',
    '🍑',
    '🍒',
    '🍓',
    '🫐',
    '🥝',
    '🍅',
    '🫒',
    '🥥',
    '🥑',
    '🍆',
    '🥔',
    '🥕',
    '🌽',
    '🌶️',
    '🫑',
    '🥒',
    '🥬',
    '🥦',
    '🧄',
    '🧅',
    '🍄',
    '🥜',
    '🫘',
    '🌰',
    '🍞',
    '🥐',
    '🥖',
    '🫓',
    '🥨',
    '🥯',
    '🥞',
    '🧇',
    '🧀',
    '🍖',
    '🍗',
    '🥩',
    '🥓',
    '🍔',
    '🍟',
    '🍕',
    '🌭',
    '🥪',
    '🌮',
    '🌯',
    '🫔',
    '🥙',
    '🧆',
    '🥚',
    '🍳',
    '🥘',
    '🍲',
    '🫕',
    '🥣',
    '🥗',
    '🍿',
    '🧈',
    '🧂',
    '🥫',
    '🍱',
    '🍘',
    '🍙',
    '🍚',
    '🍛',
    '🍜',
    '🍝',
    '🍠',
    '🍢',
    '🍣',
    '🍤',
    '🍥',
    '🥮',
    '🍡',
    '🥟',
    '🥠',
    '🥡',
    '🦀',
    '🦞',
    '🦐',
    '🦑',
    '🦪',
    '🍦',
    '🍧',
    '🍨',
    '🍩',
    '🍪',
    '🎂',
    '🍰',
    '🧁',
    '🥧',
    '🍫',
    '🍬',
    '🍭',
    '🍮',
    '🍯',
    '🍼',
    '🥛',
    '☕',
    '🫖',
    '🍵',
    '🍶',
    '🍾',
    '🍷',
    '🍸',
    '🍹',
    '🍺',
    '🍻',
    '🥂',
    '🥃',
    '🥤',
    '🧋',
    '🧃',
    '🧉',
    '🧊'
  ];

  // Default color palette that matches NES theme
  final List<Color> defaultColors = [
    Color(0xFF4CAF50), // Green
    Color(0xFF2196F3), // Blue
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF8BC34A), // Light Green
    Color(0xFFFFC107), // Amber
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
    Color(0xFFE91E63), // Pink
    Color(0xFF5C4033), // Brown (NES theme)
  ];

  @override
  void initState() {
    super.initState();
    _selectedEmoji = widget.initialEmoji;
    _selectedColor = widget.initialColor;
  }

  void _showEmojiPicker() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isLargeScreen = screenSize.width >= 1200;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isSmallScreen
              ? screenSize.width * 0.9
              : isTablet
                  ? 500
                  : 600,
          height: isSmallScreen
              ? screenSize.height * 0.7
              : isTablet
                  ? 550
                  : 650,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(bottom: BorderSide(color: Colors.black)),
                ),
                child: Center(
                  child: Text(
                    'Select Emoji',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    padding: EdgeInsets.all(4),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(screenSize),
                      crossAxisSpacing: isSmallScreen ? 6 : 8,
                      mainAxisSpacing: isSmallScreen ? 6 : 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (context, index) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedEmoji = emojis[index];
                            });
                            widget.onEmojiChanged(_selectedEmoji);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(8),
                          splashColor: Colors.blue.withOpacity(0.3),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedEmoji == emojis[index]
                                    ? Colors.blue
                                    : Colors.grey.withOpacity(0.3),
                                width: _selectedEmoji == emojis[index] ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: _selectedEmoji == emojis[index]
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.05),
                            ),
                            child: Center(
                              child: Text(
                                emojis[index],
                                style: TextStyle(
                                  fontSize: _getEmojiSize(screenSize),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.black),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getCrossAxisCount(Size screenSize) {
    if (screenSize.width < 400) return 5;
    if (screenSize.width < 600) return 6;
    if (screenSize.width < 900) return 7;
    return 8;
  }

  double _getEmojiSize(Size screenSize) {
    if (screenSize.width < 400) return 28;
    if (screenSize.width < 600) return 32;
    if (screenSize.width < 900) return 36;
    return 40;
  }

  void _showColorPicker() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(// ADDED: StatefulBuilder to update the dialog state
              builder: (context, setDialogState) {
        return NesDialog(
          child: Container(
            width: isSmallScreen ? 320 : 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NesContainer(
                    child: Text('Select Background Color',
                        style: TextStyle(fontSize: 13)),
                  ),
                  SizedBox(height: 16),

                  // Current Selection Preview
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child:
                          AnimatedEmojiMapper.hasAnimatedVersion(_selectedEmoji)
                              ? AnimatedEmojiMapper.getAnimatedEmojiWidget(
                                    _selectedEmoji,
                                    size: 40,
                                  ) ??
                                  Text(
                                    _selectedEmoji,
                                    style: TextStyle(fontSize: 40),
                                  )
                              : Text(
                                  _selectedEmoji,
                                  style: TextStyle(fontSize: 40),
                                ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Custom Color Picker
                  NesContainer(
                    child: Column(
                      children: [
                        Text(
                          'Custom Color',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 12),
                        Column(
                          children: [
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _selectedColor,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.black, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  _colorToHex(_selectedColor),
                                  style: TextStyle(
                                    color: _getContrastColor(_selectedColor),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height:
                                    12), // CHANGED: Added SizedBox for vertical spacing
                            NesButton(
                              type: NesButtonType.normal,
                              onPressed: () => _showColorPickerDialog(
                                  setDialogState), // CHANGED: Pass setDialogState
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.colorize, size: 16),
                                  SizedBox(width: 4),
                                  Text('Pick Color'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Default Colors
                  NesContainer(
                    child: Column(
                      children: [
                        Text(
                          'Default Colors',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 12),
                        Container(
                          height: 140,
                          child: GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isSmallScreen ? 6 : 8,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: defaultColors.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = defaultColors[index];
                                  });
                                  widget.onColorChanged(_selectedColor);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: defaultColors[index],
                                    border: Border.all(
                                      color:
                                          _selectedColor == defaultColors[index]
                                              ? Colors.white
                                              : Colors.transparent,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  child: _selectedColor == defaultColors[index]
                                      ? Icon(Icons.check,
                                          color: _getContrastColor(
                                              defaultColors[index]),
                                          size: 20)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),
                  NesButton(
                    type: NesButtonType.primary,
                    onPressed: () {
                      widget.onColorChanged(_selectedColor);
                      Navigator.pop(context);
                    },
                    child: Text('Apply Color'),
                  ),
                  SizedBox(height: 8),
                  NesButton(
                    type: NesButtonType.normal,
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showColorPickerDialog(StateSetter setDialogState) async {
    // CHANGED: Accept setDialogState parameter
    Color? pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick a Color',
            style: TextStyle(
              fontSize: 12,
            )),
        content: SingleChildScrollView(
          child: ColorPicker(
            onColorChanged: (color) {
              // Update both the main state and the dialog state
              setState(() {
                _selectedColor = color;
              });
              setDialogState(() {}); // CHANGED: Trigger dialog rebuild
              widget
                  .onColorChanged(color); // CHANGED: Call callback immediately
            },
            pickerColor: _selectedColor,
            enableLabel: true,
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          NesButton(
            type: NesButtonType.normal,
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          NesButton(
            type: NesButtonType.primary,
            onPressed: () {
              Navigator.pop(context, _selectedColor);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );

    if (pickedColor != null) {
      setState(() {
        _selectedColor = pickedColor;
      });
      widget.onColorChanged(_selectedColor);
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate the perceptive luminance (human eye favors green color)
    double luminance = (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;

    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        // Preview Section
        NesContainer(
          child: Column(
            children: [
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              Container(
                width: isSmallScreen ? 90 : 120,
                height: isSmallScreen ? 90 : 120,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  borderRadius: BorderRadius.circular(12),
                  // border: Border.all(color: Colors.black, width: 3),
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.black26,
                  //     blurRadius: 8,
                  //     offset: Offset(2, 2),
                  //   ),
                  // ],
                ),
                child: Center(
                  child: AnimatedEmojiMapper.hasAnimatedVersion(_selectedEmoji)
                      ? AnimatedEmojiMapper.getAnimatedEmojiWidget(
                            _selectedEmoji,
                            size: isSmallScreen ? 40 : widget.emojiSize,
                          ) ??
                          Text(
                            _selectedEmoji,
                            style: TextStyle(
                                fontSize:
                                    isSmallScreen ? 40 : widget.emojiSize),
                          )
                      : Text(
                          _selectedEmoji,
                          style: TextStyle(
                              fontSize: isSmallScreen ? 40 : widget.emojiSize),
                        ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                _colorToHex(_selectedColor),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Selection Buttons
        isSmallScreen
            ? Column(
                children: [
                  NesButton(
                    type: NesButtonType.normal,
                    onPressed: _showEmojiPicker,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_emotions, size: 16),
                        SizedBox(width: 8),
                        Text('Change Emoji'),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  NesButton(
                    type: NesButtonType.normal,
                    onPressed: _showColorPicker,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.palette, size: 16),
                        SizedBox(width: 8),
                        Text('Change Color'),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: NesButton(
                      type: NesButtonType.normal,
                      onPressed: _showEmojiPicker,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_emotions, size: 16),
                          SizedBox(width: 8),
                          Text('Change Emoji'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: NesButton(
                      type: NesButtonType.normal,
                      onPressed: _showColorPicker,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.palette, size: 16),
                          SizedBox(width: 8),
                          Text('Change Color'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}

// Simple Color Picker Widget
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool enableLabel;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    this.enableLabel = true,
    this.pickerAreaHeightPercent = 0.7,
  }) : super(key: key);

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.pickerColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 400,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Color preview
            Container(
              padding: EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Center(
                child: Text(
                  _colorToHex(_currentColor),
                  style: TextStyle(
                    color: _getContrastColor(_currentColor),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // RGB sliders
            _buildColorSlider('Red', _currentColor.red, (value) {
              setState(() {
                _currentColor = Color.fromARGB(
                  255,
                  value.toInt(),
                  _currentColor.green,
                  _currentColor.blue,
                );
              });
              widget.onColorChanged(
                  _currentColor); // CHANGED: Call callback immediately
            }),
            _buildColorSlider('Green', _currentColor.green, (value) {
              setState(() {
                _currentColor = Color.fromARGB(
                  255,
                  _currentColor.red,
                  value.toInt(),
                  _currentColor.blue,
                );
              });
              widget.onColorChanged(
                  _currentColor); // CHANGED: Call callback immediately
            }),
            _buildColorSlider('Blue', _currentColor.blue, (value) {
              setState(() {
                _currentColor = Color.fromARGB(
                  255,
                  _currentColor.red,
                  _currentColor.green,
                  value.toInt(),
                );
              });
              widget.onColorChanged(
                  _currentColor); // CHANGED: Call callback immediately
            }),

            SizedBox(height: 20),

            // Quick color grid
            Text('Quick Colors', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _quickColors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentColor = _quickColors[index];
                    });
                    widget.onColorChanged(
                        _currentColor); // CHANGED: Call callback immediately
                  },
                  child: Container(
                    color: _quickColors[index],
                    child: _currentColor.value == _quickColors[index].value
                        ? Icon(Icons.check,
                            color: _getContrastColor(_quickColors[index]),
                            size: 16)
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSlider(
      String label, int value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        Slider(
          activeColor: label == 'Red'
              ? Colors.red
              : label == 'Green'
                  ? Colors.green
                  : Colors.blue,
          inactiveColor: Colors.grey.shade400,
          value: value.toDouble(),
          min: 0,
          max: 255,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    double luminance = (0.299 * backgroundColor.red +
            0.587 * backgroundColor.green +
            0.114 * backgroundColor.blue) /
        255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  final List<Color> _quickColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.lime,
    Colors.amber,
    Colors.brown,
    Colors.grey,
    Colors.black,
    Colors.white,
    Colors.indigo,
    Colors.deepOrange,
    Colors.lightBlue,
  ];
}
