import 'package:flutter/material.dart';
import 'package:urchat/model/chat_room.dart';
import 'package:urchat/service/api_service.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:urchat/utils/animated_emoji_mapper.dart';

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
      //print('❌ Error updating group pfp: $e');
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: isSmallScreen
              ? MediaQuery.of(context).size.width * 0.95
              : isTablet
                  ? 500
                  : 600,
          height: isSmallScreen
              ? MediaQuery.of(context).size.height * 0.7
              : isTablet
                  ? 550
                  : 650,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_emotions,
                        color: colorScheme.onPrimary,
                        size: isSmallScreen ? 20 : 24),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Text(
                        'Select Group Emoji',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: colorScheme.onPrimary,
                          size: isSmallScreen ? 20 : 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Emoji Grid
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: isSmallScreen ? 8 : 12),
                  child: GridView.builder(
                    padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          _getCrossAxisCount(MediaQuery.of(context).size),
                      crossAxisSpacing: isSmallScreen ? 6 : 10,
                      mainAxisSpacing: isSmallScreen ? 6 : 10,
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
                          splashColor: colorScheme.primary.withOpacity(0.2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedPfpIndex == emoji
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: _selectedPfpIndex == emoji ? 3 : 0,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: _selectedPfpIndex == emoji
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : colorScheme.surfaceVariant.withOpacity(0.5),
                            ),
                            child: Center(
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: _getEmojiSize(
                                      MediaQuery.of(context).size),
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

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Close Button
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 14 : 16),
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
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: isSmallScreen
                  ? MediaQuery.of(context).size.width * 0.95
                  : 450,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.palette,
                              color: colorScheme.onPrimary,
                              size: isSmallScreen ? 20 : 24),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Text(
                              'Select Background Color',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: colorScheme.onPrimary,
                                size: isSmallScreen ? 20 : 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Current Selection Preview
                          Container(
                            width: isSmallScreen ? 100 : 120,
                            height: isSmallScreen ? 100 : 120,
                            decoration: BoxDecoration(
                              color: _selectedPfpBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedEmojiMapper.hasAnimatedVersion(
                                      _selectedPfpIndex)
                                  ? AnimatedEmojiMapper.getAnimatedEmojiWidget(
                                        _selectedPfpIndex,
                                        size: isSmallScreen ? 40 : 48,
                                      ) ??
                                      Text(
                                        _selectedPfpIndex,
                                        style: TextStyle(
                                            fontSize: isSmallScreen ? 40 : 48),
                                      )
                                  : Text(
                                      _selectedPfpIndex,
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 40 : 48),
                                    ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 20 : 24),

                          // Color Options Section
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Color Options',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),

                                // Default Colors Grid
                                SizedBox(
                                  height: isSmallScreen ? 120 : 140,
                                  child: GridView.builder(
                                    // physics:
                                    // const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isSmallScreen ? 7 : 8,
                                      crossAxisSpacing: isSmallScreen ? 8 : 10,
                                      mainAxisSpacing: isSmallScreen ? 8 : 10,
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
                                          setDialogState(() {});
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
                                                  ? 3
                                                  : 0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: _selectedPfpBg.value ==
                                                  color.value
                                              ? Icon(
                                                  Icons.check,
                                                  color:
                                                      _getContrastColor(color),
                                                  size: isSmallScreen ? 16 : 20,
                                                )
                                              : null,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                SizedBox(height: isSmallScreen ? 16 : 20),

                                // Custom Color Picker Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _showCustomColorPicker(setDialogState),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 16 : 20,
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                    ),
                                    icon: Icon(Icons.colorize,
                                        size: isSmallScreen ? 18 : 20),
                                    label: Text(
                                      'Custom Color',
                                      style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: isSmallScreen ? 20 : 24),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.onSurface,
                                    padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 14 : 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side:
                                        BorderSide(color: colorScheme.outline),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18),
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                        vertical: isSmallScreen ? 14 : 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    'Apply',
                                    style: TextStyle(
                                        fontSize: isSmallScreen ? 16 : 18),
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
          );
        },
      ),
    );
  }

  void _showCustomColorPicker(StateSetter setDialogState) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Custom Color Picker',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: isSmallScreen ? 20 : 22,
              ),
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: isSmallScreen
                    ? MediaQuery.of(context).size.width * 0.8
                    : 400,
                child: _buildCustomColorPicker(
                    setPickerState, setDialogState, isSmallScreen),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomColorPicker(StateSetter setPickerState,
      StateSetter setDialogState, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color preview
        Container(
          width: isSmallScreen ? 100 : 120,
          height: isSmallScreen ? 100 : 120,
          decoration: BoxDecoration(
            color: _selectedPfpBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _colorToHex(_selectedPfpBg),
              style: TextStyle(
                color: _getContrastColor(_selectedPfpBg),
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 20 : 24),

        // RGB sliders
        _buildColorSlider('Red', _selectedPfpBg.red, (value) {
          setPickerState(() {
            _selectedPfpBg = Color.fromARGB(
              255,
              value.toInt(),
              _selectedPfpBg.green,
              _selectedPfpBg.blue,
            );
          });
          setDialogState(() {});
        }, isSmallScreen),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildColorSlider('Green', _selectedPfpBg.green, (value) {
          setPickerState(() {
            _selectedPfpBg = Color.fromARGB(
              255,
              _selectedPfpBg.red,
              value.toInt(),
              _selectedPfpBg.blue,
            );
          });
          setDialogState(() {});
        }, isSmallScreen),
        SizedBox(height: isSmallScreen ? 12 : 16),
        _buildColorSlider('Blue', _selectedPfpBg.blue, (value) {
          setPickerState(() {
            _selectedPfpBg = Color.fromARGB(
              255,
              _selectedPfpBg.red,
              _selectedPfpBg.green,
              value.toInt(),
            );
          });
          setDialogState(() {});
        }, isSmallScreen),

        SizedBox(height: isSmallScreen ? 20 : 24),

        // Quick color grid
        Text(
          'Quick Colors',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmallScreen ? 6 : 8,
            crossAxisSpacing: isSmallScreen ? 6 : 8,
            mainAxisSpacing: isSmallScreen ? 6 : 8,
          ),
          itemCount: _colorOptions.length,
          itemBuilder: (context, index) {
            final color = _parseColor(_colorOptions[index]);
            return GestureDetector(
              onTap: () {
                setPickerState(() {
                  _selectedPfpBg = color;
                });
                setDialogState(() {});
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
                        size: isSmallScreen ? 16 : 18,
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildColorSlider(String label, int value,
      ValueChanged<double> onChanged, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
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
        sliderColor = colorScheme.primary;
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
                color: colorScheme.onSurface,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            Text(
              value.toString(),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Slider(
          activeColor: sliderColor,
          inactiveColor: colorScheme.outline.withOpacity(0.3),
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

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
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
                padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.photo_camera,
                        color: colorScheme.onPrimary,
                        size: isSmallScreen ? 20 : 24),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: Text(
                        'Group Profile Picture',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_isUpdating)
                      SizedBox(
                        width: isSmallScreen ? 20 : 24,
                        height: isSmallScreen ? 20 : 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.check,
                            color: colorScheme.onPrimary,
                            size: isSmallScreen ? 20 : 24),
                        onPressed: _updateGroupPfp,
                        tooltip: 'Save',
                      ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: colorScheme.onPrimary,
                          size: isSmallScreen ? 20 : 24),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cancel',
                    ),
                  ],
                ),
              ),

              // Current Selection Preview
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
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
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
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
                padding:
                    EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showEmojiPicker,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 14 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        label: Text(
                          'Change Emoji',
                          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 12 : 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showColorPicker,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 14 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        label: Text(
                          'Change Color',
                          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 24 : 32),
            ],
          ),
        ),
      ),
    );
  }

  // Emoji and color options
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
