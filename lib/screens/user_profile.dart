import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:animated_emoji/animated_emoji.dart';
import 'package:urchat_back_testing/screens/home_screen.dart';
import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/utils/animated_emoji_mapper.dart';
import 'package:urchat_back_testing/utils/chat_navigation_helper.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String username;
  final bool fromChat;
  final ThemeData? chatTheme; // Optional chat theme

  const OtherUserProfileScreen({
    Key? key,
    required this.username,
    required this.fromChat,
    this.chatTheme, // Add optional chat theme parameter
  }) : super(key: key);

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
      print('🎯 Creating chat with ${widget.username}');
      final chat = await ApiService.createIndividualChat(widget.username);
      NavigationHelper.navigateToChat(context, widget.username);
    } catch (e) {
      print('❌ Error creating chat: $e');
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
    // If coming from chat with a theme, use that theme
    if (widget.fromChat && widget.chatTheme != null) {
      return Theme(
        data: widget.chatTheme!,
        child: _buildContent(),
      );
    }

    // If coming from chat without theme, use default
    if (widget.fromChat) {
      return _buildContent();
    }

    // If not from chat, check if NesTheme is available
    final nesTheme = Theme.of(context).extension<NesTheme>();
    if (nesTheme == null) {
      // return NesTheme(
      //   child: _buildContent(),
      // );
    }

    return _buildContent();
  }

  Widget _buildContent() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: widget.fromChat ? colorScheme.onPrimary : Colors.black,
          ),
        ),
        backgroundColor: widget.fromChat ? colorScheme.primary : Colors.white,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        leading: !widget.fromChat
            ? Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 0),
                child: NesIconButton(
                  icon: NesIcons.leftArrowIndicator,
                  onPress: () => Navigator.pop(context),
                ),
              )
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _isLoading
          ? Center(
              child: widget.fromChat
                  ? CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    )
                  : NesPixelRowLoadingIndicator(count: 3),
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

                    // Action Button - Only show if not from chat
                    if (!widget.fromChat) _buildActionButton(isSmallScreen),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfilePictureSection(bool isSmallScreen) {
    final pfpEmoji = _userData?['pfpIndex'] ?? '😊';
    final bgColor = _hexToColor(_userData?['pfpBg'] ?? '#4CAF50');
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: isSmallScreen ? 100 : 120,
          height: isSmallScreen ? 100 : 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Hero(
            tag: widget.fromChat
                ? "user_avatar_${widget.username}"
                : "chat_avatar_${widget.username}",
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
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        Text(
          _userData?['fullName'] ?? widget.username,
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '@${_userData?['username'] ?? widget.username}',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection(bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;

    // If from chat, use themed Material Design containers
    if (widget.fromChat) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
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
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.onSurface,
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
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.onSurface,
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
                  color: colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              isSmallScreen,
            ),
          ],
        ),
      );
    }

    // If not from chat, use NesContainer if available, otherwise fallback
    final nesContainerTheme = Theme.of(context).extension<NesContainerTheme>();
    if (nesContainerTheme == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.onSurface,
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
                      ? colorScheme.onSurface.withOpacity(0.4)
                      : colorScheme.onSurface,
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
                  color: colorScheme.onSurface.withOpacity(0.8),
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
                    ? colorScheme.onSurface.withOpacity(0.4)
                    : colorScheme.onSurface,
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
                    ? colorScheme.onSurface.withOpacity(0.4)
                    : colorScheme.onSurface,
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
                color: colorScheme.onSurface.withOpacity(0.8),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        content,
      ],
    );
  }

  Widget _buildActionButton(bool isSmallScreen) {
    // This method is only called when not from chat
    final nesTheme = Theme.of(context).extension<NesTheme>();
    final colorScheme = Theme.of(context).colorScheme;

    if (nesTheme == null) {
      // Fallback buttons using Material Design with theme colors
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAddingToChat ? null : _addToChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding:
                    EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
              ),
              child: _isAddingToChat
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary),
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
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                side: BorderSide(color: colorScheme.primary),
              ),
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
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
            child: Center(
              child: Text(
                'Back',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
