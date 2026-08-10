import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stajapp/themes/tema1.dart';
import '../services/api_client.dart';

class ChatsPage extends StatefulWidget {
  final String userName;
  final int roomId;

  const ChatsPage({
    super.key,
    required this.userName,
    required this.roomId,
    required isGroup,
    required participants,
  });

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // ScrollController eklendi
  final ApiClient api = ApiClient();

  String? token;
  int? currentUserId;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;

  // FCM Dinleyicisi Abone Değişkeni
  StreamSubscription<RemoteMessage>? _fcmSubscription;

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
    loadMessages();
    _setupFCMListener(); // FCM Dinleyicisi Başlatıldı
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel(); // Sayfadan çıkılınca dinleyiciyi kapatıyoruz
    _messageController.dispose();
    _scrollController.dispose(); // Memory leak önlemek için eklendi
    super.dispose();
  }

  // --- CANLI MESAJ DİNLEYİCİSİ ---
  void _setupFCMListener() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;

      final data = message.data;

      // Backend'den farklı türde gelebilecek room_id ve sender_id 'yi garantiye alıyoruz
      final String? incomingRoomId = (data['room_id'] ?? data['roomId'] ?? data['room'])?.toString();
      final String? incomingSenderId = (data['sender_id'] ?? data['senderId'] ?? data['sender'])?.toString();
      final String incomingText = data['message'] ?? data['body'] ?? message.notification?.body ?? "";

      // Tip uyuşmazlığını engellemek için ikisini de trim edip karşılaştırıyoruz
      final bool isSameRoom = incomingRoomId != null &&
          incomingRoomId.trim() == widget.roomId.toString().trim();

      // 1. Kullanıcı ŞU AN o sohbet odasındaysa:
      if (isSameRoom) {
        // Eğer gelen mesaj kendi attığımız mesaj değilse listeye ekle
        if (incomingSenderId != currentUserId.toString()) {
          setState(() {
            messages.add({
              "sender_id": incomingSenderId,
              "message": incomingText,
              "timestamp": data['timestamp'] ?? DateTime.now().toIso8601String(),
            });
          });

          // Mesaj gelince sayfayı OTOMATİK EN ALTA KAYDIR
          _scrollToBottom();

          // Okundu bilgisi gönder
          if (token != null && currentUserId != null) {
            api.markAsRead(
              token: token!,
              userId: currentUserId!,
              roomId: widget.roomId,
            );
          }
        }
      } else {
        // 2. Kullanıcı başka bir odada veya sayfadaysa SnackBar göster
        final title = message.notification?.title ?? widget.userName;
        final body = message.notification?.body ?? incomingText;

        AppTheme.showSnackBar(
          context,
          message: "$title: $body",
          isError: false,
        );
      }
    });
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
        _scrollToBottom(); // Mesajlar yüklenince en alta kaydır
      }
    } catch (e) {
      debugPrint("Mesaj yükleme hatası: $e");
      if (mounted) setState(() => isLoading = false);
    }
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
    _scrollToBottom(); // Mesaj gönderilince en alta kaydır

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

  @override
  Widget build(BuildContext context) {
    final String firstLetter = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : "?";

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
                  title: Row(
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
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryNavy,
                                      AppTheme.secondaryNavy,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
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
                      Column(
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
                        ],
                      ),
                    ],
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

                      return Align(
                        alignment: me
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.70,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  message["message"]?.toString() ?? "",
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                    color: me ? Colors.white : onSurfaceColor,
                                  ),
                                ),
                              ),
                              if (formattedTime.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 1),
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: me
                                          ? Colors.white.withAlpha(180)
                                          : onSurfaceColor.withAlpha(120),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor.withAlpha(220),
                        borderRadius: BorderRadius.circular(28),
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