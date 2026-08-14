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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

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
    _fcmSubscription?.cancel();
    _messageController.dispose();
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

          _scrollToBottom();

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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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

      if (response.statusCode != 200) {
        return;
      }

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
    if (!widget.isGroup || token == null || currentUserId == null) {
      return;
    }

    try {
      final response = await api.rooms(token: token!, userId: currentUserId!);

      if (response.statusCode != 200 || !mounted) {
        return;
      }

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

  // 🔍 Katılımcılardan Gönderenin Adını Bulma Yardımcısı
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

  // 🗑️ MESAJI SİLME DİYALOĞU
  void _confirmDeleteMessage(int index, Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                minimumSize: const Size(90, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(index, message);
              },
              child: const Text("Sil", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMessage(int index, Map<String, dynamic> message) async {
    final messageId = message["message_id"] ?? message["id"];

    if (token == null || currentUserId == null || messageId == null) {
      AppTheme.showSnackBar(
        context,
        message: "Mesaj bilgisi alınamadı.",
        isError: true,
      );
      return;
    }

    // Sadece kendi mesajını silme kontrolü (Backend de kontrol ediyor)
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
          messages[index]["is_deleted"] = true;
          messages[index]["message"] = null;
          messages[index]["image_url"] = null;
        });

        AppTheme.showSnackBar(
          context,
          message: "Mesaj başarıyla silindi.",
          isError: false,
        );
        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message: "Mesaj başarıyla silindi.",
          isError: false,
        );
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message: data["error"] ?? "Mesaj silinemedi.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Bir hata oluştu: $e",
        isError: true,
      );
    }
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString("token");
    currentUserId = prefs.getInt("userId");

    if (token == null || currentUserId == null) return;
    try {
      await api.markAsRead(
        token: token!,
        userId: currentUserId!,
        roomId: widget.roomId,
      );
    } catch (e) {
      debugPrint("markAsRead Hatası: $e");
    }
    try {
      final response = await api.messages(
        token: token!,
        roomId: widget.roomId,
        userId: currentUserId!,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          messages = List<Map<String, dynamic>>.from(json["data"]["messages"]);
          isLoading = false;
        });
        if (widget.isGroup) {
          await _loadGroupInfo();
        }
        _scrollToBottom();
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
        messages = newMessages;
      });

      _scrollToBottom();

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
    if (oldMessages.length != newMessages.length) {
      return false;
    }

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
        imageQuality: 75,
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
          if (!mounted) return;
          AppTheme.showSnackBar(
            context,
            message: "Hata oluştu: $e",
            isError: true,
          );
        } finally {
          if (mounted) setState(() => isSendingImage = false);
        }
      }
    } else {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Gerekli izin verilmedi.",
        isError: true,
      );
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryNavy.withAlpha(15),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  title: const Text(
                    "Kamera",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryNavy.withAlpha(15),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  title: const Text(
                    "Galeri",
                    style: TextStyle(fontWeight: FontWeight.bold),
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
    final String firstLetter = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : "?";

    final String? fullHeaderPhotoUrl =
        (widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty)
        ? "${ApiClient.baseUrl}${widget.userPhotoUrl!.startsWith('/') ? widget.userPhotoUrl : '/${widget.userPhotoUrl}'}"
        : null;

    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: surfaceColor.withAlpha(200),
              child: SafeArea(
                bottom: false,
                child: AppBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  titleSpacing: 0,
                  toolbarHeight: 85,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: onSurfaceColor,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: GestureDetector(
                    onTap: _navigateToGroupDetail,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: Stack(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: fullHeaderPhotoUrl == null
                                        ? const LinearGradient(
                                            colors: [
                                              AppTheme.primaryNavy,
                                              AppTheme.secondaryNavy,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
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
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          firstLetter,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ],
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: onSurfaceColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              if (widget.isGroup &&
                                  widget.participants != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  (widget.participants as List)
                                      .map(
                                        (p) => p["user_name"] ?? p["full_name"],
                                      )
                                      .join(", "),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: onSurfaceColor.withAlpha(140),
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

      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: MediaQuery.of(context).padding.top + 95,
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

                      final String? fullMsgImageUrl =
                          (imageUrl != null && imageUrl.isNotEmpty)
                          ? "${ApiClient.baseUrl}${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}"
                          : null;
                      final bool isDeleted = message["is_deleted"] == true;

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

                      final String displayedText = isLongMessage && !isExpanded
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
                              : () => _confirmDeleteMessage(
                                  index,
                                  message,
                                ), // 👈 Basılı tutunca silme
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.70,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: me
                                  ? AppTheme.primaryNavy
                                  : surfaceColor.withAlpha(220),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(me ? 20 : 4),
                                bottomRight: Radius.circular(me ? 4 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // --- 0. GRUP MESAJINDA GÖNDERENİN ADI ---
                                if (widget.isGroup && !me) ...[
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],

                                // --- 1. FOTOĞRAF VARSA GÖSTERİMİ ---
                                if (fullMsgImageUrl != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      fullMsgImageUrl,
                                      fit: BoxFit.cover,
                                      frameBuilder:
                                          (
                                            context,
                                            child,
                                            frame,
                                            wasSynchronouslyLoaded,
                                          ) {
                                            if (frame != null ||
                                                wasSynchronouslyLoaded) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    if (mounted) {
                                                      _scrollToBottom();
                                                    }
                                                  });
                                            }
                                            return child;
                                          },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.broken_image_rounded,
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
                                            );
                                          },
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                // --- 2. MESAJ METNİ VE SAAT HİZALAMASI ---
                                if (messageText.trim().isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
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
                                                fontSize: 15,
                                                height: 1.3,
                                                fontStyle: isDeleted
                                                    ? FontStyle.italic
                                                    : FontStyle.normal,
                                                color: isDeleted
                                                    ? Color.fromARGB(255, 182, 183, 190)
                                                      
                                                  
                                                    : me
                                                    ? AppTheme.backgroundColor
                                                    : onSurfaceColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (formattedTime.isNotEmpty)
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w400,
                                                color: me
                                                    ? Colors.white.withAlpha(
                                                        180,
                                                      )
                                                    : onSurfaceColor.withAlpha(
                                                        120,
                                                      ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (isLongMessage)
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
                                              minimumSize: const Size(0, 30),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              isExpanded
                                                  ? "Daha az göster"
                                                  : "Devam et",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: me
                                                    ? Colors.white
                                                    : const Color.fromARGB(
                                                        255,
                                                        118,
                                                        99,
                                                        148,
                                                      ),
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

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: isSendingImage ? null : _showMediaOptions,
                    icon: isSendingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.add_circle_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor.withAlpha(220),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: onSurfaceColor),
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: "Mesaj yaz...",
                          hintStyle: TextStyle(
                            color: onSurfaceColor.withAlpha(120),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: _sendMessage,
                    child: const CircleAvatar(
                      radius: 23,
                      backgroundColor: AppTheme.primaryNavy,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
