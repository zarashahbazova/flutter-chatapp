import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:stajapp/themes/tema1.dart';
import '../../services/api_client.dart';

class GroupChatDialog extends StatefulWidget {
  final ApiClient api;
  final String token;
  final int currentUserId;
  final Function(String groupName, List<String> usernames) onCreateGroup;

  const GroupChatDialog({
    super.key,
    required this.api,
    required this.token,
    required this.currentUserId,
    required this.onCreateGroup,
  });

  @override
  State<GroupChatDialog> createState() => _GroupChatDialogState();
}

class _GroupChatDialogState extends State<GroupChatDialog> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<String> selectedUsernames = [];
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
        query: query.trim(),
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

  void addUserToList(String username) {
    final cleanName = username.trim().replaceAll('@', '');
    if (cleanName.isNotEmpty && !selectedUsernames.contains(cleanName)) {
      setState(() {
        selectedUsernames.add(cleanName);
        searchController.clear();
        searchSuggestions = [];
      });
    }
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
            Icon(Icons.groups_rounded, color: AppTheme.primaryNavy),
            SizedBox(width: 8),
            Text(
              "Yeni Grup Oluştur",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.45,
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: [
              TextField(
                controller: groupNameController,
                decoration: InputDecoration(
                  labelText: "Grup Adı",
                  hintText: "Örn: Proje Grubu",
                  prefixIcon: const Icon(Icons.group_work_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (selectedUsernames.isNotEmpty) ...[
                const Text(
                  "Eklenecek Katılımcılar:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: selectedUsernames.map((username) {
                    return Chip(
                      backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
                      side: BorderSide.none,
                      avatar: CircleAvatar(
                        backgroundColor: AppTheme.primaryNavy,
                        child: Text(
                          username[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      label: Text(
                        "@$username",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      deleteIcon: const Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: AppTheme.primaryNavy,
                      ),
                      onDeleted: () {
                        setState(() {
                          selectedUsernames.remove(username);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: performSearch,
                      onSubmitted: (value) => addUserToList(value),
                      decoration: InputDecoration(
                        labelText: "Katılımcı Ara / Yaz",
                        hintText: "Örn: kullanici123",
                        prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => addUserToList(searchController.text),
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),

              if (isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(),
                ),

              if (searchSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: searchSuggestions.map((user) {
                      final username = user["user_name"].toString();
                      final bool isAdded = selectedUsernames.contains(username);

                      return ListTile(
                        dense: true,
                        title: Text(
                          user["full_name"] ?? username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("@$username"),
                        trailing: Icon(
                          isAdded
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          color: isAdded ? Colors.green : AppTheme.primaryNavy,
                        ),
                        onTap: () => addUserToList(username),
                      );
                    }).toList(),
                  ),
                ),
              ],
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
              final name = groupNameController.text.trim();
              if (name.isEmpty) {
                AppTheme.showSnackBar(
                  context,
                  message: "Lütfen grup adını girin.",
                  isError: true,
                );
                return;
              }
              if (selectedUsernames.isEmpty) {
                AppTheme.showSnackBar(
                  context,
                  message: "En az 1 katılımcı eklemelisiniz.",
                  isError: true,
                );
                return;
              }

              Navigator.of(context, rootNavigator: true).pop();
              widget.onCreateGroup(name, selectedUsernames);
            },
            child: Text("Oluştur (${selectedUsernames.length})"),
          ),
        ],
      ),
    );
  }
}
