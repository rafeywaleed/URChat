import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:urchat_back_testing/model/user.dart';
import 'package:urchat_back_testing/screens/home_screen.dart';
import 'package:urchat_back_testing/screens/user_profile.dart';

import 'package:urchat_back_testing/service/api_service.dart';
import 'package:urchat_back_testing/utils/chat_navigation_helper.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchUsers(query.trim());
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.searchUsers(query);
      setState(() {
        _searchResults = results.cast<User>();
        _isSearching = false;
      });
    } catch (e) {
      print("❌ Search error: $e");
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _startChat(User user) async {
    try {
      final chat = await ApiService.createIndividualChat(user.username);

      NavigationHelper.navigateToChat(context, user.username);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to start chat: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewProfile(User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OtherUserProfileScreen(
          username: user.username,
          fromChat: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

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
        backgroundColor: const Color(0xFF5C4033),
        title: NesContainer(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: const Color.fromARGB(255, 0, 0, 0),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  autofocus: true,
                  scrollPadding: EdgeInsets.all(2),
                  controller: _searchController,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search users...",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear,
                      size: 18, color: const Color.fromARGB(255, 0, 0, 0)),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers("");
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tight(Size(24, 24)),
                ),
            ],
          ),
        ),
        elevation: 2,
      ),
      body: _buildBody(isSmallScreen, theme),
    );
  }

  Widget _buildBody(bool isSmallScreen, ThemeData theme) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NesPixelRowLoadingIndicator(count: 5),
            const SizedBox(height: 16),
            Text(
              "Searching...",
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState(isSmallScreen);
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState(isSmallScreen);
    }

    return _buildResultsList(isSmallScreen);
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NesIcon(
              iconData: NesIcons.owl,
              // size: isSmallScreen ? 48 : 64,
              primaryColor: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "Search for Users",
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Find people by username to start chatting",
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NesIcon(
              iconData: NesIcons.user,
              // size: isSmallScreen ? 48 : 64,
              primaryColor: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No Users Found",
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Try searching with a different username or name",
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(bool isSmallScreen) {
    return ListView.separated(
      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => SizedBox(height: isSmallScreen ? 8 : 12),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final bgColor = _parseColor(user.pfpBg);

        return NesContainer(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Row(
            children: [
              // Profile Avatar
              GestureDetector(
                onTap: () => _viewProfile(user),
                child: Container(
                  width: isSmallScreen ? 48 : 56,
                  height: isSmallScreen ? 48 : 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Hero(
                    tag: "user_avatar_${user.username}",
                    child: CircleAvatar(
                      backgroundColor: bgColor,
                      child: Text(
                        user.pfpIndex,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),

              // User Info
              Expanded(
                child: GestureDetector(
                  onTap: () => _viewProfile(user),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "@${user.username}",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              _buildActionButtons(user, isSmallScreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(User user, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile Button
        NesButton(
          type: NesButtonType.normal,
          onPressed: () => _viewProfile(user),
          child: Icon(
            Icons.person_outline,
            size: isSmallScreen ? 16 : 18,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),

        // Chat Button
        NesButton(
          type: NesButtonType.primary,
          onPressed: () => _startChat(user),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: isSmallScreen ? 14 : 16,
              ),
              if (!isSmallScreen) ...[
                SizedBox(width: 6),
                Text(
                  "Chat",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF' + hexColor;
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Color(0xFF4CAF50); // Default fallback color
    }
  }
}
