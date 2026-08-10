import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stajapp/themes/tema1.dart';
import 'chats_page.dart';
import 'discover_page.dart';
import 'profile.dart';
import '../services/api_client.dart';
import '../widgets/message_tile.dart';
import '../widgets/custom_glass_nav_bar.dart';
import '../widgets/dialogs/single_chat_dialog.dart';
import '../widgets/dialogs/group_chat_dialog.dart';
import '../widgets/dialogs/new_chat_sheet.dart';

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
  Timer? _pollingTimer;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    loadUser();

    _pageController = PageController(initialPage: _selectedIndex);
    _scrollController.addListener(() {
      final show = _scrollController.offset > 60;
      if (show != _showSmallTitle) {
        setState(() => _showSmallTitle = show);
      }
    });

    _pollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted && _selectedIndex == 0) {
        loadRooms(showLoading: false);
      }
    });

    _setupGlobalFCMListener();
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    _pollingTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showTopNotification({required String title, required String body, dynamic roomId}) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final surfaceColor = Theme.of(context).colorScheme.surface;
        final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor.withAlpha(210),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryNavy.withAlpha(40),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryNavy,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: onSurfaceColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: onSurfaceColor.withAlpha(160),
                              ),
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
      },
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _setupGlobalFCMListener() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;

      final data = message.data;
      final String? incomingSenderId = (data['sender_id'] ?? data['senderId'] ?? data['sender'])?.toString();
      final String incomingText = data['message'] ?? data['body'] ?? message.notification?.body ?? "";
      final String title = message.notification?.title ?? "Yeni Mesaj";

      if (incomingSenderId != currentUserId.toString()) {
        _showTopNotification(
          title: title,
          body: incomingText,
          roomId: data['room_id'],
        );

        loadRooms(showLoading: false);
      }
    });
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
              "display_photo": room["display_photo"],
              "name":
                  room["display_name"] ??
                  room["display_username"] ??
                  "Kullanıcı",
              "message": room["last_message"] ?? "Sohbeti başlatın...",
              "time": _formatTime(room["last_message_time"]),
              "unread": unreadVal,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("loadRooms EXCEPTION: $e");
    }
  }

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
        AppTheme.showSnackBar(
          context,
          message: "Böyle bir kullanıcı bulunamadı.",
          isError: true,
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
        final profilePhoto = otherUser?["profile_photo"];

        await loadRooms();
        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          message: isExisting
              ? "Bu kullanıcıyla zaten sohbetiniz var."
              : "Sohbet odası başarıyla oluşturuldu!",
          isError: false,
        );

        if (roomId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatsPage(
                userName: displayName,
                roomId: roomId,
                isGroup: false,
                participants: null,
                userPhotoUrl: profilePhoto,
              ),
            ),
          ).then((_) => loadRooms(showLoading: false));
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Hata oluştu: $e",
        isError: true,
      );
    }
  }

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

        AppTheme.showSnackBar(
          context,
          message: "Grup başarıyla oluşturuldu!",
          isError: false,
        );

        if (roomId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatsPage(
                userName: groupName,
                roomId: roomId,
                isGroup: true,
                participants: null,
                userPhotoUrl: null,
              ),
            ),
          ).then((_) => loadRooms(showLoading: false));
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Hata oluştu: $e",
        isError: true,
      );
    }
  }

  void _openSingleChatDialog() {
    if (token == null || currentUserId == null) return;
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => SingleChatDialog(
        api: api,
        token: token!,
        currentUserId: currentUserId!,
        onCreateChat: _createSingleChat,
      ),
    );
  }

  void _openGroupChatDialog() {
    if (token == null || currentUserId == null) return;
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => GroupChatDialog(
        api: api,
        token: token!,
        currentUserId: currentUserId!,
        onCreateGroup: _createGroupChat,
      ),
    );
  }

  void _openNewChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => NewChatSheet(
        onSingleChatTap: _openSingleChatDialog,
        onGroupChatTap: _openGroupChatDialog,
      ),
    );
  }

  void _handleTileTap(Map<String, dynamic> user) {
    setState(() {
      user["unread"] = 0;
    });

    _pollingTimer?.cancel();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatsPage(
          userName: user["name"],
          roomId: user["room_id"],
          isGroup: user["is_group"] ?? false,
          participants: user["participants"],
          userPhotoUrl: user["display_photo"],
        ),
      ),
    ).then((_) {
      loadRooms(showLoading: false);

      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted && _selectedIndex == 0) {
          loadRooms(showLoading: false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        color: Theme.of(context).colorScheme.surface.withAlpha(200),
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
                            width: 0.8,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "Sohbetler",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
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
            child: CustomGlassNavBar(
              selectedIndex: _selectedIndex,
              currentPage: _currentPage,
              pageController: _pageController,
              onPageSelected: (index) => setState(() {
                _selectedIndex = index;
                _currentPage = index.toDouble();
              }),
              onPageDragged: (page) => setState(() => _currentPage = page),
            ),
          ),
        ],
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

        final primaryColor = Theme.of(context).colorScheme.primary;
        final surfaceColor = Theme.of(context).colorScheme.surface;
        final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

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
                      Text(
                        "Sohbetler",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: onSurfaceColor,
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
                            color: primaryColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$totalUnread yeni",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
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
                          color: primaryColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: primaryColor,
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
                  color: surfaceColor.withAlpha(220),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: onSurfaceColor.withAlpha(20),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: onSurfaceColor,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: onSurfaceColor.withAlpha(140),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 44),
                    suffixIcon: _searchText.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchText = "");
                            },
                            child: Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: onSurfaceColor.withAlpha(120),
                            ),
                          )
                        : null,
                    hintText: "Sohbetlerde ara...",
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: onSurfaceColor.withAlpha(120),
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
                        color: onSurfaceColor.withAlpha(100),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sonuç bulunamadı",
                        style: TextStyle(
                          fontSize: 15,
                          color: onSurfaceColor.withAlpha(140),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredUsers.map(
                (user) =>
                    MessageTile(user: user, onTap: () => _handleTileTap(user)),
              ),
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
}