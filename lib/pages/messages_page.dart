import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'chats_page.dart';
import 'discover_page.dart';
import 'profile.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ApiClient api = ApiClient();

  String? token;
  int? currentUserId;
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;

  bool _showSmallTitle = false;
  String _searchText = "";
  double _currentPage = 0.0;

  List<Map<String, dynamic>> users = [];
  Timer? _pollingTimer; // Arka planda sohbetleri canlı tutan zamanlayıcı

  @override
  void initState() {
    super.initState();
    loadUser();

    _pageController = PageController(initialPage: _selectedIndex);
    _scrollController.addListener(() {
      final show = _scrollController.offset > 55;
      if (show != _showSmallTitle) {
        setState(() {
          _showSmallTitle = show;
        });
      }
    });

    // Her 3 saniyede bir odaları ve son mesajları otomatik yeniler
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _selectedIndex == 0) {
        loadRooms(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Zamanlayıcıyı temizle
    _scrollController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime dt = DateTime.parse(timestamp.toString()).toLocal();
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (_) {
      return "";
    }
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString("token");
    currentUserId = prefs.getInt("userId");

    if (currentUserId == null && token != null) {
      try {
        final response = await api.profile(token!);
        if (response.statusCode == 200) {
          final profileData = jsonDecode(response.body);
          currentUserId = profileData["data"]["id"];
          if (currentUserId != null) {
            await prefs.setInt("userId", currentUserId!);
          }
        }
      } catch (e) {
        debugPrint("Profil çekilirken hata: $e");
      }
    }
    await loadRooms();
  }

  Future<void> loadRooms({bool showLoading = true}) async {
    if (token == null || currentUserId == null) return;

    try {
      final response = await api.rooms(token: token!, userId: currentUserId!);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List roomsList = data["data"]?["rooms"] ?? [];

        if (!mounted) return;

        setState(() {
          users = roomsList.map<Map<String, dynamic>>((room) {
            int unreadVal = 0;
            if (room["unread_count"] != null) {
              unreadVal = int.tryParse(room["unread_count"].toString()) ?? 0;
            }

            return {
              "room_id": room["room_id"],
              "other_user_id": room["other_user_id"],
              "is_group": room["is_group"] ?? false,
              "participants": room["participants"] ?? [],
              "name":
                  room["display_name"] ??
                  room["display_username"] ??
                  "Kullanıcı",
              "message": room["last_message"] ?? "Sohbeti başlatın...",
              "time": _formatTime(room["last_message_time"]),
              "unread": unreadVal, // <-- BURASI DEĞİŞTİ (Eski hali sabit 0'dı)
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("loadRooms EXCEPTION: $e");
    }
  }

  // 1. KİŞİSEL SOHBET OLUŞTURMA
  Future<void> _createSingleChat(String targetUsername) async {
    if (token == null || currentUserId == null) return;

    try {
      final response = await api.createRoomByUsername(
        token: token!,
        myUserId: currentUserId!,
        targetUsername: targetUsername,
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Böyle bir kullanıcı bulunamadı.")),
        );
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final roomId = data["data"]?["roomId"];
        final bool isExisting = data["data"]?["is_existing"] ?? false;
        final otherUser = data["data"]?["other_user"];
        final displayName =
            otherUser?["full_name"] ??
            otherUser?["user_name"] ??
            targetUsername;

        await loadRooms();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isExisting
                  ? "Bu kullanıcıyla zaten sohbetiniz var."
                  : "Sohbet odası başarıyla oluşturuldu!",
            ),
          ),
        );

        if (roomId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatsPage(
                userName: displayName,
                roomId: roomId,
                isGroup: null,
                participants: null,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
    }
  }

  // 2. GRUP OLUŞTURMA
  Future<void> _createGroupChat(
    String groupName,
    List<String> usernames,
  ) async {
    if (token == null || currentUserId == null) return;

    try {
      final response = await api.createGroup(
        token: token!,
        adminId: currentUserId!,
        roomName: groupName,
        participantUsernames: usernames,
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final roomId = data["data"]?["roomId"];

        await loadRooms();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Grup başarıyla oluşturuldu!")),
        );

        if (roomId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatsPage(
                userName: groupName,
                roomId: roomId,
                isGroup: null,
                participants: null,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
    }
  }

  // DINAMIK KULLANICI ARAMA / ÖNERİ DIALOGU (KİŞİSEL)
  // TAŞMA YAPMAYAN DÜZELTİLMİŞ KİŞİSEL SOHBET DIALOGU
  void _openSingleChatDialog() {
    final TextEditingController usernameController = TextEditingController();
    List<Map<String, dynamic>> searchSuggestions = [];
    bool isSearching = false;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void performSearch(String query) async {
              if (query.trim().isEmpty) {
                setDialogState(() => searchSuggestions = []);
                return;
              }
              setDialogState(() => isSearching = true);
              try {
                final response = await api.searchUsers(
                  token: token!,
                  query: query,
                  currentUserId: currentUserId!,
                );
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  setDialogState(() {
                    searchSuggestions = List<Map<String, dynamic>>.from(
                      data["data"]["users"],
                    );
                  });
                }
              } catch (_) {}
              setDialogState(() => isSearching = false);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              title: const Row(
                children: [
                  Icon(Icons.person_add_rounded, color: Color(0xFF08314D)),
                  SizedBox(width: 8),
                  Text(
                    "Kişisel Sohbet Başlat",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                // Klavyeyle sıkışmayı önleyen dinamik yükseklik
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
                        hintText: "Örn: ahmet123",
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
                          color: Colors.white,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text("@${user["user_name"]}"),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Color(0xFF08314D),
                              ),
                              onTap: () {
                                usernameController.text = user["user_name"];
                                setDialogState(() => searchSuggestions = []);
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
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text(
                    "İptal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08314D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final input = usernameController.text.trim();
                    if (input.isNotEmpty) {
                      Navigator.of(context, rootNavigator: true).pop();
                      _createSingleChat(input);
                    }
                  },
                  child: const Text("Başlat"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // DINAMIK KULLANICI ARAMA / ÖNERİ DIALOGU (GRUP)
  void _openGroupChatDialog() {
    final TextEditingController groupNameController = TextEditingController();
    final TextEditingController searchController = TextEditingController();

    List<String> selectedUsernames = [];
    List<Map<String, dynamic>> searchSuggestions = [];
    bool isSearching = false;

    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void performSearch(String query) async {
              if (query.trim().isEmpty) {
                setDialogState(() => searchSuggestions = []);
                return;
              }

              setDialogState(() => isSearching = true);

              try {
                final response = await api.searchUsers(
                  token: token!,
                  query: query.trim(),
                  currentUserId: currentUserId!,
                );

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  setDialogState(() {
                    searchSuggestions = List<Map<String, dynamic>>.from(
                      data["data"]["users"],
                    );
                  });
                }
              } catch (_) {}

              setDialogState(() => isSearching = false);
            }

            void addUserToList(String username) {
              final cleanName = username.trim().replaceAll('@', '');
              if (cleanName.isNotEmpty &&
                  !selectedUsernames.contains(cleanName)) {
                setDialogState(() {
                  selectedUsernames.add(cleanName);
                  searchController.clear();
                  searchSuggestions = [];
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              title: const Row(
                children: [
                  Icon(Icons.groups_rounded, color: Color(0xFF08314D)),
                  SizedBox(width: 8),
                  Text(
                    "Yeni Grup Oluştur",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                // Klavye açıldığında içeriğin taşmasını engelleyen dinamik yükseklik sınırı
                height: MediaQuery.of(context).size.height * 0.45,
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 1. Grup Adı
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

                    // 2. Eklenen Katılımcılar (Chips)
                    if (selectedUsernames.isNotEmpty) ...[
                      Text(
                        "Eklenecek Katılımcılar (${selectedUsernames.length}):",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF08314D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: selectedUsernames.map((username) {
                          return Chip(
                            backgroundColor: const Color(
                              0xFF08314D,
                            ).withOpacity(0.1),
                            side: BorderSide.none,
                            avatar: CircleAvatar(
                              backgroundColor: const Color(0xFF08314D),
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
                                color: Color(0xFF08314D),
                              ),
                            ),
                            deleteIcon: const Icon(
                              Icons.cancel_rounded,
                              size: 16,
                              color: Color(0xFF08314D),
                            ),
                            onDeleted: () {
                              setDialogState(() {
                                selectedUsernames.remove(username);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 3. Arama Kutusu ve Butonu
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            onChanged: performSearch,
                            onSubmitted: (value) => addUserToList(value),
                            decoration: InputDecoration(
                              labelText: "Katılımcı Ara / Yaz",
                              hintText: "Örn: ahmet123",
                              prefixIcon: const Icon(
                                Icons.person_add_alt_1_rounded,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF08314D),
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

                    // 4. Arama Sonucu Öneri Listesi
                    if (searchSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: searchSuggestions.map((user) {
                            final username = user["user_name"].toString();
                            final bool isAdded = selectedUsernames.contains(
                              username,
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
                                    : const Color(0xFF08314D),
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
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  child: const Text(
                    "İptal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF08314D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final name = groupNameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Lütfen grup adını girin."),
                        ),
                      );
                      return;
                    }
                    if (selectedUsernames.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("En az 1 katılımcı eklemelisiniz."),
                        ),
                      );
                      return;
                    }

                    Navigator.of(context, rootNavigator: true).pop();
                    _createGroupChat(name, selectedUsernames);
                  },
                  child: Text("Oluştur (${selectedUsernames.length})"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openNewChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0F4F8),
                    child: Icon(
                      Icons.person_add_rounded,
                      color: Color(0xFF08314D),
                    ),
                  ),
                  title: const Text(
                    "Kişisel Sohbet Başlat",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Kullanıcı adı veya isim arayarak sohbet edin",
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openSingleChatDialog();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0F4F8),
                    child: Icon(Icons.groups_rounded, color: Color(0xFF08314D)),
                  ),
                  title: const Text(
                    "Yeni Grup Oluştur",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Birden fazla kişiyi seçerek sohbet grubu kurun",
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _openGroupChatDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      extendBody: true,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                setState(() {
                  _currentPage =
                      _pageController.page ?? _selectedIndex.toDouble();
                });
              }
              return false;
            },
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              children: [_page(), const DiscoverPage(), const ProfilePage()],
            ),
          ),
          if (_selectedIndex == 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 20),
                opacity: _showSmallTitle ? 1.0 : 0.0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: MediaQuery.of(context).padding.top + 52,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(190),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF08314D).withAlpha(15),
                            width: 0.8,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Sohbetler",
                        style: TextStyle(
                          color: Color.fromARGB(255, 6, 44, 65),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: _buildCustomGlassNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomGlassNavBar() {
    final navItems = [
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Sohbetler'},
      {'icon': Icons.explore_outlined, 'label': 'Keşfet'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profil'},
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: Colors.white.withAlpha(180),
                width: 1.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemWidth = totalWidth / navItems.length;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    double targetPage = (details.localPosition.dx / itemWidth)
                        .clamp(0.0, (navItems.length - 1).toDouble());
                    setState(() => _currentPage = targetPage);
                    if (_pageController.hasClients) {
                      _pageController.jumpTo(
                        targetPage * _pageController.position.viewportDimension,
                      );
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    int targetIndex = _currentPage.round().clamp(
                      0,
                      navItems.length - 1,
                    );
                    setState(() {
                      _selectedIndex = targetIndex;
                      _currentPage = targetIndex.toDouble();
                    });
                    _pageController.animateToPage(
                      targetIndex,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Stack(
                    children: [
                      Positioned(
                        left: (_currentPage * itemWidth).clamp(
                          0.0,
                          totalWidth - itemWidth,
                        ),
                        width: itemWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              4,
                              38,
                              73,
                            ).withAlpha(215),
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(navItems.length, (index) {
                          double distance = (_currentPage - index).abs();
                          double selectionRatio = (1.0 - distance).clamp(
                            0.0,
                            1.0,
                          );
                          Color dynamicColor = Color.lerp(
                            const Color(0xFF4A5568),
                            Colors.white,
                            selectionRatio,
                          )!;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                  _currentPage = index.toDouble();
                                });
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    navItems[index]['icon'] as IconData,
                                    color: dynamicColor,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    navItems[index]['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selectionRatio > 0.5
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: dynamicColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _page() {
    switch (_selectedIndex) {
      case 0:
        final filteredUsers = users.where((user) {
          return user["name"].toString().toLowerCase().contains(
            _searchText.toLowerCase(),
          );
        }).toList();

        final totalUnread = users.fold<int>(
          0,
          (sum, item) => sum + ((item["unread"] as int?) ?? 0),
        );

        return ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 120,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Sohbetler",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF041B2A),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (totalUnread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF08314D).withAlpha(18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$totalUnread yeni",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF08314D),
                            ),
                          ),
                        ),
                    ],
                  ),

                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _openNewChatOptions,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF08314D).withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF08314D),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(210),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF08314D).withAlpha(8),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 44),
                    suffixIcon: _searchText.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchText = "");
                            },
                            child: const Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : null,
                    hintText: "Sohbetlerde ara...",
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchText = value),
                ),
              ),
            ),

            const SizedBox(height: 14),

            if (filteredUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sonuç bulunamadı",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredUsers.map((user) => _buildMessageTile(user)),
          ],
        );

      case 1:
        return const DiscoverPage();
      case 2:
        return const ProfilePage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMessageTile(Map<String, dynamic> user) {
    final int unread = user["unread"] ?? 0;
    final String name = user["name"] ?? "";
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: unread > 0 ? Colors.white : Colors.white.withAlpha(210),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unread > 0
                ? const Color(0xFF08314D).withAlpha(20)
                : Colors.white,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFF08314D).withAlpha(15),
            onTap: () {
              // 1. Lokalde anında 0 yap
              setState(() {
                user["unread"] = 0;
              });

              // 2. Timer'ı geçici durdur ki sohbet içindeyken eski veriyi tekrar çekip rozeti geri getirmesin
              _pollingTimer?.cancel();

              // 3. Sohbete git ve geri dönüldüğünde hem odaları yenile hem zamanlayıcıyı tekrar başlat
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatsPage(
                    userName: user["name"],
                    roomId: user["room_id"],
                    isGroup: user["is_group"] ?? false,
                    participants: user["participants"],
                  ),
                ),
              ).then((_) {
                // Geri dönüldüğünde odaları güncel verilerle yenile
                loadRooms(showLoading: false);

                // Zamanlayıcıyı (Timer) yeniden başlat
                _pollingTimer?.cancel();
                _pollingTimer = Timer.periodic(const Duration(seconds: 3), (
                  timer,
                ) {
                  if (mounted && _selectedIndex == 0) {
                    loadRooms(showLoading: false);
                  }
                });
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 14, 56, 84),
                          Color(0xFF1E5276),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF08314D).withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user["time"] ?? "",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: unread > 0
                                    ? const Color(0xFF08314D)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user["message"] ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: unread > 0
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: unread > 0
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                height: 20,
                                constraints: const BoxConstraints(minWidth: 20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF08314D),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unread > 99 ? "99+" : unread.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// import 'dart:async';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'chats_page.dart';
// import 'discover_page.dart';
// import 'profile.dart';
// import '../services/api_client.dart';

// // Widget Modülleri
// import '../widgets/message_tile.dart';
// import '../widgets/custom_glass_nav_bar.dart';
// import '../widgets/dialogs/single_chat_dialog.dart';
// import '../widgets/dialogs/group_chat_dialog.dart';
// import '../widgets/dialogs/new_chat_sheet.dart';

// class MessagesPage extends StatefulWidget {
//   const MessagesPage({super.key});

//   @override
//   State<MessagesPage> createState() => _MessagesPageState();
// }

// class _MessagesPageState extends State<MessagesPage> {
//   final ApiClient api = ApiClient();

//   String? token;
//   int? currentUserId;
//   int _selectedIndex = 0;
//   final TextEditingController _searchController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late PageController _pageController;

//   bool _showSmallTitle = false;
//   String _searchText = "";
//   double _currentPage = 0.0;

//   List<Map<String, dynamic>> users = [];
//   Timer? _pollingTimer;

//   @override
//   void initState() {
//     super.initState();
//     loadUser();

//     _pageController = PageController(initialPage: _selectedIndex);
//     _scrollController.addListener(() {
//       final show = _scrollController.offset > 55;
//       if (show != _showSmallTitle) {
//         setState(() => _showSmallTitle = show);
//       }
//     });

//     _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//       if (mounted && _selectedIndex == 0) {
//         loadRooms(showLoading: false);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _pollingTimer?.cancel();
//     _scrollController.dispose();
//     _searchController.dispose();
//     _pageController.dispose();
//     super.dispose();
//   }

//   String _formatTime(dynamic timestamp) {
//     if (timestamp == null) return "";
//     try {
//       DateTime dt = DateTime.parse(timestamp.toString()).toLocal();
//       final hour = dt.hour.toString().padLeft(2, '0');
//       final minute = dt.minute.toString().padLeft(2, '0');
//       return "$hour:$minute";
//     } catch (_) {
//       return "";
//     }
//   }

//   Future<void> loadUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString("token");
//     currentUserId = prefs.getInt("userId");

//     if (currentUserId == null && token != null) {
//       try {
//         final response = await api.profile(token!);
//         if (response.statusCode == 200) {
//           final profileData = jsonDecode(response.body);
//           currentUserId = profileData["data"]["id"];
//           if (currentUserId != null) {
//             await prefs.setInt("userId", currentUserId!);
//           }
//         }
//       } catch (e) {
//         debugPrint("Profil çekilirken hata: $e");
//       }
//     }
//     await loadRooms();
//   }

//   Future<void> loadRooms({bool showLoading = true}) async {
//     if (token == null || currentUserId == null) return;

//     try {
//       final response = await api.rooms(token: token!, userId: currentUserId!);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List roomsList = data["data"]?["rooms"] ?? [];

//         if (!mounted) return;

//         setState(() {
//           users = roomsList.map<Map<String, dynamic>>((room) {
//             int unreadVal = 0;
//             if (room["unread_count"] != null) {
//               unreadVal = int.tryParse(room["unread_count"].toString()) ?? 0;
//             }

//             return {
//               "room_id": room["room_id"],
//               "other_user_id": room["other_user_id"],
//               "is_group": room["is_group"] ?? false,
//               "participants": room["participants"] ?? [],
//               "name": room["display_name"] ?? room["display_username"] ?? "Kullanıcı",
//               "message": room["last_message"] ?? "Sohbeti başlatın...",
//               "time": _formatTime(room["last_message_time"]),
//               "unread": unreadVal,
//             };
//           }).toList();
//         });
//       }
//     } catch (e) {
//       debugPrint("loadRooms EXCEPTION: $e");
//     }
//   }

//   Future<void> _createSingleChat(String targetUsername) async {
//     if (token == null || currentUserId == null) return;

//     try {
//       final response = await api.createRoomByUsername(
//         token: token!,
//         myUserId: currentUserId!,
//         targetUsername: targetUsername,
//       );

//       final data = jsonDecode(response.body);
//       if (!mounted) return;

//       if (response.statusCode == 404) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Böyle bir kullanıcı bulunamadı.")),
//         );
//         return;
//       }

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final roomId = data["data"]?["roomId"];
//         final bool isExisting = data["data"]?["is_existing"] ?? false;
//         final otherUser = data["data"]?["other_user"];
//         final displayName = otherUser?["full_name"] ?? otherUser?["user_name"] ?? targetUsername;

//         await loadRooms();
//         if (!mounted) return;

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               isExisting
//                   ? "Bu kullanıcıyla zaten sohbetiniz var."
//                   : "Sohbet odası başarıyla oluşturuldu!",
//             ),
//           ),
//         );

//         if (roomId != null) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => ChatsPage(
//                 userName: displayName,
//                 roomId: roomId,
//                 isGroup: false, participants: null,
//               ),
//             ),
//           ).then((_) => loadRooms(showLoading: false));
//         }
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
//     }
//   }

//   Future<void> _createGroupChat(String groupName, List<String> usernames) async {
//     if (token == null || currentUserId == null) return;

//     try {
//       final response = await api.createGroup(
//         token: token!,
//         adminId: currentUserId!,
//         roomName: groupName,
//         participantUsernames: usernames,
//       );

//       final data = jsonDecode(response.body);
//       if (!mounted) return;

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final roomId = data["data"]?["roomId"];

//         await loadRooms();
//         if (!mounted) return;

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Grup başarıyla oluşturuldu!")),
//         );

//         if (roomId != null) {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => ChatsPage(
//                 userName: groupName,
//                 roomId: roomId,
//                 isGroup: true, participants: null,
//               ),
//             ),
//           ).then((_) => loadRooms(showLoading: false));
//         }
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu: $e")));
//     }
//   }

//   void _openSingleChatDialog() {
//     if (token == null || currentUserId == null) return;
//     showDialog(
//       context: context,
//       useRootNavigator: true,
//       builder: (_) => SingleChatDialog(
//         api: api,
//         token: token!,
//         currentUserId: currentUserId!,
//         onCreateChat: _createSingleChat,
//       ),
//     );
//   }

//   void _openGroupChatDialog() {
//     if (token == null || currentUserId == null) return;
//     showDialog(
//       context: context,
//       useRootNavigator: true,
//       builder: (_) => GroupChatDialog(
//         api: api,
//         token: token!,
//         currentUserId: currentUserId!,
//         onCreateGroup: _createGroupChat,
//       ),
//     );
//   }

//   void _openNewChatOptions() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (_) => NewChatSheet(
//         onSingleChatTap: _openSingleChatDialog,
//         onGroupChatTap: _openGroupChatDialog,
//       ),
//     );
//   }

//   void _handleTileTap(Map<String, dynamic> user) {
//     setState(() {
//       user["unread"] = 0;
//     });

//     _pollingTimer?.cancel();

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChatsPage(
//           userName: user["name"],
//           roomId: user["room_id"],
//           isGroup: user["is_group"] ?? false,
//           participants: user["participants"],
//         ),
//       ),
//     ).then((_) {
//       loadRooms(showLoading: false);

//       _pollingTimer?.cancel();
//       _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
//         if (mounted && _selectedIndex == 0) {
//           loadRooms(showLoading: false);
//         }
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6F9),
//       extendBody: true,
//       body: Stack(
//         children: [
//           NotificationListener<ScrollNotification>(
//             onNotification: (notification) {
//               if (_pageController.hasClients && _pageController.position.haveDimensions) {
//                 setState(() {
//                   _currentPage = _pageController.page ?? _selectedIndex.toDouble();
//                 });
//               }
//               return false;
//             },
//             child: PageView(
//               controller: _pageController,
//               onPageChanged: (index) => setState(() => _selectedIndex = index),
//               children: [_page(), const DiscoverPage(), const ProfilePage()],
//             ),
//           ),
//           if (_selectedIndex == 0)
//             Positioned(
//               top: 0,
//               left: 0,
//               right: 0,
//               child: AnimatedOpacity(
//                 duration: const Duration(milliseconds: 20),
//                 opacity: _showSmallTitle ? 1.0 : 0.0,
//                 child: ClipRect(
//                   child: BackdropFilter(
//                     filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//                     child: Container(
//                       height: MediaQuery.of(context).padding.top + 52,
//                       padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withAlpha(190),
//                         border: Border(
//                           bottom: BorderSide(
//                             color: const Color(0xFF08314D).withAlpha(15),
//                             width: 0.8,
//                           ),
//                         ),
//                       ),
//                       alignment: Alignment.center,
//                       child: const Text(
//                         "Sohbetler",
//                         style: TextStyle(
//                           color: Color.fromARGB(255, 6, 44, 65),
//                           fontSize: 17,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           Positioned(
//             left: 20,
//             right: 20,
//             bottom: MediaQuery.of(context).padding.bottom + 12,
//             child: CustomGlassNavBar(
//               selectedIndex: _selectedIndex,
//               currentPage: _currentPage,
//               pageController: _pageController,
//               onPageSelected: (index) => setState(() {
//                 _selectedIndex = index;
//                 _currentPage = index.toDouble();
//               }),
//               onPageDragged: (page) => setState(() => _currentPage = page),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _page() {
//     switch (_selectedIndex) {
//       case 0:
//         final filteredUsers = users.where((user) {
//           return user["name"].toString().toLowerCase().contains(
//             _searchText.toLowerCase(),
//           );
//         }).toList();

//         final totalUnread = users.fold<int>(
//           0,
//           (sum, item) => sum + ((item["unread"] as int?) ?? 0),
//         );

//         return ListView(
//           controller: _scrollController,
//           physics: const BouncingScrollPhysics(),
//           padding: EdgeInsets.only(
//             top: MediaQuery.of(context).padding.top + 16,
//             bottom: 120,
//           ),
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Row(
//                     children: [
//                       const Text(
//                         "Sohbetler",
//                         style: TextStyle(
//                           fontSize: 30,
//                           fontWeight: FontWeight.w800,
//                           color: Color(0xFF041B2A),
//                           letterSpacing: -0.6,
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       if (totalUnread > 0)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF08314D).withAlpha(18),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             "$totalUnread yeni",
//                             style: const TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF08314D),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   GestureDetector(
//                     behavior: HitTestBehavior.opaque,
//                     onTap: _openNewChatOptions,
//                     child: Padding(
//                       padding: const EdgeInsets.all(8.0),
//                       child: Container(
//                         width: 42,
//                         height: 42,
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF08314D).withAlpha(15),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Icon(
//                           Icons.add_rounded,
//                           color: Color(0xFF08314D),
//                           size: 26,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 18),
//               child: Container(
//                 height: 46,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withAlpha(210),
//                   borderRadius: BorderRadius.circular(24),
//                   border: Border.all(color: Colors.white, width: 1.2),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFF08314D).withAlpha(8),
//                       blurRadius: 16,
//                       spreadRadius: 0,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 alignment: Alignment.center,
//                 child: TextField(
//                   controller: _searchController,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF1F2937),
//                   ),
//                   decoration: InputDecoration(
//                     border: InputBorder.none,
//                     enabledBorder: InputBorder.none,
//                     focusedBorder: InputBorder.none,
//                     filled: true,
//                     fillColor: Colors.transparent,
//                     isDense: true,
//                     contentPadding: const EdgeInsets.symmetric(vertical: 0),
//                     prefixIcon: const Padding(
//                       padding: EdgeInsets.only(left: 10, right: 10),
//                       child: Icon(
//                         Icons.search_rounded,
//                         size: 22,
//                         color: Color(0xFF64748B),
//                       ),
//                     ),
//                     prefixIconConstraints: const BoxConstraints(minWidth: 44),
//                     suffixIcon: _searchText.isNotEmpty
//                         ? GestureDetector(
//                             onTap: () {
//                               _searchController.clear();
//                               setState(() => _searchText = "");
//                             },
//                             child: const Icon(
//                               Icons.cancel_rounded,
//                               size: 18,
//                               color: Color(0xFF94A3B8),
//                             ),
//                           )
//                         : null,
//                     hintText: "Sohbetlerde ara...",
//                     hintStyle: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w400,
//                       color: Color(0xFF94A3B8),
//                     ),
//                   ),
//                   onChanged: (value) => setState(() => _searchText = value),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 14),
//             if (filteredUsers.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 40),
//                 child: Center(
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.search_off_rounded,
//                         size: 48,
//                         color: Colors.grey.shade400,
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         "Sonuç bulunamadı",
//                         style: TextStyle(
//                           fontSize: 15,
//                           color: Colors.grey.shade600,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               ...filteredUsers.map(
//                 (user) => MessageTile(
//                   user: user,
//                   onTap: () => _handleTileTap(user),
//                 ),
//               ),
//           ],
//         );

//       case 1:
//         return const DiscoverPage();
//       case 2:
//         return const ProfilePage();
//       default:
//         return const SizedBox();
//     }
//   }
// }