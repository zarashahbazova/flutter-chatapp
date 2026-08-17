import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Lafla/themes/tema1.dart';
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
              Icons.groups_rounded,
              size: 20,
              color: AppTheme.getIconFg(isDark),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Yeni Grup Oluştur",
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
        height: MediaQuery.of(context).size.height * 0.45,
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          children: [
            TextField(
              controller: groupNameController,
              decoration: const InputDecoration(
                labelText: "Grup Adı",
                hintText: "Örn: Proje Grubu",
                prefixIcon: Icon(Icons.group_work_rounded),
              ),
            ),
            const SizedBox(height: 14),

            if (selectedUsernames.isNotEmpty) ...[
              Text(
                "EKLENECEK KATILIMCILAR",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.getSectionHeaderColor(isDark),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedUsernames.map((username) {
                  return Chip(
                    backgroundColor: AppTheme.getIconBg(isDark),
                    side: BorderSide(
                      color: AppTheme.getCardBorder(isDark),
                    ),
                    avatar: CircleAvatar(
                      backgroundColor: isDark ? AppTheme.darkpurple2 : AppTheme.textColor,
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
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor,
                      ),
                    ),
                    deleteIcon: Icon(
                      Icons.cancel_rounded,
                      size: 16,
                      color: onSurfaceColor.withAlpha(160),
                    ),
                    onDeleted: () {
                      setState(() {
                        selectedUsernames.remove(username);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: performSearch,
                    onSubmitted: (value) => addUserToList(value),
                    decoration: const InputDecoration(
                      labelText: "Katılımcı Ara / Yaz",
                      hintText: "Örn: kullanici123",
                      prefixIcon: Icon(Icons.person_add_alt_1_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkpurple2 : AppTheme.textColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    onPressed: () => addUserToList(searchController.text),
                    icon: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            if (isSearching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              ),

            if (searchSuggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
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
                    final username = user["user_name"].toString();
                    final bool isAdded = selectedUsernames.contains(username);
                    final displayName = user["full_name"] ?? username;
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
                        "@$username",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.getSectionHeaderColor(isDark),
                        ),
                      ),
                      trailing: Icon(
                        isAdded
                            ? Icons.check_circle_rounded
                            : Icons.add_circle_outline_rounded,
                        color: isAdded
                            ? AppTheme.successColor
                            : onSurfaceColor.withAlpha(120),
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
            minimumSize: const WidgetStatePropertyAll(Size(100, 40)),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          child: Text(
            "Oluştur (${selectedUsernames.length})",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}