import 'dart:async';
import 'package:flutter/material.dart';
import 'package:urchat_back_testing/model/user.dart';
import 'package:urchat_back_testing/service/api_service.dart';

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

  /// Debounced search
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
      Navigator.pop(context, chat);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error starting chat: $e")),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF5C4033),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: "Search users...",
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                _searchController.clear();
                _searchUsers("");
              },
            ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _hasSearched
                          ? "No users found"
                          : "🔍 Search for people to start a chat",
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final bgColor = Color(
                      int.parse(user.pfpBg.replaceAll("#", "0xFF")),
                    );

                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: bgColor,
                        child: Text(
                          user.pfpIndex,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      title: Text(
                        user.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        "@${user.username}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C4033),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text("Chat"),
                        onPressed: () => _startChat(user),
                      ),
                      onTap: () => _startChat(user),
                    );
                  },
                ),
    );
  }
}
