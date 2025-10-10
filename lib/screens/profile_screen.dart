import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/widgets/pfp_selector.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> emojis = [
    '😊',
    '😂',
    '🥰',
    '😎',
    '🤩',
    '🧐',
    '😋',
    '🤠',
    '😍',
    '🥳',
    '🤖',
    '👻',
    '🐱',
    '🐶',
    '🦊',
    '🐼'
  ];
  final List<Color> bgColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF8BC34A),
    Color(0xFFFFC107),
    Color(0xFFFF5722),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFE91E63),
    Color(0xFF4CAF50),
  ];

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF5C4033),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.close),
              onPressed: _cancelEdit,
            ),
        ],
      ),
      body: _isLoading && _userData == null
          ? Center(child: CircularProgressIndicator(color: Color(0xFF5C4033)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  // Profile Picture Section
                  _buildProfilePictureSection(),
                  SizedBox(height: 32),

                  // User Info Section
                  _buildUserInfoSection(),
                  SizedBox(height: 24),

                  // Action Button
                  _buildActionButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 120,
              height: 120,
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
                radius: 56,
                child: Text(
                  _selectedEmoji,
                  style: TextStyle(fontSize: 48),
                ),
              ),
            ),
            if (_isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF5C4033),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.edit, color: Colors.white, size: 18),
                    onPressed: _showProfileCustomization,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          _userData?['username'] ?? ApiService.currentUsername ?? 'Unknown',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 4),
        Text(
          _email ??
              'user@example.com', // You might need to get email from auth or another endpoint
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Full Name',
              _buildEditableField(_fullNameController, 'Full Name')),
          SizedBox(height: 20),
          _buildInfoRow(
              'Bio', _buildEditableField(_bioController, 'Bio', maxLines: 3)),
          SizedBox(height: 20),
          _buildInfoRow(
            'Member Since',
            Text(
              _formatJoinedAt(_userData?['joinedAt']?.toString()),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildEditableField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return _isEditing
        ? TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF5C4033)),
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          )
        : Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              controller.text.isEmpty ? 'Not set' : controller.text,
              style: TextStyle(
                fontSize: 16,
                color: controller.text.isEmpty
                    ? Colors.grey[400]
                    : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF5C4033),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                _isEditing ? 'Save Changes' : 'Edit Profile',
                style: TextStyle(
                  fontSize: 16,
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
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                    padding: EdgeInsets.all(16),
                    child: NesEmojiColorPicker(
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
                      emojiSize: 48,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
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
