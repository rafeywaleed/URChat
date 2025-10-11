import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/utils/animated_emoji_mapper.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String username;

  const OtherUserProfileScreen({Key? key, required this.username})
      : super(key: key);

  @override
  _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isAddingToChat = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await ApiService.getUserProfile(widget.username);
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user profile'),
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

  void _addToChat() async {
    setState(() {
      _isAddingToChat = true;
    });

    try {
      // Create chat with the user
      final chat = await ApiService.createIndividualChat(widget.username);

      // Return the chat to the previous screen
      Navigator.of(context).pop(chat);
    } catch (e) {
      print('Error adding to chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isAddingToChat = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if NesTheme is available, if not wrap with NesTheme
    final nesTheme = Theme.of(context).extension<NesTheme>();

    if (nesTheme == null) {
      // return NesTheme(
      //   child: _buildContent(),
      // );
    }

    return _buildContent();
  }

  @override
  Widget _buildContent() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF5C4033),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
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
                    // Profile Picture Section
                    _buildProfilePictureSection(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 24 : 32),

                    // User Info Section
                    _buildUserInfoSection(isSmallScreen),
                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Action Button
                    _buildActionButton(isSmallScreen),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection(bool isSmallScreen) {
    final pfpEmoji = _userData?['pfpIndex'] ?? '😊';
    final bgColor = _hexToColor(_userData?['pfpBg'] ?? '#4CAF50');

    return Column(
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
            backgroundColor: bgColor,
            radius: isSmallScreen ? 48 : 56,
            child: AnimatedEmojiMapper.hasAnimatedVersion(pfpEmoji)
                ? AnimatedEmojiMapper.getAnimatedEmojiWidget(
                      pfpEmoji,
                      size: isSmallScreen ? 36 : 48,
                    ) ??
                    Text(
                      pfpEmoji,
                      style: TextStyle(fontSize: isSmallScreen ? 36 : 48),
                    )
                : Text(
                    pfpEmoji,
                    style: TextStyle(fontSize: isSmallScreen ? 36 : 48),
                  ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          _userData?['fullName'] ?? widget.username,
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 4),
        Text(
          '@${_userData?['username'] ?? widget.username}',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(bool isSmallScreen) {
    final nesContainerTheme = Theme.of(context).extension<NesContainerTheme>();

    if (nesContainerTheme == null) {
      // Fallback container using Material Design
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Full Name',
              Text(
                _userData?['fullName'] ?? 'Not set',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: (_userData?['fullName'] ?? '').isEmpty
                      ? Colors.grey[400]
                      : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildInfoRow(
              'Bio',
              Text(
                _userData?['bio'] ?? 'Hello! I am using URChat',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: (_userData?['bio'] ?? '').isEmpty
                      ? Colors.grey[400]
                      : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
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

    // Original NesContainer implementation
    return NesContainer(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            'Full Name',
            Text(
              _userData?['fullName'] ?? 'Not set',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: (_userData?['fullName'] ?? '').isEmpty
                    ? Colors.grey[400]
                    : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
            isSmallScreen,
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),
          _buildInfoRow(
            'Bio',
            Text(
              _userData?['bio'] ?? 'Hello! I am using URChat',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: (_userData?['bio'] ?? '').isEmpty
                    ? Colors.grey[400]
                    : Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
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

  Widget _buildActionButton(bool isSmallScreen) {
    final nesTheme = Theme.of(context).extension<NesTheme>();

    if (nesTheme == null) {
      // Fallback buttons using Material Design
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAddingToChat ? null : _addToChat,
              child: _isAddingToChat
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: NesHourglassLoadingIndicator(),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: isSmallScreen ? 16 : 18),
                        SizedBox(width: 8),
                        Text(
                          'Start Chat',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Original NesButton implementation
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: NesButton(
            type: NesButtonType.primary,
            onPressed: _isAddingToChat ? null : _addToChat,
            child: _isAddingToChat
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat, size: isSmallScreen ? 16 : 18),
                      SizedBox(width: 8),
                      Text(
                        'Start Chat',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        SizedBox(
          width: double.infinity,
          child: NesButton(
            type: NesButtonType.normal,
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
