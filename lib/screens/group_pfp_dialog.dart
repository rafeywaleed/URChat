import 'package:flutter/material.dart';
import 'package:urchat_back_testing/model/ChatRoom.dart';
import 'package:urchat_back_testing/service/api_service.dart';

class GroupPfpDialog extends StatefulWidget {
  final ChatRoom group;

  const GroupPfpDialog({Key? key, required this.group}) : super(key: key);

  @override
  _GroupPfpDialogState createState() => _GroupPfpDialogState();
}

class _GroupPfpDialogState extends State<GroupPfpDialog> {
  late String _selectedPfpIndex;
  late String _selectedPfpBg;
  bool _isUpdating = false;

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
    '🌟'
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
    '#82E0AA'
  ];

  @override
  void initState() {
    super.initState();
    _selectedPfpIndex = widget.group.pfpIndex;
    _selectedPfpBg = widget.group.pfpBg;
  }

  Future<void> _updateGroupPfp() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedGroup = await ApiService.updateGroupPfp(
        widget.group.chatId,
        _selectedPfpIndex,
        _selectedPfpBg,
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF5C4033),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Group Profile Picture',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_isUpdating)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              padding: const EdgeInsets.all(24),
              child: CircleAvatar(
                backgroundColor: _parseColor(_selectedPfpBg),
                radius: 40,
                child: Text(
                  _selectedPfpIndex,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),

            // Emoji Selection
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select Emoji',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojiOptions.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPfpIndex = emoji;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedPfpIndex == emoji
                            ? _parseColor(_selectedPfpBg).withOpacity(0.3)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: _selectedPfpIndex == emoji
                            ? Border.all(
                                color: _parseColor(_selectedPfpBg), width: 2)
                            : null,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Color Selection
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select Background Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colorOptions.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPfpBg = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _parseColor(color),
                        borderRadius: BorderRadius.circular(20),
                        border: _selectedPfpBg == color
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
