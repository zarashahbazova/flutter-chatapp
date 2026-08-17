import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Lafla/themes/tema1.dart';
import '../../services/api_client.dart';

class SingleChatDialog extends StatefulWidget {
  final ApiClient api;
  final String token;
  final int currentUserId;
  final Function(String username) onCreateChat;

  const SingleChatDialog({
    super.key,
    required this.api,
    required this.token,
    required this.currentUserId,
    required this.onCreateChat,
  });

  @override
  State<SingleChatDialog> createState() => _SingleChatDialogState();
}

class _SingleChatDialogState extends State<SingleChatDialog> {
  final TextEditingController usernameController = TextEditingController();
  List<Map<String, dynamic>> searchSuggestions = [];
  bool isSearching = false;

  void performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => searchSuggestions = []);
      return;
    }
    if (mounted) setState(() => isSearching = true);

    try {
      final response = await widget.api.searchUsers(
        token: widget.token,
        query: query.trim(),
        currentUserId: widget.currentUserId,
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          searchSuggestions = List<Map<String, dynamic>>.from(
            data["data"]["users"],
          );
        });
      }
    } catch (_) {}

    if (mounted) setState(() => isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = AppTheme.getSurfaceColor(isDark);
    final onSurfaceColor = theme.colorScheme.onSurface;

    return AlertDialog(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.getCardBorder(isDark),
          width: 1.1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.getIconBg(isDark),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_add_rounded,
              size: 20,
              color: AppTheme.getIconFg(isDark),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Kişisel Sohbet Başlat",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: onSurfaceColor,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.35,
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: [
            TextField(
              controller: usernameController,
              autofocus: true,
              onChanged: performSearch,
              decoration: const InputDecoration(
                labelText: "Kullanıcı Adı veya İsim",
                hintText: "Örn: kullanici123",
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 10),
            if (isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              ),
            if (searchSuggestions.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.getCardBorder(isDark),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: searchSuggestions.map((user) {
                    final uname = user["user_name"].toString();
                    final displayName = user["full_name"] ?? uname;
                    final letter = displayName.isNotEmpty
                        ? displayName[0].toUpperCase()
                        : "?";

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.getIconBg(isDark),
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: onSurfaceColor,
                          ),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: onSurfaceColor,
                        ),
                      ),
                      subtitle: Text(
                        "@$uname",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSectionHeaderColor(isDark),
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: onSurfaceColor.withAlpha(120),
                      ),
                      onTap: () {
                        usernameController.text = uname;
                        setState(() => searchSuggestions = []);
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(
            "İptal",
            style: TextStyle(
              color: onSurfaceColor.withAlpha(160),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: AppTheme.standardButtonStyle(context).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(90, 40)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          onPressed: () {
            final input = usernameController.text.trim();
            if (input.isNotEmpty) {
              Navigator.of(context, rootNavigator: true).pop();
              widget.onCreateChat(input);
            }
          },
          child: const Text(
            "Başlat",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}