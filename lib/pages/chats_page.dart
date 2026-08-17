import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:Lafla/pages/group_detail_page.dart';
import 'package:Lafla/themes/tema1.dart';
import 'package:Lafla/widgets/dialogs/user_profile_dialog.dart';
import '../services/api_client.dart';

class ChatsPage extends StatefulWidget {
  final String userName;
  final int roomId;
  final String? userPhotoUrl;
  final String? roomDesc;
  final bool isGroup;
  final dynamic participants;
  final int adminId;

  const ChatsPage({
    super.key,
    required this.userName,
    this.roomDesc,
    required this.roomId,
    this.userPhotoUrl,
    this.isGroup = false,
    this.participants,
    required this.adminId,
  });

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiClient api = ApiClient();
  final ImagePicker _picker = ImagePicker();

  String? token;
  int? currentUserId;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSendingImage = false;
  List<dynamic> groupParticipants = [];
  Timer? _messagesTimer;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  final Set<String> _expandedMessages = {};
  final Set<String> _pendingDeleteIds = {};

  // 🔽 Akıllı kaydırma ve okunmamış mesaj durumu
  bool _showScrollToBottomBtn = false;
  bool _isNearBottom = true;
  bool _showUnreadBanner = false;
  int _unreadCount = 0;
  Timer? _unreadBannerTimer;

  bool _isAtBottom() {
    if (!_scrollController.hasClients) return true;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return (maxScroll - currentScroll) <= 120;
  }

  void _onScroll() {
    final nearBottom = _isAtBottom();
    if (nearBottom != _isNearBottom) {
      setState(() {
        _isNearBottom = nearBottom;
        _showScrollToBottomBtn = !nearBottom;
      });
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);

    if (widget.isGroup && widget.participants != null) {
      groupParticipants = List<dynamic>.from(widget.participants);
    }

    loadMessages();
    _setupFCMListener();

    _messagesTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshMessages(),
    );
  }

  @override
  void dispose() {
    _messagesTimer?.cancel();
    _unreadBannerTimer?.cancel();
    _fcmSubscription?.cancel();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _setupFCMListener() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (!mounted) return;

      final data = message.data;
      final String? incomingRoomId =
          (data['room_id'] ?? data['roomId'] ?? data['room'])?.toString();
      final String? incomingSenderId =
          (data['sender_id'] ?? data['senderId'] ?? data['sender'])?.toString();
      final String incomingText =
          data['message'] ?? data['body'] ?? message.notification?.body ?? "";
      final String? incomingImageUrl = data['image_url'];

      final bool isSameRoom =
          incomingRoomId != null &&
          incomingRoomId.trim() == widget.roomId.toString().trim();

      if (isSameRoom) {
        if (incomingSenderId != currentUserId.toString()) {
          setState(() {
            messages.add({
              "sender_id": incomingSenderId,
              "sender_name": data['sender_name'] ?? data['sender_username'],
              "message": incomingText,
              "image_url": incomingImageUrl,
              "timestamp":
                  data['timestamp'] ?? DateTime.now().toIso8601String(),
            });
          });

          // Kullanıcı en alttaysa otomatik indir, yukarıdaysa indirme butonu çıkar
          if (_isNearBottom) {
            _scrollToBottom();
          } else {
            setState(() {
              _showScrollToBottomBtn = true;
            });
          }

          if (token != null && currentUserId != null) {
            api.markAsRead(
              token: token!,
              userId: currentUserId!,
              roomId: widget.roomId,
            );
          }
        }
      } else {
        final title = message.notification?.title ?? widget.userName;
        final body = message.notification?.body ?? incomingText;
        _showTopNotificationInChat(title: title, body: body);
      }
    });
  }

  void _showTopNotificationInChat({
    required String title,
    required String body,
  }) {
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surfaceColor = AppTheme.getSurfaceColor(isDark);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceColor.withAlpha(220),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.getCardBorder(isDark),
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.getIconBg(isDark),
                        ),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppTheme.getIconFg(isDark),
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
                                color: AppTheme.getSectionHeaderColor(isDark),
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

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Future<void> _loadGroupDetailsAndNavigate() async {
    if (token == null || currentUserId == null) return;

    try {
      final response = await api.rooms(token: token!, userId: currentUserId!);
      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      final List rooms = data["data"]["rooms"] ?? [];

      final room = rooms.firstWhere(
        (r) => r["room_id"].toString() == widget.roomId.toString(),
        orElse: () => null,
      );

      if (room == null || !mounted) return;

      final List participants = List<dynamic>.from(room["participants"] ?? []);
      final String? groupPhotoUrl = room["display_photo"];
      final String? roomDesc = room["display_description"];
      final int adminId =
          int.tryParse(room["admin_id"]?.toString() ?? "") ?? widget.adminId;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailPage(
            roomName: room["display_name"] ?? widget.userName,
            roomDesc: roomDesc,
            roomId: widget.roomId,
            groupPhotoUrl: groupPhotoUrl,
            adminId: adminId,
            currentUserId: currentUserId!,
            participants: participants,
            token: token!,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Grup bilgileri alınırken hata: $e");
    }
  }

  Future<void> _loadGroupInfo() async {
    if (!widget.isGroup || token == null || currentUserId == null) return;

    try {
      final response = await api.rooms(token: token!, userId: currentUserId!);
      if (response.statusCode != 200 || !mounted) return;

      final data = jsonDecode(response.body);
      final List rooms = data["data"]["rooms"] ?? [];

      final room = rooms.firstWhere(
        (r) => r["room_id"].toString() == widget.roomId.toString(),
        orElse: () => null,
      );

      if (room == null) return;

      setState(() {
        groupParticipants = List<dynamic>.from(room["participants"] ?? []);
      });
    } catch (e) {
      debugPrint("Grup bilgileri alınamadı: $e");
    }
  }

  void _navigateToGroupDetail() {
    if (widget.isGroup) {
      _loadGroupDetailsAndNavigate();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileDialog(
            user: {
              "full_name": widget.userName,
              "user_name": widget.userName,
              "profile_photo": widget.userPhotoUrl,
            },
          ),
        ),
      );
    }
  }

  String _messageKey(Map<String, dynamic> message, int index) {
    return "${message["id"] ?? message["sender_id"]}_${message["timestamp"]}_$index";
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "";
    try {
      DateTime dt;
      if (timestamp is DateTime) {
        dt = timestamp;
      } else {
        dt = DateTime.parse(timestamp.toString()).toLocal();
      }
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (_) {
      return "";
    }
  }

  String _getSenderName(Map<String, dynamic> message) {
    if (message["sender_name"] != null &&
        message["sender_name"].toString().isNotEmpty) {
      return message["sender_name"].toString();
    }
    final senderId = message["sender_id"]?.toString();
    if (senderId != null && groupParticipants.isNotEmpty) {
      final participant = groupParticipants.firstWhere(
        (p) =>
            p["id"]?.toString() == senderId ||
            p["user_id"]?.toString() == senderId,
        orElse: () => null,
      );
      if (participant != null) {
        return participant["full_name"] ??
            participant["user_name"] ??
            "Kullanıcı";
      }
    }
    return "Kullanıcı";
  }

  void _confirmDeleteMessage(int index, Map<String, dynamic> message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.getSurfaceColor(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.getCardBorder(isDark)),
          ),
          title: const Text(
            "Mesajı Sil",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Bu mesajı silmek istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                minimumSize: const Size(85, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _scheduleDeleteMessage(index, message);
              },
              child: const Text(
                "Sil",
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

  Future<void> _deleteMessage(int index, Map<String, dynamic> message) async {
    final messageId = message["message_id"] ?? message["id"];

    if (token == null || currentUserId == null || messageId == null) return;

    if (message["sender_id"].toString() != currentUserId.toString()) {
      AppTheme.showSnackBar(
        context,
        message: "Sadece kendi gönderdiğiniz mesajları silebilirsiniz.",
        isError: true,
      );
      return;
    }

    try {
      final response = await api.deleteMessage(
        token: token!,
        messageId: int.parse(messageId.toString()),
        userId: currentUserId!,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _pendingDeleteIds.remove(messageId.toString());
          messages[index]["is_deleted"] = true;
          messages[index]["message"] = null;
          messages[index]["image_url"] = null;
        });
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showSnackBar(context, message: "Hata: $e", isError: true);
      }
    }
  }

  void _scheduleDeleteMessage(int index, Map<String, dynamic> message) {
    final messageId = message["message_id"] ?? message["id"];
    if (messageId == null) return;

    final String messageIdString = messageId.toString();

    setState(() {
      _pendingDeleteIds.add(messageIdString);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Mesaj silindi."),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: "GERİ AL",
          textColor: Colors.white,
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _pendingDeleteIds.remove(messageIdString);
            });
          },
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 5), () async {
      if (!mounted) return;
      if (!_pendingDeleteIds.contains(messageIdString)) return;

      final currentIndex = messages.indexWhere((item) {
        final id = item["message_id"] ?? item["id"];
        return id?.toString() == messageIdString;
      });

      if (currentIndex != -1) {
        await _deleteMessage(currentIndex, messages[currentIndex]);
      }
    });
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    currentUserId = prefs.getInt("userId");

    if (token == null || currentUserId == null) return;

    try {
      final response = await api.messages(
        token: token!,
        roomId: widget.roomId,
        userId: currentUserId!,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!mounted) return;

        final rawList = List<Map<String, dynamic>>.from(
          json["data"]["messages"],
        );

        // Okunmamış mesaj sayısını hesapla
        final unread = rawList
            .where(
              (m) =>
                  m["sender_id"].toString() != currentUserId.toString() &&
                  m["is_read"] == false,
            )
            .length;

        setState(() {
          messages = rawList;
          isLoading = false;
          _unreadCount = unread;
          if (_unreadCount > 0) {
            _showUnreadBanner = true;
          }
        });

        if (widget.isGroup) {
          await _loadGroupInfo();
        }

        // Açılışta doğrudan en alta kaydır
        _scrollToBottom(animate: false);

        // 5 saniye sonra okunmadı banner'ını otomatik gizle
        if (_showUnreadBanner) {
          _unreadBannerTimer?.cancel();
          _unreadBannerTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() => _showUnreadBanner = false);
            }
          });
        }

        // Okundu olarak işaretle
        await api.markAsRead(
          token: token!,
          userId: currentUserId!,
          roomId: widget.roomId,
        );
      }
    } catch (e) {
      debugPrint("Mesaj yükleme hatası: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _refreshMessages() async {
    if (!mounted || token == null || currentUserId == null) return;

    try {
      final response = await api.messages(
        token: token!,
        roomId: widget.roomId,
        userId: currentUserId!,
      );

      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body);
      final List<Map<String, dynamic>> newMessages =
          List<Map<String, dynamic>>.from(json["data"]["messages"]);

      if (!mounted) return;

      if (_areMessagesSame(messages, newMessages)) {
        return;
      }

      setState(() {
        for (final newMessage in newMessages) {
          final id = newMessage["message_id"] ?? newMessage["id"];
          if (id != null && _pendingDeleteIds.contains(id.toString())) {
            newMessage["is_deleted"] = true;
            newMessage["message"] = null;
            newMessage["image_url"] = null;
          }
        }
        messages = newMessages;
      });

      // Eğer kullanıcı en alttaysa yeni mesaj geldiğinde indir, yukarıdaysa butonu göster
      if (_isNearBottom) {
        _scrollToBottom();
      } else {
        setState(() => _showScrollToBottomBtn = true);
      }

      await api.markAsRead(
        token: token!,
        userId: currentUserId!,
        roomId: widget.roomId,
      );
    } catch (e) {
      debugPrint("Mesaj yenileme hatası: $e");
    }
  }

  bool _areMessagesSame(
    List<Map<String, dynamic>> oldMessages,
    List<Map<String, dynamic>> newMessages,
  ) {
    if (oldMessages.length != newMessages.length) return false;

    for (int i = 0; i < oldMessages.length; i++) {
      final oldMessage = oldMessages[i];
      final newMessage = newMessages[i];

      if (oldMessage["message"] != newMessage["message"] ||
          oldMessage["timestamp"] != newMessage["timestamp"] ||
          oldMessage["sender_id"].toString() !=
              newMessage["sender_id"].toString() ||
          oldMessage["image_url"] != newMessage["image_url"]) {
        return false;
      }
    }
    return true;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || token == null || currentUserId == null) return;

    _messageController.clear();

    final tempMessage = {
      "sender_id": currentUserId,
      "message": text,
      "timestamp": DateTime.now().toIso8601String(),
    };

    setState(() {
      messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final response = await api.sendMessage(
        token: token!,
        senderId: currentUserId!,
        roomId: widget.roomId,
        message: text,
      );

      if (response.statusCode != 200) {
        await loadMessages();
      }
    } catch (e) {
      debugPrint("Mesaj gönderilemedi: $e");
      await loadMessages();
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    PermissionStatus status;

    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.photos.request();
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
    }

    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Lütfen ayarlardan izin verin.",
        isError: true,
      );
      openAppSettings();
      return;
    }

    if (status.isGranted || status.isLimited) {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );

      if (image != null && token != null && currentUserId != null) {
        setState(() => isSendingImage = true);

        try {
          final response = await api.sendImageMessage(
            token: token!,
            senderId: currentUserId!,
            roomId: widget.roomId,
            filePath: image.path,
            message: _messageController.text.trim(),
          );

          if (response.statusCode == 200) {
            _messageController.clear();
            await loadMessages();
          } else {
            if (!mounted) return;
            AppTheme.showSnackBar(
              context,
              message: "Fotoğraf gönderilemedi.",
              isError: true,
            );
          }
        } catch (e) {
          if (mounted) {
            AppTheme.showSnackBar(
              context,
              message: "Hata oluştu: $e",
              isError: true,
            );
          }
        } finally {
          if (mounted) setState(() => isSendingImage = false);
        }
      }
    } else {
      if (mounted) {
        AppTheme.showSnackBar(
          context,
          message: "Gerekli izin verilmedi.",
          isError: true,
        );
      }
    }
  }

  void _showMediaOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = AppTheme.getSurfaceColor(isDark);
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurfaceColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.getIconBg(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.getIconFg(isDark),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "Kamera ile Çek",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: onSurfaceColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(ImageSource.camera);
                  },
                ),
                Divider(
                  height: 1,
                  thickness: 0.7,
                  indent: 16,
                  endIndent: 16,
                  color: onSurfaceColor.withAlpha(isDark ? 16 : 10),
                ),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.getIconBg(isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: AppTheme.getIconFg(isDark),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "Galeriden Seç",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: onSurfaceColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(ImageSource.gallery);
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
    final isDark = Theme.brightnessOf(context) == Brightness.dark;
    final surfaceColor = AppTheme.getSurfaceColor(isDark);
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    final String firstLetter = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : "?";

    final String? fullHeaderPhotoUrl =
        (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty)
        ? "${ApiClient.baseUrl}${widget.userPhotoUrl!.startsWith('/') ? widget.userPhotoUrl : '/${widget.userPhotoUrl}'}"
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor.withAlpha(isDark ? 190 : 230),
                border: Border(
                  bottom: BorderSide(
                    color: onSurfaceColor.withAlpha(isDark ? 14 : 10),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: AppBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  titleSpacing: 0,
                  toolbarHeight: 80,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: onSurfaceColor,
                      size: 19,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: GestureDetector(
                    onTap: _navigateToGroupDetail,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.getIconBg(isDark),
                            border: Border.all(
                              color: AppTheme.getAvatarBorder(isDark),
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: fullHeaderPhotoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    fullHeaderPhotoUrl,
                                    width: 42,
                                    height: 42,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(
                                      firstLetter,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: onSurfaceColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Text(
                                  firstLetter,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: onSurfaceColor,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: onSurfaceColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (widget.isGroup &&
                                  widget.participants != null) ...[
                                const SizedBox(height: 1),
                                Text(
                                  (widget.participants as List)
                                      .map(
                                        (p) => p["user_name"] ?? p["full_name"],
                                      )
                                      .join(", "),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.getSectionHeaderColor(
                                      isDark,
                                    ),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: MediaQuery.of(context).padding.top + 96,
                          bottom: 16,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final bool me =
                              message["sender_id"].toString() ==
                              currentUserId.toString();
                          final String formattedTime = _formatTime(
                            message["timestamp"],
                          );
                          final String? imageUrl = message["image_url"];
                          final messageId =
                              message["message_id"] ?? message["id"];

                          final bool isDeleted =
                              message["is_deleted"] == true ||
                              (messageId != null &&
                                  _pendingDeleteIds.contains(
                                    messageId.toString(),
                                  ));

                          final String? fullMsgImageUrl =
                              (!isDeleted &&
                                  imageUrl != null &&
                                  imageUrl.isNotEmpty)
                              ? "${ApiClient.baseUrl}${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}"
                              : null;

                          final String messageText = isDeleted
                              ? "Bu mesaj silindi"
                              : (message["message"]?.toString() ?? "");

                          const int maxMessageCharacters = 300;
                          final bool isLongMessage =
                              messageText.length > maxMessageCharacters;
                          final String messageKey = _messageKey(message, index);
                          final bool isExpanded = _expandedMessages.contains(
                            messageKey,
                          );
                          final String displayedText =
                              isLongMessage && !isExpanded
                              ? messageText.substring(0, maxMessageCharacters)
                              : messageText;

                          final String senderName = _getSenderName(message);

                          return Align(
                            alignment: me
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: isDeleted
                                  ? null
                                  : () => _confirmDeleteMessage(index, message),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.74,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  // 🟣 Benim mesajlarım: Tek renk tema açık moru | Silinmiş/Gelen: Nötr
                                  color: isDeleted
                                      ? (isDark
                                            ? const Color(0xFF1B1A1E)
                                            : const Color(0xFFECEBEF))
                                      : (me
                                            ? AppTheme.primaryNavy
                                            : (isDark
                                                  ? AppTheme.darkSurfaceColor
                                                  : Colors.white)),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(me ? 18 : 4),
                                    bottomRight: Radius.circular(me ? 4 : 18),
                                  ),
                                  border: Border.all(
                                    color: (me && !isDeleted)
                                        ? Colors.transparent
                                        : (isDeleted
                                              ? Colors.transparent
                                              : (isDark
                                                    ? AppTheme.darkpurple2
                                                    : const Color(0xFFE5E3EB))),
                                    width: 1,
                                  ),
                                  boxShadow: isDeleted
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(
                                              isDark ? 30 : 6,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.isGroup &&
                                        !me &&
                                        !isDeleted) ...[
                                      Text(
                                        senderName,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppTheme.primaryNavy
                                              : const Color(0xFF5964AA),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                    ],

                                    if (fullMsgImageUrl != null) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          fullMsgImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.broken_image_rounded,
                                                    size: 16,
                                                    color: Colors.white54,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    "Görsel yüklenemedi",
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],

                                    if (messageText.trim().isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  displayedText,
                                                  style: TextStyle(
                                                    fontSize: 14.5,
                                                    height: 1.3,
                                                    fontStyle: isDeleted
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                                    color: isDeleted
                                                        ? (isDark
                                                              ? const Color(
                                                                  0xFF6B6873,
                                                                )
                                                              : const Color(
                                                                  0xFF8A8793,
                                                                ))
                                                        : (me
                                                              ? const Color(
                                                                  0xFF19181B,
                                                                )
                                                              : onSurfaceColor),
                                                    fontWeight:
                                                        (me && !isDeleted)
                                                        ? FontWeight.w500
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (formattedTime.isNotEmpty &&
                                                  !isDeleted)
                                                Text(
                                                  formattedTime,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w400,
                                                    color: me
                                                        ? const Color(
                                                            0xFF19181B,
                                                          ).withAlpha(150)
                                                        : AppTheme.getSectionHeaderColor(
                                                            isDark,
                                                          ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (isLongMessage && !isDeleted)
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    if (isExpanded) {
                                                      _expandedMessages.remove(
                                                        messageKey,
                                                      );
                                                    } else {
                                                      _expandedMessages.add(
                                                        messageKey,
                                                      );
                                                    }
                                                  });
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(
                                                    0,
                                                    26,
                                                  ),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                child: Text(
                                                  isExpanded
                                                      ? "Daha az göster"
                                                      : "Devam et",
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: me
                                                        ? const Color(
                                                            0xFF19181B,
                                                          )
                                                        : AppTheme.primaryNavy,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // 💬 MESAJ YAZMA ÇUBUĞU (YUVARLAK & MODERN TASARIM)
              SafeArea(
                top: false,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                      decoration: BoxDecoration(
                        color: surfaceColor.withAlpha(isDark ? 190 : 230),
                        border: Border(
                          top: BorderSide(
                            color: onSurfaceColor.withAlpha(isDark ? 16 : 10),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Medya Ekle Butonu
                          IconButton(
                            onPressed: isSendingImage
                                ? null
                                : _showMediaOptions,
                            icon: isSendingImage
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: onSurfaceColor.withAlpha(180),
                                    size: 24,
                                  ),
                          ),

                          // Yuvarlak Mesaj Yazma Alanı
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF141316)
                                    : const Color(0xFFF3F2F5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? AppTheme.darkpurple2
                                      : const Color(0xFFE2DFE7),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _messageController,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  color: onSurfaceColor,
                                ),
                                maxLines: 4,
                                minLines: 1,
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  hintText: "Mesaj yaz...",
                                  hintStyle: TextStyle(
                                    fontSize: 14.5,
                                    color: onSurfaceColor.withAlpha(110),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Gönder Butonu (Temanın Açık Moru)
                          InkWell(
                            onTap: _sendMessage,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryNavy,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryNavy.withAlpha(60),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.send_rounded,
                                color: Color(0xFF19181B),
                                size: 19,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 📌 5 SANİYE SONRA KAYBOLAN OKUNMAMIŞ MESAJ BİLDİRİM BANDI
          if (_showUnreadBanner && _unreadCount > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 88,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _showUnreadBanner ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withAlpha(220),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mark_chat_unread_rounded,
                          size: 15,
                          color: Color(0xFF19181B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$_unreadCount yeni okunmamış mesaj",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF19181B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ⬇️ EN AŞAĞI KAYDIR BUTONU (Yukarı kaydırılınca veya yeni mesaj gelince çıkar)
          if (_showScrollToBottomBtn)
            Positioned(
              right: 18,
              bottom: 80,
              child: FloatingActionButton.small(
                elevation: 3,
                backgroundColor: surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark
                        ? AppTheme.darkpurple2
                        : const Color(0xFFE2DFE7),
                  ),
                ),
                onPressed: () => _scrollToBottom(),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: onSurfaceColor,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
