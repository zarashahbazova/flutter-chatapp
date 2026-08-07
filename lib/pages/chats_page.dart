// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/api_client.dart';

// class ChatsPage extends StatefulWidget {
//   final String userName;
//   final int roomId;

//   const ChatsPage({super.key, required this.userName, required this.roomId});

//   @override
//   State<ChatsPage> createState() => _ChatsPageState();
// }

// class _ChatsPageState extends State<ChatsPage> {
//   final TextEditingController _messageController = TextEditingController();
//   final ApiClient api = ApiClient();

//   String? token;
//   int? currentUserId;

//   List<Map<String, dynamic>> messages = [];

//   bool isLoading = true;

//   @override
//   void dispose() {
//     _messageController.dispose();
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//     loadMessages();
//   }

//   Future<void> loadMessages() async {
//     final prefs = await SharedPreferences.getInstance();

//     token = prefs.getString("token");
//     currentUserId = prefs.getInt("userId");

//     final response = await api.messages(
//       token: token!,
//       roomId: widget.roomId,
//       userId: currentUserId!,
//     );
//     final json = jsonDecode(response.body);

//     setState(() {
//       messages = List<Map<String, dynamic>>.from(json["data"]["messages"]);
//       isLoading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String firstLetter = widget.userName.isNotEmpty
//         ? widget.userName[0].toUpperCase()
//         : "?";

//     return Scaffold(
//       backgroundColor: const Color(0xFFF4F6F9),
//       extendBodyBehindAppBar: true,

//       // Cam (Glassmorphic) AppBar
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(85),
//         child: ClipRect(
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
//             child: Container(
//               color: Colors.white.withAlpha(190),
//               child: SafeArea(
//                 bottom: false,
//                 child: AppBar(
//                   elevation: 0,
//                   backgroundColor: Colors.transparent,
//                   surfaceTintColor: Colors.transparent,
//                   titleSpacing: 0,
//                   toolbarHeight: 85, // AppBar yüksekliğini eşledik
//                   leading: IconButton(
//                     icon: const Icon(
//                       Icons.arrow_back_ios_new_rounded,
//                       color: Color(0xFF041B2A),
//                       size: 20,
//                     ),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   title: Row(
//                     crossAxisAlignment:
//                         CrossAxisAlignment.center, // Dikeyde tam ortalama
//                     children: [
//                       // Tam Daire Olan Avatar
//                       Center(
//                         child: SizedBox(
//                           width: 42,
//                           height: 42,
//                           child: Stack(
//                             children: [
//                               Container(
//                                 width: 42,
//                                 height: 42,
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   gradient: const LinearGradient(
//                                     colors: [
//                                       Color(0xFF08314D),
//                                       Color(0xFF1E5276),
//                                     ],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: const Color(
//                                         0xFF08314D,
//                                       ).withAlpha(40),
//                                       blurRadius: 6,
//                                       offset: const Offset(0, 2),
//                                     ),
//                                   ],
//                                 ),
//                                 alignment: Alignment.center,
//                                 child: Text(
//                                   firstLetter,
//                                   style: const TextStyle(
//                                     fontSize: 17,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                 right: 0,
//                                 bottom: 0,
//                                 child: Container(
//                                   width: 11,
//                                   height: 11,
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF10B981),
//                                     shape: BoxShape.circle,
//                                     border: Border.all(
//                                       color: Colors.white,
//                                       width: 2,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       // Kullanıcı İsmi ve Durumu
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisAlignment:
//                             MainAxisAlignment.center, // Dikeyde tam ortalama
//                         children: [
//                           Text(
//                             widget.userName,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w700,
//                               color: Color(0xFF0F172A),
//                               letterSpacing: -0.3,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           const Text(
//                             "Çevrimiçi",
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: Color(0xFF10B981),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),

//       body: Column(
//         children: [
//           // 1. Mesaj Listesi Katmanı
//           Expanded(
//             child: ListView.builder(
//               physics: const BouncingScrollPhysics(),
//               padding: EdgeInsets.only(
//                 left: 16,
//                 right: 16,
//                 top: MediaQuery.of(context).padding.top + 95,
//                 bottom: 16,
//               ),
//               itemCount: messages.length,
//               itemBuilder: (context, index) {
//                 final message = messages[index];
//                 final bool me = message["sender_id"] == currentUserId;

//                 return Align(
//                   alignment: me ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     constraints: BoxConstraints(
//                       maxWidth: MediaQuery.of(context).size.width * 0.60,
//                     ),
//                     margin: const EdgeInsets.only(bottom: 10),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: me
//                           ? const Color(0xFF08314D)
//                           : Colors.white.withAlpha(220),
//                       borderRadius: BorderRadius.only(
//                         topLeft: const Radius.circular(20),
//                         topRight: const Radius.circular(20),
//                         bottomLeft: Radius.circular(me ? 20 : 4),
//                         bottomRight: Radius.circular(me ? 4 : 20),
//                       ),
//                       border: Border.all(
//                         color: me ? Colors.transparent : Colors.white,
//                         width: 1,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: me
//                               ? const Color(0xFF08314D).withAlpha(25)
//                               : Colors.black.withAlpha(8),
//                           blurRadius: 10,
//                           spreadRadius: 0,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Flexible(
//                           child: Text(
//                             message["message"].toString(),
//                             style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.w400,
//                               color: me
//                                   ? Colors.white
//                                   : const Color(0xFF0F172A),
//                               height: 1.3,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 1),
//                           child: Text(
//                             message["timestamp"].toString(),
//                             style: TextStyle(
//                               fontSize: 11,
//                               fontWeight: FontWeight.w400,
//                               color: me
//                                   ? Colors.white.withAlpha(170)
//                                   : const Color(0xFF94A3B8),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           // 2. Alt Mesaj Gönderme Çubuğu
//           SafeArea(
//             top: false,
//             child: Container(
//               padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF4F6F9),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withAlpha(5),
//                     blurRadius: 10,
//                     offset: const Offset(0, -4),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white.withAlpha(220),
//                         borderRadius: BorderRadius.circular(28),
//                         border: Border.all(color: Colors.white, width: 1.2),
//                         boxShadow: [
//                           BoxShadow(
//                             color: const Color(0xFF08314D).withAlpha(8),
//                             blurRadius: 12,
//                             offset: const Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: TextField(
//                         controller: _messageController,
//                         style: const TextStyle(
//                           fontSize: 15,
//                           fontWeight: FontWeight.w500,
//                           color: Color(0xFF1F2937),
//                         ),
//                         decoration: const InputDecoration(
//                           hintText: "Mesaj yaz...",
//                           hintStyle: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w400,
//                             color: Color(0xFF94A3B8),
//                           ),
//                           border: InputBorder.none,
//                           enabledBorder: InputBorder.none,
//                           focusedBorder: InputBorder.none,
//                           filled: true,
//                           fillColor: Colors.transparent,
//                           isDense: true,
//                           contentPadding: EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 13,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),

//                   // Gönder Butonu
//                   Container(
//                     width: 46,
//                     height: 46,
//                     decoration: BoxDecoration(
//                       gradient: const LinearGradient(
//                         colors: [Color(0xFF08314D), Color(0xFF1E5276)],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: const Color(0xFF08314D).withAlpha(45),
//                           blurRadius: 10,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Material(
//                       color: Colors.transparent,
//                       shape: const CircleBorder(),
//                       child: InkWell(
//                         customBorder: const CircleBorder(),
//                         onTap: () {
//                           if (_messageController.text.trim().isNotEmpty) {
//                             setState(() {
//                               messages.add({
//                                 "me": true,
//                                 "text": _messageController.text.trim(),
//                                 "time":
//                                     "${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}",
//                               });
//                               _messageController.clear();
//                             });
//                           }
//                         },
//                         child: const Icon(
//                           Icons.send_rounded,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
  final ApiClient api = ApiClient();

  String? token;
  int? currentUserId;

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  // Tarih / Saat Formatlayıcı (ISO string veya DateTime kabul eder)
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

  // 1. MESAJLARI BACKEND'DEN ÇEKME
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
      }
    } catch (e) {
      debugPrint("Mesaj yükleme hatası: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 2. MESAJ GÖNDERME İŞLEMİ
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || token == null || currentUserId == null) return;

    _messageController.clear();

    // UI'da anında göstermek için geçici yerel ekleme (Optimistic UI)
    final tempMessage = {
      "sender_id": currentUserId,
      "message": text,
      "timestamp": DateTime.now().toIso8601String(),
    };

    setState(() {
      messages.add(tempMessage);
    });

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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      extendBodyBehindAppBar: true,

      // Cam (Glassmorphic) AppBar
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.white.withAlpha(190),
              child: SafeArea(
                bottom: false,
                child: AppBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  titleSpacing: 0,
                  toolbarHeight: 85,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF041B2A),
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
                                      Color(0xFF08314D),
                                      Color(0xFF1E5276),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
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
          // 1. Mesaj Listesi Katmanı
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
                                ? const Color(0xFF08314D)
                                : Colors.white.withAlpha(220),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(me ? 20 : 4),
                              bottomRight: Radius.circular(me ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
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
                                    color: me
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
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
                                          ? Colors.white.withAlpha(70)
                                          : const Color(0xFF94A3B8),
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

          // 2. Alt Mesaj Gönderme Çubuğu
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: "Mesaj yaz...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
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
                      backgroundColor: Color(0xFF08314D),
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
