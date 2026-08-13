import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:stajapp/themes/tema1.dart';
import 'package:stajapp/widgets/dialogs/user_profile_dialog.dart';
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

    // 👈 Sayfa açılır açılmaz veritabanından güncel açıklamayı çekiyoruz
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

  // --- GRUP FOTOĞRAFI YÜKLEME ---
  Future<void> _pickAndUploadGroupPhoto() async {
    if (!isAdmin) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (image != null) {
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
          setState(() {
            currentGroupPhotoUrl = data["data"]["photo_url"];
          });
          if (mounted) {
            AppTheme.showSnackBar(
              context,
              message: "Grup fotoğrafı güncellendi!",
              isError: false,
            );
          }
        } else {
          if (mounted) {
            AppTheme.showSnackBar(
              context,
              message: "Fotoğraf güncellenemedi.",
              isError: true,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          AppTheme.showSnackBar(context, message: "Hata: $e", isError: true);
        }
      } finally {
        if (mounted) setState(() => isUploadingPhoto = false);
      }
    }
  }

  // --- GRUP ADI VE AÇIKLAMASINI DÜZENLEME ---
  void _showEditGroupInfoDialog() {
    if (!isAdmin) return;
    final nameController = TextEditingController(text: currentRoomName);
    final descController = TextEditingController(text: currentRoomDesc);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                decoration: InputDecoration(
                  labelText: "Grup Adı",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Grup Açıklaması",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- ÜYE SİLME ONAY DIALOG'U ---
  void _showConfirmRemoveDialog({
    required dynamic userId,
    required String username,
    required int index,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Üyeyi Çıkar",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "@$username kullanıcısını gruptan çıkarmak istediğinize emin misiniz?",
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
              child: const Text("Evet, Çıkar"),
            ),
          ],
        );
      },
    );
  }

  void _showSelectNewAdminDialog() {
    // Kendisi dışındaki kullanıcıları alıyoruz.
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
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
                          selectedTileColor: AppTheme.primaryNavy.withAlpha(20),

                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryNavy.withAlpha(30),
                            child: Text(
                              name.toString().isNotEmpty
                                  ? name.toString()[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                color: AppTheme.primaryNavy,
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
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: selectedUser == null
                      ? null
                      : () {
                          Navigator.pop(dialogContext);

                          _showConfirmLeaveWithNewAdminDialog(selectedUser);
                        },
                  child: const Text("Devam Et"),
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
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  final res = await api.leaveGroup(
                    token: widget.token,
                    roomId: widget.roomId,
                    userId: widget.currentUserId,

                    // BURASI BACKEND'DEKİ GERÇEK PARAMETREYE
                    // GÖRE AYARLANACAK.
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
              child: const Text("Ayrıl"),
            ),
          ],
        );
      },
    );
  }

  // --- GRUPTAN AYRILMA ONAYI ---
  void _showLeaveGroupDialog() {
    if (isAdmin) {
      _showSelectNewAdminDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Gruptan Ayrıl",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Bu gruptan ayrılmak istediğinize emin misiniz? "
            "Mesajları tekrar göremezsiniz.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
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
              child: const Text("Ayrıl"),
            ),
          ],
        );
      },
    );
  }

  // --- CANLI ARAMALI KATILIMCI EKLEME DIALOG'U (GroupChatDialog Mantığıyla Birebir Aynı) ---
  void _showAddParticipantDialog() {
    if (!isAdmin) return;

    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> selectedUsers = [];
    List<Map<String, dynamic>> searchSuggestions = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
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
              backgroundColor: Theme.of(context).colorScheme.surface,
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: performSearch,
                            decoration: InputDecoration(
                              labelText: "Katılımcı Ara",
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
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
                          // Backend'den eklenen kullanıcı objesi dönüyorsa al, dönmüyorsa eldeki user'ı formatla
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

  @override
  Widget build(BuildContext context) {
    final cardBgColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final String firstLetter = currentRoomName.isNotEmpty
        ? currentRoomName[0].toUpperCase()
        : "G";

    final String? fullGroupPhotoUrl =
        (currentGroupPhotoUrl != null && currentGroupPhotoUrl!.isNotEmpty)
        ? "${ApiClient.baseUrl}${currentGroupPhotoUrl!.startsWith('/') ? currentGroupPhotoUrl : '/$currentGroupPhotoUrl'}"
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Grup Bilgisi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // 1. GRUP PROFİL FOTOĞRAFI
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryNavy, AppTheme.secondaryNavy],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: fullGroupPhotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              fullGroupPhotoUrl,
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            firstLetter,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.primaryNavy,
                          child: isUploadingPhoto
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. GRUP ADI VE DÜZENLEME
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentRoomName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: onSurfaceColor,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: AppTheme.primaryNavy,
                      size: 20,
                    ),
                    onPressed: _showEditGroupInfoDialog,
                  ),
                ],
              ],
            ),
            Text(
              "${currentParticipants.length} Katılımcı",
              style: TextStyle(
                color: onSurfaceColor.withAlpha(140),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),

            // 3. GRUP AÇIKLAMASI KARTI
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: onSurfaceColor.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Grup Açıklaması",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentRoomDesc,
                      style: TextStyle(fontSize: 14, color: onSurfaceColor),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 5. YÖNETİCİ ÖZEL AKSİYONU: ÜYE EKLE
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: onSurfaceColor.withAlpha(20)),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryNavy,
                      child: Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Katılımcı Ekle",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: _showAddParticipantDialog,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 6. KATILIMCI LİSTESİ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: onSurfaceColor.withAlpha(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: Text(
                        "Grup Katılımcıları (${currentParticipants.length})",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentParticipants.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color: onSurfaceColor.withAlpha(15),
                      ),
                      itemBuilder: (context, index) {
                        final p = currentParticipants[index];
                        final name =
                            p["full_name"] ?? p["user_name"] ?? "Kullanıcı";
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
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryNavy.withAlpha(30),
                            ),
                            child: fullUserPhotoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      fullUserPhotoUrl,
                                      width: 38,
                                      height: 38,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          firstLetter,
                                          style: const TextStyle(
                                            color: AppTheme.primaryNavy,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      firstLetter,
                                      style: const TextStyle(
                                        color: AppTheme.primaryNavy,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          title: Text(
                            name + (isMe ? " (Sen)" : ""),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            "@$username",
                            style: const TextStyle(fontSize: 11),
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
                                    borderRadius: BorderRadius.circular(12),
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
                                        builder: (_) =>
                                            UserProfileDialog(user: p),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) {
                                  final List<PopupMenuEntry<String>> menuItems =
                                      [];

                                  if (isAdmin && !isMe) {
                                    menuItems.add(
                                      const PopupMenuItem(
                                        value: "remove",
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.person_remove_rounded,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Gruptan Çıkar",
                                              style: TextStyle(
                                                color: Colors.redAccent,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 7. GRUPTAN AYRIL BUTONU
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: const Color.fromARGB(
                      255,
                      165,
                      127,
                      125,
                    ).withAlpha(40),
                  ),
                ),
                tileColor: const Color.fromARGB(
                  255,
                  162,
                  100,
                  96,
                ).withAlpha(15),
                leading: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  "Gruptan Ayrıl",
                  style: TextStyle(
                    color: Color.fromARGB(255, 193, 135, 135),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _showLeaveGroupDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
