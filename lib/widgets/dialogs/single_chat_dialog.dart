// import 'dart:convert';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:Lafla/themes/tema1.dart';
// import '../../services/api_client.dart';

// class SingleChatDialog extends StatefulWidget {
//   final ApiClient api;
//   final String token;
//   final int currentUserId;
//   final Function(String username) onCreateChat;

//   const SingleChatDialog({
//     super.key,
//     required this.api,
//     required this.token,
//     required this.currentUserId,
//     required this.onCreateChat,
//   });

//   @override
//   State<SingleChatDialog> createState() => _SingleChatDialogState();
// }

// class _SingleChatDialogState extends State<SingleChatDialog> {
//   final TextEditingController usernameController = TextEditingController();
//   List<Map<String, dynamic>> searchSuggestions = [];
//   bool isSearching = false;

//   void performSearch(String query) async {
//     if (query.trim().isEmpty) {
//       setState(() => searchSuggestions = []);
//       return;
//     }
//     setState(() => isSearching = true);
//     try {
//       final response = await widget.api.searchUsers(
//         token: widget.token,
//         query: query,
//         currentUserId: widget.currentUserId,
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           searchSuggestions = List<Map<String, dynamic>>.from(
//             data["data"]["users"],
//           );
//         });
//       }
//     } catch (_) {}
//     setState(() => isSearching = false);
//   }

//   InputDecoration _fieldDecoration({
//     required String label,
//     required String hint,
//     required IconData icon,
//     required Color onSurfaceColor,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: Icon(icon, color: AppTheme.primaryNavy, size: 20),
//       filled: true,
//       fillColor: onSurfaceColor.withAlpha(10),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide(color: onSurfaceColor.withAlpha(20)),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide(color: onSurfaceColor.withAlpha(20)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: AppTheme.primaryNavy, width: 1.6),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final surfaceColor = Theme.of(context).colorScheme.surface;
//     final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Dialog(
//       backgroundColor: Colors.transparent,
//       insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: 500,
//           minWidth: 0,
//           maxHeight: MediaQuery.of(context).size.height - 48,
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(26),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: surfaceColor.withAlpha(isDark ? 215 : 240),
//                 borderRadius: BorderRadius.circular(26),
//                 border: Border.all(
//                   color: onSurfaceColor.withAlpha(18),
//                   width: 1.1,
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppTheme.primaryNavy.withAlpha(30),
//                     blurRadius: 30,
//                     spreadRadius: -6,
//                     offset: const Offset(0, 14),
//                   ),
//                 ],
//               ),
//               padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: 42,
//                         height: 42,
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           gradient: const LinearGradient(
//                             colors: [
//                               AppTheme.primaryNavy,
//                               AppTheme.secondaryNavy,
//                             ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: AppTheme.primaryNavy.withAlpha(60),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.person_add_rounded,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           "Kişisel Sohbet Başlat",
//                           style: TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 17,
//                             letterSpacing: -0.2,
//                             color: onSurfaceColor,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 18),

//                   ConstrainedBox(
//                     constraints: BoxConstraints(
//                       maxHeight: MediaQuery.of(context).size.height * 0.4,
//                     ),
//                     child: ListView(
//                       shrinkWrap: true,
//                       physics: const BouncingScrollPhysics(),
//                       children: [
//                         TextField(
//                           controller: usernameController,
//                           autofocus: true,
//                           onChanged: performSearch,
//                           style: TextStyle(color: onSurfaceColor),
//                           decoration: _fieldDecoration(
//                             label: "Kullanıcı Adı veya İsim",
//                             hint: "Örn: kullanici123",
//                             icon: Icons.search_rounded,
//                             onSurfaceColor: onSurfaceColor,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         if (isSearching)
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 10),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(20),
//                               child: LinearProgressIndicator(
//                                 minHeight: 3,
//                                 backgroundColor: onSurfaceColor.withAlpha(20),
//                                 valueColor: const AlwaysStoppedAnimation<Color>(
//                                   AppTheme.primaryNavy,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         if (searchSuggestions.isNotEmpty)
//                           Container(
//                             margin: const EdgeInsets.only(top: 4),
//                             decoration: BoxDecoration(
//                               color: onSurfaceColor.withAlpha(8),
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(
//                                 color: onSurfaceColor.withAlpha(16),
//                               ),
//                             ),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: searchSuggestions.map((user) {
//                                 final uname = user["user_name"].toString();
//                                 final displayName = user["full_name"] ?? uname;
//                                 final letter = displayName.isNotEmpty
//                                     ? displayName[0].toUpperCase()
//                                     : "?";
//                                 return ListTile(
//                                   dense: true,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(14),
//                                   ),
//                                   leading: Container(
//                                     width: 36,
//                                     height: 36,
//                                     alignment: Alignment.center,
//                                     decoration: const BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       gradient: LinearGradient(
//                                         colors: [
//                                           AppTheme.primaryNavy,
//                                           AppTheme.secondaryNavy,
//                                         ],
//                                         begin: Alignment.topLeft,
//                                         end: Alignment.bottomRight,
//                                       ),
//                                     ),
//                                     child: Text(
//                                       letter,
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 13,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                   title: Text(
//                                     displayName,
//                                     style: TextStyle(
//                                       fontWeight: FontWeight.w700,
//                                       fontSize: 13.5,
//                                       color: onSurfaceColor,
//                                     ),
//                                   ),
//                                   subtitle: Text(
//                                     "@$uname",
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: onSurfaceColor.withAlpha(130),
//                                     ),
//                                   ),
//                                   trailing: const Icon(
//                                     Icons.arrow_forward_ios_rounded,
//                                     size: 13,
//                                     color: AppTheme.primaryNavy,
//                                   ),
//                                   onTap: () {
//                                     usernameController.text = uname;
//                                     setState(() => searchSuggestions = []);
//                                   },
//                                 );
//                               }).toList(),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 14),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () =>
//                             Navigator.of(context, rootNavigator: true).pop(),
//                         child: Text(
//                           "İptal",
//                           style: TextStyle(
//                             color: onSurfaceColor.withAlpha(150),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       Container(
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(14),
//                           gradient: const LinearGradient(
//                             colors: [
//                               AppTheme.primaryNavy,
//                               AppTheme.secondaryNavy,
//                             ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: AppTheme.primaryNavy.withAlpha(70),
//                               blurRadius: 12,
//                               offset: const Offset(0, 5),
//                             ),
//                           ],
//                         ),
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             foregroundColor: Colors.white,
//                             shadowColor: Colors.transparent,
//                             elevation: 0,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(14),
//                             ),
//                           ),
//                           onPressed: () {
//                             final input = usernameController.text.trim();
//                             if (input.isNotEmpty) {
//                               Navigator.of(context, rootNavigator: true).pop();
//                               widget.onCreateChat(input);
//                             }
//                           },
//                           child: const Text(
//                             "Başlat",
//                             style: TextStyle(fontWeight: FontWeight.w700),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Lafla/themes/tema1.dart';
import '../../services/api_client.dart';

class SingleChatDialog extends StatefulWidget {
  final ApiClient api;
  final String token;
  final int currentUserId;
  final Function(String username) onCreateChat;

  const SingleChatDialog({
    super.key,
    required this.api,
    required this.token,
    required this.currentUserId,
    required this.onCreateChat,
  });

  @override
  State<SingleChatDialog> createState() => _SingleChatDialogState();
}

class _SingleChatDialogState extends State<SingleChatDialog> {
  final TextEditingController usernameController = TextEditingController();
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
        query: query,
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
            Icon(Icons.person_add_rounded, color: AppTheme.darkpurple2),
            SizedBox(width: 8),
            Text(
              "Kişisel Sohbet Başlat",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
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
                  hintText: "Örn: kullanici123",
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
                    color: AppTheme.surfaceColor,
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
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("@${user["user_name"]}"),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppTheme.primaryNavy,
                        ),
                        onTap: () {
                          usernameController.text = user["user_name"];
                          setState(() => searchSuggestions = []);
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
              final input = usernameController.text.trim();
              if (input.isNotEmpty) {
                Navigator.of(context, rootNavigator: true).pop();
                widget.onCreateChat(input);
              }
            },
            child: const Text("Başlat"),
          ),
        ],
      ),
    );
  }
}
