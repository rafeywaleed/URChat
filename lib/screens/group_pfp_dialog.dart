import 'package:flutter/material.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:urchat_back_testing/utils/animated_emoji_mapper.dart';

class GroupPfpDialog extends StatefulWidget {
  final ChatRoom group;

  const GroupPfpDialog({Key? key, required this.group}) : super(key: key);

  @override
  _GroupPfpDialogState createState() => _GroupPfpDialogState();
}

class _GroupPfpDialogState extends State<GroupPfpDialog> {
  late String _selectedPfpIndex;
  late Color _selectedPfpBg;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedPfpIndex = widget.group.pfpIndex;
    _selectedPfpBg = _parseColor(widget.group.pfpBg);
  }

  Future<void> _updateGroupPfp() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedGroup = await ApiService.updateGroupPfp(
        widget.group.chatId,
        _selectedPfpIndex,
        _colorToHex(_selectedPfpBg),
      );

      Navigator.of(context).pop(updatedGroup);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group profile picture updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error updating group pfp: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  void _showEmojiPicker() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;

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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Select Group Emoji',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar (optional - you can add this later)
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: TextField(
              //     decoration: InputDecoration(
              //       hintText: 'Search emojis...',
              //       prefixIcon: Icon(Icons.search),
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 16),

              // Emoji Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getCrossAxisCount(screenSize),
                      crossAxisSpacing: isSmallScreen ? 6 : 8,
                      mainAxisSpacing: isSmallScreen ? 6 : 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _emojiOptions.length,
                    itemBuilder: (context, index) {
                      final emoji = _emojiOptions[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedPfpIndex = emoji;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          splashColor:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPfpIndex == emoji
                                    ? Theme.of(context).primaryColor
                                    : Colors.transparent,
                                width: _selectedPfpIndex == emoji ? 3 : 0,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedPfpIndex == emoji
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1)
                                  : Theme.of(context).hoverColor,
                              boxShadow: _selectedPfpIndex == emoji
                                  ? [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                emoji,
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
              const SizedBox(height: 16),

              // Close Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
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

  void _showColorPicker() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isSmallScreen ? 340 : 400,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Select Background Color',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Current Selection Preview
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: _selectedPfpBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedEmojiMapper.hasAnimatedVersion(
                                  _selectedPfpIndex)
                              ? AnimatedEmojiMapper.getAnimatedEmojiWidget(
                                    _selectedPfpIndex,
                                    size: 50,
                                  ) ??
                                  Text(
                                    _selectedPfpIndex,
                                    style: const TextStyle(fontSize: 50),
                                  )
                              : Text(
                                  _selectedPfpIndex,
                                  style: const TextStyle(fontSize: 50),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Custom Color Picker Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).hoverColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Custom Color',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Color Preview
                            Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: _selectedPfpBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _colorToHex(_selectedPfpBg),
                                  style: TextStyle(
                                    color: _getContrastColor(_selectedPfpBg),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Custom Color Picker Button
                            ElevatedButton.icon(
                              onPressed: _showCustomColorPicker,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              icon: const Icon(Icons.colorize, size: 20),
                              label: const Text(
                                'Pick Custom Color',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Default Colors Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).hoverColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Default Colors',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.color,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 160,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isSmallScreen ? 6 : 8,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: _colorOptions.length,
                                itemBuilder: (context, index) {
                                  final color =
                                      _parseColor(_colorOptions[index]);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPfpBg = color;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        color: color,
                                        border: Border.all(
                                          color: _selectedPfpBg.value ==
                                                  color.value
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: _selectedPfpBg.value ==
                                                  color.value
                                              ? 4
                                              : 0,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: _selectedPfpBg.value == color.value
                                          ? Icon(
                                              Icons.check,
                                              color: _getContrastColor(color),
                                              size: 24,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                'Apply Color',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor,
                                foregroundColor: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(fontSize: 16),
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
          ),
        ),
      ),
    );
  }

  void _showCustomColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Custom Color Picker',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: _buildCustomColorPicker(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColorPicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color preview
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _selectedPfpBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _colorToHex(_selectedPfpBg),
              style: TextStyle(
                color: _getContrastColor(_selectedPfpBg),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // RGB sliders
        _buildColorSlider('Red', _selectedPfpBg.red, (value) {
          setState(() {
            _selectedPfpBg = Color.fromARGB(
              255,
              value.toInt(),
              _selectedPfpBg.green,
              _selectedPfpBg.blue,
            );
          });
        }),
        const SizedBox(height: 16),
        _buildColorSlider('Green', _selectedPfpBg.green, (value) {
          setState(() {
            _selectedPfpBg = Color.fromARGB(
              255,
              _selectedPfpBg.red,
              value.toInt(),
              _selectedPfpBg.blue,
            );
          });
        }),
        const SizedBox(height: 16),
        _buildColorSlider('Blue', _selectedPfpBg.blue, (value) {
          setState(() {
            _selectedPfpBg = Color.fromARGB(
              255,
              _selectedPfpBg.red,
              _selectedPfpBg.green,
              value.toInt(),
            );
          });
        }),

        const SizedBox(height: 24),

        // Quick color grid
        Text(
          'Quick Colors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _colorOptions.length,
          itemBuilder: (context, index) {
            final color = _parseColor(_colorOptions[index]);
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPfpBg = color;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedPfpBg.value == color.value
                        ? Colors.white
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _selectedPfpBg.value == color.value
                    ? Icon(
                        Icons.check,
                        color: _getContrastColor(color),
                        size: 18,
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorSlider(
      String label, int value, ValueChanged<double> onChanged) {
    Color sliderColor;
    switch (label) {
      case 'Red':
        sliderColor = Colors.red;
        break;
      case 'Green':
        sliderColor = Colors.green;
        break;
      case 'Blue':
        sliderColor = Colors.blue;
        break;
      default:
        sliderColor = Theme.of(context).primaryColor;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          activeColor: sliderColor,
          inactiveColor: Colors.grey.shade400,
          thumbColor: Colors.white,
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

  int _getCrossAxisCount(Size screenSize) {
    if (screenSize.width < 400) return 4;
    if (screenSize.width < 600) return 5;
    if (screenSize.width < 900) return 6;
    return 7;
  }

  double _getEmojiSize(Size screenSize) {
    if (screenSize.width < 400) return 28;
    if (screenSize.width < 600) return 32;
    if (screenSize.width < 900) return 36;
    return 40;
  }

  // Keep your existing _emojiOptions and _colorOptions lists...

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isSmallScreen ? 350 : 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_camera, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      'Group Profile Picture',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_isUpdating)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.white),
                        onPressed: _updateGroupPfp,
                        tooltip: 'Save',
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              ),

              // Current Selection Preview
              Padding(
                padding: const EdgeInsets.all(32),
                child: Container(
                  width: isSmallScreen ? 80 : 100,
                  height: isSmallScreen ? 80 : 100,
                  decoration: BoxDecoration(
                    color: _selectedPfpBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedEmojiMapper.hasAnimatedVersion(
                            _selectedPfpIndex)
                        ? AnimatedEmojiMapper.getAnimatedEmojiWidget(
                              _selectedPfpIndex,
                              size: isSmallScreen ? 32 : 40,
                            ) ??
                            Text(
                              _selectedPfpIndex,
                              style:
                                  TextStyle(fontSize: isSmallScreen ? 32 : 40),
                            )
                        : Text(
                            _selectedPfpIndex,
                            style: TextStyle(fontSize: isSmallScreen ? 32 : 40),
                          ),
                  ),
                ),
              ),

              // Selection Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showEmojiPicker,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 16 : 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        icon: Icon(Icons.emoji_emotions,
                            size: isSmallScreen ? 18 : 20),
                        label: Text(
                          'Change Emoji',
                          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showColorPicker,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 16 : 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        icon:
                            Icon(Icons.palette, size: isSmallScreen ? 18 : 20),
                        label: Text(
                          'Change Color',
                          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Keep your existing _emojiOptions and _colorOptions lists here...
  final List<String> _emojiOptions = [
    '👥',
    '👪',
    '🏠',
    '🎮',
    '🎯',
    '🎨',
    '📚',
    '🎵',
    '⚽',
    '🎭',
    '🚀',
    '🌟',
    '💼',
    '🎓',
    '🏆',
    '🎪',
    '🎬',
    '🎤',
    '🎧',
    '🎼',
    '🏀',
    '⚾',
    '🎾',
    '🏐',
    '🏈',
    '🎳',
    '🎱',
    '🛶',
    '⛺',
    '🎄',
    '🎁',
    '🎉',
    '🎊',
    '🛍️',
    '📱',
    '💻',
    '🖥️',
    '📷',
    '🎥',
    '📺',
    '🔊',
    '📞',
    '💡',
    '🔦',
    '🏮',
    '📔',
    '📚',
    '🎒',
    '✏️',
    '📝',
    '📌',
    '📍',
    '📎',
    '✂️',
    '📏',
    '📐',
    '🧮',
    '🔍',
    '🔎',
    '💊',
    '💉',
    '🩺',
    '🌡️',
    '🩹',
    '🧴',
    '🧼',
    '🪒',
    '🧽',
    '🛁',
    '🚿',
    '🧻',
    '🎀',
    '🎗️',
    '👑',
    '💍',
    '💎',
    '🔑',
    '🗝️',
    '💸',
    '💰',
    '🪙',
    '💳',
    '🧾',
    '✉️',
    '📧',
    '📨',
    '📩',
    '📤',
    '📥',
    '📦',
    '📫',
    '📪',
    '📬',
    '📭',
    '🗳️',
    '✒️',
    '🖋️',
    '🖊️',
    '🖌️',
    '🖍️',
    '📁',
    '📂',
    '🗂️',
    '📅',
    '📆',
    '🗒️',
    '🗓️',
    '📇',
    '📈',
    '📉',
    '📊',
    '📋',
    '🖇️',
    '🗃️',
    '🗄️',
    '🗑️',
    '🔒',
    '🔓',
    '🔏',
    '🔐',
    '🔨',
    '🪓',
    '⛏️',
    '⚒️',
    '🛠️',
    '🗡️',
    '⚔️',
    '🔫',
    '🏹',
    '🛡️',
    '🔧',
    '🔩',
    '⚙️',
    '🗜️',
    '⚖️',
    '🔗',
    '⛓️',
    '⚗️',
    '🔬',
    '🔭',
    '📡',
    '🩸',
    '🚪',
    '🛏️',
    '🛋️',
    '🪑',
    '🚽',
    '🪠',
    '🧷',
    '🧹',
    '🧺',
    '🧯',
    '🛒',
    '🚬',
    '⚰️',
    '⚱️',
    '🗿',
    '🪦',
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

  final List<String> _colorOptions = [
    '#FF6B6B',
    '#4ECDC4',
    '#45B7D1',
    '#96CEB4',
    '#FFEAA7',
    '#DDA0DD',
    '#98D8C8',
    '#F7DC6F',
    '#BB8FCE',
    '#85C1E9',
    '#F8C471',
    '#82E0AA',
    '#4CAF50',
    '#2196F3',
    '#FF9800',
    '#F44336',
    '#9C27B0',
    '#673AB7',
    '#3F51B5',
    '#00BCD4',
    '#009688',
    '#8BC34A',
    '#FFC107',
    '#FF5722',
    '#795548',
    '#607D8B',
    '#E91E63',
    '#5C4033'
  ];
}
