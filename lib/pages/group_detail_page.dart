import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:Lafla/themes/tema1.dart';
import 'package:Lafla/widgets/dialogs/user_profile_dialog.dart';
import '../services/api_client.dart';

class GroupDetailPage extends StatefulWidget {
  final String roomName;
  final String? roomDesc;
  final int roomId;
  final String? groupPhotoUrl;
  final int adminId;
  final int currentUserId;
  final List<dynamic> participants;
  final String token;

  const GroupDetailPage({
    super.key,
    required this.roomName,
    this.roomDesc,
    required this.roomId,
    this.groupPhotoUrl,
    required this.adminId,
    required this.currentUserId,
    required this.participants,
    required this.token,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final ApiClient api = ApiClient();
  final ImagePicker _picker = ImagePicker();

  late String currentRoomName;
  late String currentRoomDesc;
  late String? currentGroupPhotoUrl;
  late List<dynamic> currentParticipants;
  bool isUploadingPhoto = false;

  bool get isAdmin => widget.adminId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    currentRoomName = widget.roomName;
    currentRoomDesc = widget.roomDesc ?? "Açıklama eklenmemiş.";
    currentGroupPhotoUrl = widget.groupPhotoUrl;
    currentParticipants = List.from(widget.participants);

    _fetchRoomDetails();
  }

  Future<void> _fetchRoomDetails() async {
    try {
      final response = await api.rooms(
        token: widget.token,
        userId: widget.currentUserId,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rooms = data["data"]["rooms"] ?? [];

        final currentRoom = rooms.firstWhere(
          (r) => r["room_id"] == widget.roomId,
          orElse: () => null,
        );

        if (currentRoom != null && mounted) {
          setState(() {
            final desc = currentRoom["display_description"];
            currentRoomDesc =
                (desc != null && desc.toString().trim().isNotEmpty)
                ? desc.toString().trim()
                : "Açıklama eklenmemiş.";

            if (currentRoom["display_name"] != null) {
              currentRoomName = currentRoom["display_name"];
            }
            if (currentRoom["display_photo"] != null) {
              currentGroupPhotoUrl = currentRoom["display_photo"];
            }
            if (currentRoom["participants"] != null) {
              currentParticipants = currentRoom["participants"];
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Oda detayları yüklenirken hata: $e");
    }
  }

  Future<void> _pickAndUploadGroupPhoto() async {
    if (!isAdmin) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text("Kamerayı Aç"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text("Galeriden Seç"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 80,
    );

    if (image == null) return;

    if (!mounted) return;
    setState(() => isUploadingPhoto = true);

    try {
      final streamedRes = await api.editGroupImage(
        token: widget.token,
        roomId: widget.roomId,
        adminId: widget.currentUserId,
        filePath: image.path,
      );

      final response = await http.Response.fromStream(streamedRes);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          currentGroupPhotoUrl = data["data"]["photo_url"];
        });

        AppTheme.showSnackBar(
          context,
          message: "Grup fotoğrafı güncellendi!",
          isError: false,
        );
      } else {
        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          message: "Fotoğraf güncellenemedi.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      AppTheme.showSnackBar(context, message: "Hata: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() => isUploadingPhoto = false);
      }
    }
  }

  void _showEditGroupInfoDialog() {
    if (!isAdmin) return;
    final nameController = TextEditingController(text: currentRoomName);
    final descController = TextEditingController(text: currentRoomDesc);

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Grup Bilgilerini Düzenle",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Grup Adı"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Grup Açıklaması"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                minimumSize: const Size(90, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newDesc = descController.text.trim();

                if (newName.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    final res = await api.editGroup(
                      token: widget.token,
                      roomId: widget.roomId,
                      adminId: widget.currentUserId,
                      roomName: newName,
                      roomDesc: newDesc,
                    );
                    if (res.statusCode == 200) {
                      setState(() {
                        currentRoomName = newName;
                        currentRoomDesc = newDesc;
                      });
                      if (mounted) {
                        AppTheme.showSnackBar(
                          context,
                          message: "Grup bilgileri güncellendi!",
                          isError: false,
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        message: "Hata: $e",
                        isError: true,
                      );
                    }
                  }
                }
              },
              child: const Text(
                "Kaydet",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmRemoveDialog({
    required dynamic userId,
    required String username,
    required int index,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Üyeyi Çıkar",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "@$username kullanıcısını gruptan çıkarmak istediğinize emin misiniz?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                minimumSize: const Size(90, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final int parsedUserId = int.parse(userId.toString());
                try {
                  final res = await api.editGroupMembers(
                    token: widget.token,
                    roomId: widget.roomId,
                    adminId: widget.currentUserId,
                    participantId: parsedUserId,
                  );

                  if (res.statusCode == 200) {
                    setState(() {
                      currentParticipants.removeAt(index);
                    });
                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        message: "@$username gruptan çıkarıldı.",
                        isError: false,
                      );
                    }
                  } else {
                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        message: "Kullanıcı çıkarılamadı.",
                        isError: true,
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    AppTheme.showSnackBar(
                      context,
                      message: "Hata oluştu: $e",
                      isError: true,
                    );
                  }
                }
              },
              child: const Text(
                "Evet, Çıkar",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSelectNewAdminDialog() {
    final otherParticipants = currentParticipants
        .where((p) => p["id"].toString() != widget.currentUserId.toString())
        .toList();

    if (otherParticipants.isEmpty) {
      AppTheme.showSnackBar(
        context,
        message: "Grupta sizden başka üye olmadığı için ayrılamazsınız.",
        isError: true,
      );
      return;
    }

    dynamic selectedUser;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.getSurfaceColor(isDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Yeni Yönetici Seç",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Gruptan ayrılmadan önce başka bir üyeyi yeni yönetici olarak seçmelisiniz.",
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    height: 300,
                    child: ListView.separated(
                      itemCount: otherParticipants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final user = otherParticipants[index];
                        final userId = user["id"];
                        final name =
                            user["full_name"] ??
                            user["user_name"] ??
                            "Kullanıcı";
                        final username = user["user_name"] ?? "";
                        final isSelected =
                            selectedUser != null &&
                            selectedUser["id"].toString() == userId.toString();

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryNavy.withAlpha(25),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.getIconBg(isDark),
                            child: Text(
                              name.toString().isNotEmpty
                                  ? name.toString()[0].toUpperCase()
                                  : "?",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name.toString(),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text("@$username"),
                          trailing: Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppTheme.primaryNavy
                                : Colors.grey,
                          ),
                          onTap: () {
                            setDialogState(() {
                              selectedUser = user;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    minimumSize: const Size(90, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: selectedUser == null
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          _showConfirmLeaveWithNewAdminDialog(selectedUser);
                        },
                  child: const Text(
                    "Devam Et",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showConfirmLeaveWithNewAdminDialog(dynamic selectedUser) {
    final name =
        selectedUser["full_name"] ?? selectedUser["user_name"] ?? "Kullanıcı";
    final userId = selectedUser["id"];

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Gruptan Ayrıl",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "$name yeni yönetici olarak atanacak ve siz gruptan ayrılacaksınız. Devam etmek istiyor musunuz?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                minimumSize: const Size(90, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final res = await api.leaveGroup(
                    token: widget.token,
                    roomId: widget.roomId,
                    userId: widget.currentUserId,
                    newAdminId: int.parse(userId.toString()),
                  );

                  if (res.statusCode == 200 && mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);

                    AppTheme.showSnackBar(
                      context,
                      message: "Yeni yönetici atandı ve gruptan ayrıldınız.",
                      isError: false,
                    );
                  } else {
                    String errorMsg =
                        "Gruptan ayrılamadınız (${res.statusCode}).";
                    try {
                      final data = jsonDecode(res.body);
                      if (data["error"] != null) {
                        errorMsg = data["error"].toString();
                      }
                    } catch (_) {}

                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        message: errorMsg,
                        isError: true,
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    AppTheme.showSnackBar(
                      context,
                      message: "Ayrılırken hata oluştu: $e",
                      isError: true,
                    );
                  }
                }
              },
              child: const Text(
                "Ayrıl",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveGroupDialog() {
    if (isAdmin) {
      _showSelectNewAdminDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Gruptan Ayrıl",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Bu gruptan ayrılmak istediğinize emin misiniz? Mesajları tekrar göremezsiniz.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                minimumSize: const Size(90, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final res = await api.leaveGroup(
                    token: widget.token,
                    roomId: widget.roomId,
                    userId: widget.currentUserId,
                  );

                  if (res.statusCode == 200 && mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);

                    AppTheme.showSnackBar(
                      context,
                      message: "Gruptan ayrıldınız.",
                      isError: false,
                    );
                  } else {
                    String errorMsg =
                        "Gruptan ayrılamadınız (${res.statusCode}).";
                    try {
                      final data = jsonDecode(res.body);
                      if (data["error"] != null) {
                        errorMsg = data["error"].toString();
                      }
                    } catch (_) {}

                    if (mounted) {
                      AppTheme.showSnackBar(
                        context,
                        message: errorMsg,
                        isError: true,
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    AppTheme.showSnackBar(
                      context,
                      message: "Ayrılırken hata oluştu: $e",
                      isError: true,
                    );
                  }
                }
              },
              child: const Text(
                "Ayrıl",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddParticipantDialog() {
    if (!isAdmin) return;

    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> selectedUsers = [];
    List<Map<String, dynamic>> searchSuggestions = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void performSearch(String query) async {
              if (query.trim().isEmpty) {
                if (context.mounted) {
                  setDialogState(() => searchSuggestions = []);
                }
                return;
              }

              if (context.mounted) {
                setDialogState(() => isSearching = true);
              }

              try {
                final response = await api.searchUsers(
                  token: widget.token,
                  query: query.trim(),
                  currentUserId: widget.currentUserId,
                );

                if (response.statusCode == 200 && context.mounted) {
                  final data = jsonDecode(response.body);
                  final List<Map<String, dynamic>> users =
                      List<Map<String, dynamic>>.from(data["data"]["users"]);

                  final existingIds = currentParticipants
                      .map((p) => p["id"])
                      .toSet();

                  setDialogState(() {
                    searchSuggestions = users
                        .where((u) => !existingIds.contains(u["id"]))
                        .toList();
                  });
                }
              } catch (_) {}

              if (context.mounted) {
                setDialogState(() => isSearching = false);
              }
            }

            void addUserToList(Map<String, dynamic> user) {
              final bool alreadySelected = selectedUsers.any(
                (u) => u["id"] == user["id"],
              );

              if (!alreadySelected && context.mounted) {
                setDialogState(() {
                  selectedUsers.add(user);
                  searchController.clear();
                  searchSuggestions = [];
                });
              }
            }

            return AlertDialog(
              backgroundColor: AppTheme.getSurfaceColor(isDark),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              title: const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: AppTheme.primaryNavy),
                  SizedBox(width: 8),
                  Text(
                    "Gruba Katılımcı Ekle",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.40,
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (selectedUsers.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedUsers.map((user) {
                          final username = user["user_name"].toString();
                          return Chip(
                            backgroundColor: AppTheme.primaryNavy.withAlpha(25),
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
                            label: Text("@$username"),
                            deleteIcon: const Icon(
                              Icons.cancel_rounded,
                              size: 16,
                            ),
                            onDeleted: () {
                              if (context.mounted) {
                                setDialogState(() {
                                  selectedUsers.removeWhere(
                                    (u) => u["id"] == user["id"],
                                  );
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: searchController,
                      onChanged: performSearch,
                      decoration: const InputDecoration(
                        labelText: "Katılımcı Ara",
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
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
                          color: AppTheme.getSurfaceColor(isDark),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.darkpurple2
                                : const Color(0xFFE2DFE7),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: searchSuggestions.map((user) {
                            final username = user["user_name"].toString();
                            final bool isAdded = selectedUsers.any(
                              (u) => u["id"] == user["id"],
                            );

                            return ListTile(
                              dense: true,
                              title: Text(
                                user["full_name"] ?? username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text("@$username"),
                              trailing: Icon(
                                isAdded
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: isAdded
                                    ? Colors.green
                                    : AppTheme.primaryNavy,
                              ),
                              onTap: () => addUserToList(user),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (selectedUsers.isEmpty) return;

                    final List<Map<String, dynamic>> newlyAddedUsers =
                        List.from(selectedUsers);

                    Navigator.pop(dialogContext);

                    List<Map<String, dynamic>> addedSuccessfully = [];

                    for (var user in newlyAddedUsers) {
                      try {
                        final res = await api.addGroupParticipant(
                          token: widget.token,
                          roomId: widget.roomId,
                          adminId: widget.adminId,
                          username: user["user_name"].toString(),
                        );

                        if (res.statusCode == 200 || res.statusCode == 201) {
                          final resData = jsonDecode(res.body);
                          final Map<String, dynamic> addedUserObj =
                              resData["data"]?["added_user"] ??
                              {
                                "id": user["id"],
                                "user_name": user["user_name"],
                                "full_name": user["full_name"],
                                "profile_photo": user["profile_photo"],
                                "birth_date": user["birth_date"],
                              };
                          addedSuccessfully.add(addedUserObj);
                        }
                      } catch (_) {}
                    }

                    if (mounted && addedSuccessfully.isNotEmpty) {
                      setState(() {
                        currentParticipants.addAll(addedSuccessfully);
                      });

                      AppTheme.showSnackBar(
                        this.context,
                        message:
                            "${addedSuccessfully.length} kullanıcı gruba eklendi!",
                        isError: false,
                      );
                    } else if (mounted) {
                      AppTheme.showSnackBar(
                        this.context,
                        message: "Kullanıcılar eklenemedi.",
                        isError: true,
                      );
                    }
                  },
                  child: Text("Ekle (${selectedUsers.length})"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppTheme.getSectionHeaderColor(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final subColor = AppTheme.getSectionHeaderColor(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.getIconBg(isDark),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppTheme.getIconFg(isDark)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : "Belirtilmemiş",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = AppTheme.getSurfaceColor(isDark);
    final onSurfaceColor = theme.colorScheme.onSurface;

    final String firstLetter = currentRoomName.isNotEmpty
        ? currentRoomName[0].toUpperCase()
        : "G";

    final String? fullGroupPhotoUrl =
        (currentGroupPhotoUrl != null && currentGroupPhotoUrl!.isNotEmpty)
        ? "${ApiClient.baseUrl}${currentGroupPhotoUrl!.startsWith('/') ? currentGroupPhotoUrl : '/$currentGroupPhotoUrl'}"
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Grup Bilgisi")),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 1. GRUP PROFİL FOTOĞRAFI (Kamera butonu yerinde korunarak ProfilePage stiline uyarlandı)
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surfaceColor,
                      border: Border.all(
                        color: AppTheme.getAvatarBorder(isDark),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 80 : 10),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isUploadingPhoto
                        ? const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black54,
                          )
                        : fullGroupPhotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              fullGroupPhotoUrl,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                firstLetter,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: onSurfaceColor,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            firstLetter,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                            ),
                          ),
                  ),
                  if (isAdmin)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: isUploadingPhoto
                            ? null
                            : _pickAndUploadGroupPhoto,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? const Color(0xFF2C2A31)
                                : Colors.black,
                            border: Border.all(color: surfaceColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 2. GRUP ADI VE DÜZENLEME BUTONU
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    currentRoomName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: onSurfaceColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: Icon(
                      Icons.edit_note_rounded,
                      color: onSurfaceColor.withAlpha(180),
                      size: 22,
                    ),
                    onPressed: _showEditGroupInfoDialog,
                  ),
                ],
              ],
            ),
            Text(
              "${currentParticipants.length} Katılımcı",
              style: TextStyle(
                color: AppTheme.getSectionHeaderColor(isDark),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            // 3. GRUP BİLGİLERİ KARTI (ProfilePage Stili)
            _buildSectionHeader("Grup Detayları", isDark),
            Container(
              decoration: AppTheme.profileCardDecoration(isDark),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.info_outline_rounded,
                    label: "Grup Açıklaması",
                    value: currentRoomDesc,
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.7,
                    indent: 16,
                    endIndent: 16,
                    color: onSurfaceColor.withAlpha(isDark ? 16 : 10),
                  ),
                  _buildInfoRow(
                    icon: Icons.groups_rounded,
                    label: "Toplam Üye",
                    value: "${currentParticipants.length} Kişi",
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. YÖNETİCİ ÖZEL: KATILIMCI EKLE
            if (isAdmin) ...[
              _buildSectionHeader("Yönetim", isDark),
              Container(
                decoration: AppTheme.profileCardDecoration(isDark),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.getIconBg(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 19,
                      color: AppTheme.getIconFg(isDark),
                    ),
                  ),
                  title: Text(
                    "Katılımcı Ekle",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: onSurfaceColor.withAlpha(100),
                  ),
                  onTap: _showAddParticipantDialog,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 5. KATILIMCI LİSTESİ KARTI
            _buildSectionHeader(
              "Grup Katılımcıları (${currentParticipants.length})",
              isDark,
            ),
            Container(
              decoration: AppTheme.profileCardDecoration(isDark),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentParticipants.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.7,
                  indent: 64,
                  endIndent: 16,
                  color: onSurfaceColor.withAlpha(isDark ? 16 : 10),
                ),
                itemBuilder: (context, index) {
                  final p = currentParticipants[index];
                  final name = p["full_name"] ?? p["user_name"] ?? "Kullanıcı";
                  final username = p["user_name"] ?? "";
                  final userId = p["id"];
                  final bool isUserAdmin = userId == widget.adminId;
                  final bool isMe = userId == widget.currentUserId;
                  final firstLetter = name.isNotEmpty
                      ? name[0].toUpperCase()
                      : "?";

                  final String? userPhotoPath =
                      p["profile_photo"] ?? p["display_photo"];
                  final String? fullUserPhotoUrl =
                      (userPhotoPath != null && userPhotoPath.isNotEmpty)
                      ? "${ApiClient.baseUrl}${userPhotoPath.startsWith('/') ? userPhotoPath : '/$userPhotoPath'}"
                      : null;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.getIconBg(isDark),
                      ),
                      alignment: Alignment.center,
                      child: fullUserPhotoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                fullUserPhotoUrl,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  firstLetter,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: onSurfaceColor,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              firstLetter,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                              ),
                            ),
                    ),
                    title: Text(
                      name + (isMe ? " (Sen)" : ""),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUserAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Yönetici",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: onSurfaceColor.withAlpha(140),
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == "remove") {
                              _showConfirmRemoveDialog(
                                userId: userId,
                                username: username,
                                index: index,
                              );
                            } else if (value == "profile") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfileDialog(user: p),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) {
                            final List<PopupMenuEntry<String>> menuItems = [];

                            if (isAdmin && !isMe) {
                              menuItems.add(
                                const PopupMenuItem(
                                  value: "remove",
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_remove_rounded,
                                        color: AppTheme.errorColor,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Gruptan Çıkar",
                                        style: TextStyle(
                                          color: AppTheme.errorColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            menuItems.add(
                              PopupMenuItem(
                                value: "profile",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      color: onSurfaceColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Profili Gör",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            return menuItems;
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 6. GRUPTAN AYRIL KARTI
            _buildSectionHeader("Grup İşlemleri", isDark),
            Container(
              decoration: AppTheme.profileCardDecoration(isDark),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(isDark ? 25 : 15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    size: 19,
                    color: AppTheme.errorColor,
                  ),
                ),
                title: const Text(
                  "Gruptan Ayrıl",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.errorColor,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.errorColor,
                ),
                onTap: _showLeaveGroupDialog,
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
