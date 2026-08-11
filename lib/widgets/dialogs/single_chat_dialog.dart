import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:stajapp/themes/tema1.dart';
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
      setState(() => searchSuggestions = []);
      return;
    }
    setState(() => isSearching = true);
    try {
      final response = await widget.api.searchUsers(
        token: widget.token,
        query: query,
        currentUserId: widget.currentUserId,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchSuggestions = List<Map<String, dynamic>>.from(
            data["data"]["users"],
          );
        });
      }
    } catch (_) {}
    setState(() => isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: 10,
        sigmaY: 10,
      ), // Arka planı hafif buğular
      child: AlertDialog(
        backgroundColor: surfaceColor.withAlpha(230), // Şeffaf zemin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
            width: 1,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Row(
          children: [
            Icon(Icons.person_add_rounded, color: AppTheme.darkpurple2),
            SizedBox(width: 8),
            Text(
              "Kişisel Sohbet Başlat",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                decoration: InputDecoration(
                  labelText: "Kullanıcı Adı veya İsim",
                  hintText: "Örn: kullanici123",
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: searchSuggestions.map((user) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          user["full_name"] ?? user["user_name"],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("@${user["user_name"]}"),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppTheme.primaryNavy,
                        ),
                        onTap: () {
                          usernameController.text = user["user_name"];
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
            child: const Text(
              "İptal",
              style: TextStyle(color: AppTheme.subtitleColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final input = usernameController.text.trim();
              if (input.isNotEmpty) {
                Navigator.of(context, rootNavigator: true).pop();
                widget.onCreateChat(input);
              }
            },
            child: const Text("Başlat"),
          ),
        ],
      ),
    );
  }
}
