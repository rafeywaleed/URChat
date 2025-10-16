import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/utils/animated_emoji_mapper.dart';
import 'package:urchat_back_testing/widgets/pfp_selector.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;
  late String _selectedEmoji;
  late Color _selectedBgColor;
  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _bioController = TextEditingController();
    _selectedEmoji = '😊';
    _selectedBgColor = Color(0xFF4CAF50);
    _email = "Email not available";
    _loadUserData();
  }

  void _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await ApiService.getCurrentUserProfile();
      setState(() {
        _userData = userData;
        _fullNameController.text = userData['fullName'] ?? '';
        _bioController.text = userData['bio'] ?? 'Hello! I am using URChat';
        _selectedEmoji = userData['pfpIndex'] ?? '😊';
        _email = userData['email'] ?? "Email not available";

        // Convert hex color to Color object
        final String hexColor = userData['pfpBg'] ?? '#4CAF50';
        _selectedBgColor = _hexToColor(hexColor);

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load profile data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _hexToColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Color(0xFF4CAF50); // Default color if parsing fails
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  void _updateProfile() async {
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.updateProfile({
        'fullName': _fullNameController.text,
        'bio': _bioController.text,
        'pfpIndex': _selectedEmoji,
        'pfpBg': _colorToHex(_selectedBgColor),
      });

      // Reload data to ensure we have the latest from server
      _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    // Reset to original data
    _loadUserData();
  }

  String _formatJoinedAt(String? joinedAt) {
    if (joinedAt == null) return 'Recently';

    try {
      final dateTime = DateTime.parse(joinedAt);
      return '${_getMonthName(dateTime.month)} ${dateTime.year}';
    } catch (e) {
      return 'Recently';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 2, 2),
          child: NesIconButton(
            icon: NesIcons.leftArrowIndicator,
            onPress: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: NesIconButton(
                icon: NesIcons.close,
                onPress: () => _cancelEdit,
              ),
            ),
        ],
      ),
      body: _isLoading && _userData == null
          ? const Center(
              child: NesPixelRowLoadingIndicator(
                count: 3,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  children: [
                    _buildProfilePictureSection(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    _buildUserInfoSection(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 20 : 24),
                    _buildActionButton(isSmallScreen),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection(bool isSmallScreen) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: isSmallScreen ? 100 : 120,
              height: isSmallScreen ? 100 : 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: _selectedBgColor,
                radius: isSmallScreen ? 48 : 56,
                child: AnimatedEmojiMapper.hasAnimatedVersion(_selectedEmoji)
                    ? AnimatedEmojiMapper.getAnimatedEmojiWidget(
                          _selectedEmoji,
                          size: isSmallScreen ? 36 : 48,
                        ) ??
                        Text(
                          _selectedEmoji,
                          style: TextStyle(fontSize: isSmallScreen ? 36 : 48),
                        )
                    : Text(
                        _selectedEmoji,
                        style: TextStyle(fontSize: isSmallScreen ? 36 : 48),
                      ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: isSmallScreen ? 32 : 40,
                  height: isSmallScreen ? 32 : 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF5C4033),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: isSmallScreen ? 14 : 18,
                    ),
                    onPressed: _showProfileCustomization,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          _userData?['username'] ?? ApiService.currentUsername ?? 'Unknown',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 4),
        Text(
          _email ?? 'user@example.com',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(bool isSmallScreen) {
    return NesContainer(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Full Name',
            _buildEditableField(
                _fullNameController, 'Full Name', isSmallScreen),
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildInfoRow(
            'Bio',
            _buildEditableField(_bioController, 'Bio', isSmallScreen,
                maxLines: 3),
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildInfoRow(
            'Member Since',
            Text(
              _formatJoinedAt(_userData?['joinedAt']?.toString()),
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget content, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        content,
      ],
    );
  }

  Widget _buildEditableField(
    TextEditingController controller,
    String hint,
    bool isSmallScreen, {
    int maxLines = 1,
  }) {
    return _isEditing
        ? TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : 16,
                vertical: isSmallScreen ? 10 : 12,
              ),
            ),
          )
        : NesContainer(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 10 : 12,
            ),
            child: Text(
              controller.text.isEmpty ? 'Not set' : controller.text,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: controller.text.isEmpty
                    ? Colors.grey[400]
                    : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
  }

  Widget _buildActionButton(bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      child: NesButton(
        type: NesButtonType.primary,
        onPressed: _isLoading ? null : _updateProfile,
        child: _isLoading
            ? NesHourglassLoadingIndicator()
            : Text(
                _isEditing ? 'Save Changes' : 'Edit Profile',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showProfileCustomization() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isSmallScreen = MediaQuery.of(context).size.width < 600;
        return Container(
          height:
              MediaQuery.of(context).size.height * (isSmallScreen ? 0.8 : 0.7),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: NesContainer(
            child: Column(
              children: [
                SizedBox(height: 16),
                Text(
                  'Customize Profile',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: NesEmojiColorPicker(
                      // CHANGED: Use the new improved picker
                      initialEmoji: _selectedEmoji,
                      initialColor: _selectedBgColor,
                      onEmojiChanged: (emoji) {
                        setState(() {
                          _selectedEmoji = emoji;
                        });
                      },
                      onColorChanged: (color) {
                        setState(() {
                          _selectedBgColor = color;
                        });
                      },
                      emojiSize: isSmallScreen ? 36 : 48,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: NesButton(
                    type: NesButtonType.normal,
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
