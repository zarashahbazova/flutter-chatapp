// import 'dart:convert';
// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:Lafla/themes/tema1.dart';
// import '../../services/api_client.dart';

// class GroupChatDialog extends StatefulWidget {
//   final ApiClient api;
//   final String token;
//   final int currentUserId;
//   final Function(String groupName, List<String> usernames) onCreateGroup;

//   const GroupChatDialog({
//     super.key,
//     required this.api,
//     required this.token,
//     required this.currentUserId,
//     required this.onCreateGroup,
//   });

//   @override
//   State<GroupChatDialog> createState() => _GroupChatDialogState();
// }

// class _GroupChatDialogState extends State<GroupChatDialog> {
//   final TextEditingController groupNameController = TextEditingController();
//   final TextEditingController searchController = TextEditingController();

//   List<String> selectedUsernames = [];
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
//         query: query.trim(),
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

//   void addUserToList(String username) {
//     final cleanName = username.trim().replaceAll('@', '');
//     if (cleanName.isNotEmpty && !selectedUsernames.contains(cleanName)) {
//       setState(() {
//         selectedUsernames.add(cleanName);
//         searchController.clear();
//         searchSuggestions = [];
//       });
//     }
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
//             child: SizedBox(
//               width: MediaQuery.of(context).size.width - 40,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: surfaceColor.withAlpha(isDark ? 215 : 240),
//                   borderRadius: BorderRadius.circular(26),
//                   border: Border.all(
//                     color: onSurfaceColor.withAlpha(18),
//                     width: 1.1,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppTheme.primaryNavy.withAlpha(30),
//                       blurRadius: 30,
//                       spreadRadius: -6,
//                       offset: const Offset(0, 14),
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           width: 42,
//                           height: 42,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: const LinearGradient(
//                               colors: [
//                                 AppTheme.primaryNavy,
//                                 AppTheme.secondaryNavy,
//                               ],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: AppTheme.primaryNavy.withAlpha(60),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: const Icon(
//                             Icons.groups_rounded,
//                             color: Colors.white,
//                             size: 21,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             "Yeni Grup Oluştur",
//                             style: TextStyle(
//                               fontWeight: FontWeight.w800,
//                               fontSize: 17,
//                               letterSpacing: -0.2,
//                               color: onSurfaceColor,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 18),

//                     ConstrainedBox(
//                       constraints: BoxConstraints(
//                         maxHeight: MediaQuery.of(context).size.height * 0.48,
//                       ),
//                       child: ListView(
//                         shrinkWrap: true,
//                         physics: const BouncingScrollPhysics(),
//                         children: [
//                           TextField(
//                             controller: groupNameController,
//                             style: TextStyle(color: onSurfaceColor),
//                             decoration: _fieldDecoration(
//                               label: "Grup Adı",
//                               hint: "Örn: Proje Grubu",
//                               icon: Icons.group_work_rounded,
//                               onSurfaceColor: onSurfaceColor,
//                             ),
//                           ),
//                           const SizedBox(height: 14),

//                           if (selectedUsernames.isNotEmpty) ...[
//                             Text(
//                               "Eklenecek Katılımcılar",
//                               style: TextStyle(
//                                 fontSize: 11.5,
//                                 fontWeight: FontWeight.w700,
//                                 letterSpacing: 0.2,
//                                 color: onSurfaceColor.withAlpha(140),
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Wrap(
//                               spacing: 7,
//                               runSpacing: 7,
//                               children: selectedUsernames.map((username) {
//                                 return Container(
//                                   padding: const EdgeInsets.only(
//                                     left: 4,
//                                     right: 10,
//                                     top: 4,
//                                     bottom: 4,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: AppTheme.primaryNavy.withAlpha(18),
//                                     borderRadius: BorderRadius.circular(20),
//                                     border: Border.all(
//                                       color: AppTheme.primaryNavy.withAlpha(40),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Container(
//                                         width: 22,
//                                         height: 22,
//                                         alignment: Alignment.center,
//                                         decoration: const BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           gradient: LinearGradient(
//                                             colors: [
//                                               AppTheme.primaryNavy,
//                                               AppTheme.secondaryNavy,
//                                             ],
//                                           ),
//                                         ),
//                                         child: Text(
//                                           username[0].toUpperCase(),
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 10,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 7),
//                                       Text(
//                                         "@$username",
//                                         style: const TextStyle(
//                                           fontSize: 12.5,
//                                           fontWeight: FontWeight.w700,
//                                           color: AppTheme.primaryNavy,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 4),
//                                       GestureDetector(
//                                         onTap: () {
//                                           setState(() {
//                                             selectedUsernames.remove(username);
//                                           });
//                                         },
//                                         child: Icon(
//                                           Icons.cancel_rounded,
//                                           size: 16,
//                                           color: AppTheme.primaryNavy.withAlpha(
//                                             160,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                             const SizedBox(height: 14),
//                           ],

//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: TextField(
//                                   controller: searchController,
//                                   onChanged: performSearch,
//                                   onSubmitted: (value) => addUserToList(value),
//                                   style: TextStyle(color: onSurfaceColor),
//                                   decoration: _fieldDecoration(
//                                     label: "Katılımcı Ara / Yaz",
//                                     hint: "Örn: kullanici123",
//                                     icon: Icons.person_add_alt_1_rounded,
//                                     onSurfaceColor: onSurfaceColor,
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Container(
//                                 height: 52,
//                                 width: 52,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(14),
//                                   gradient: const LinearGradient(
//                                     colors: [
//                                       AppTheme.primaryNavy,
//                                       AppTheme.secondaryNavy,
//                                     ],
//                                     begin: Alignment.topLeft,
//                                     end: Alignment.bottomRight,
//                                   ),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: AppTheme.primaryNavy.withAlpha(60),
//                                       blurRadius: 10,
//                                       offset: const Offset(0, 4),
//                                     ),
//                                   ],
//                                 ),
//                                 child: IconButton(
//                                   onPressed: () =>
//                                       addUserToList(searchController.text),
//                                   icon: const Icon(
//                                     Icons.add_rounded,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),

//                           if (isSearching)
//                             Padding(
//                               padding: const EdgeInsets.symmetric(vertical: 10),
//                               child: ClipRRect(
//                                 borderRadius: BorderRadius.circular(20),
//                                 child: LinearProgressIndicator(
//                                   minHeight: 3,
//                                   backgroundColor: onSurfaceColor.withAlpha(20),
//                                   valueColor:
//                                       const AlwaysStoppedAnimation<Color>(
//                                         AppTheme.primaryNavy,
//                                       ),
//                                 ),
//                               ),
//                             ),

//                           if (searchSuggestions.isNotEmpty) ...[
//                             const SizedBox(height: 8),
//                             Container(
//                               decoration: BoxDecoration(
//                                 color: onSurfaceColor.withAlpha(8),
//                                 borderRadius: BorderRadius.circular(16),
//                                 border: Border.all(
//                                   color: onSurfaceColor.withAlpha(16),
//                                 ),
//                               ),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: searchSuggestions.map((user) {
//                                   final username = user["user_name"].toString();
//                                   final bool isAdded = selectedUsernames
//                                       .contains(username);
//                                   final displayName =
//                                       user["full_name"] ?? username;
//                                   final letter = displayName.isNotEmpty
//                                       ? displayName[0].toUpperCase()
//                                       : "?";

//                                   return ListTile(
//                                     dense: true,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(14),
//                                     ),
//                                     leading: Container(
//                                       width: 36,
//                                       height: 36,
//                                       alignment: Alignment.center,
//                                       decoration: const BoxDecoration(
//                                         shape: BoxShape.circle,
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             AppTheme.primaryNavy,
//                                             AppTheme.secondaryNavy,
//                                           ],
//                                           begin: Alignment.topLeft,
//                                           end: Alignment.bottomRight,
//                                         ),
//                                       ),
//                                       child: Text(
//                                         letter,
//                                         style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 13,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                     title: Text(
//                                       displayName,
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.w700,
//                                         fontSize: 13.5,
//                                         color: onSurfaceColor,
//                                       ),
//                                     ),
//                                     subtitle: Text(
//                                       "@$username",
//                                       style: TextStyle(
//                                         fontSize: 12,
//                                         color: onSurfaceColor.withAlpha(130),
//                                       ),
//                                     ),
//                                     trailing: Icon(
//                                       isAdded
//                                           ? Icons.check_circle_rounded
//                                           : Icons.add_circle_outline_rounded,
//                                       color: isAdded
//                                           ? AppTheme.successColor
//                                           : AppTheme.primaryNavy,
//                                     ),
//                                     onTap: () => addUserToList(username),
//                                   );
//                                 }).toList(),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 14),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         TextButton(
//                           onPressed: () =>
//                               Navigator.of(context, rootNavigator: true).pop(),
//                           child: Text(
//                             "İptal",
//                             style: TextStyle(
//                               color: onSurfaceColor.withAlpha(150),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 6),
//                         Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(14),
//                             gradient: const LinearGradient(
//                               colors: [
//                                 AppTheme.primaryNavy,
//                                 AppTheme.secondaryNavy,
//                               ],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: AppTheme.primaryNavy.withAlpha(70),
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 5),
//                               ),
//                             ],
//                           ),
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.transparent,
//                               foregroundColor: Colors.white,
//                               shadowColor: Colors.transparent,
//                               elevation: 0,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(14),
//                               ),
//                             ),
//                             onPressed: () {
//                               final name = groupNameController.text.trim();
//                               if (name.isEmpty) {
//                                 AppTheme.showSnackBar(
//                                   context,
//                                   message: "Lütfen grup adını girin.",
//                                   isError: true,
//                                 );
//                                 return;
//                               }
//                               if (selectedUsernames.isEmpty) {
//                                 AppTheme.showSnackBar(
//                                   context,
//                                   message: "En az 1 katılımcı eklemelisiniz.",
//                                   isError: true,
//                                 );
//                                 return;
//                               }

//                               Navigator.of(context, rootNavigator: true).pop();
//                               widget.onCreateGroup(name, selectedUsernames);
//                             },
//                             child: Text(
//                               "Oluştur (${selectedUsernames.length})",
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
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
      setState(() => searchSuggestions = []);
      return;
    }

    setState(() => isSearching = true);

    try {
      final response = await widget.api.searchUsers(
        token: widget.token,
        query: query.trim(),
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
            Icon(Icons.groups_rounded, color: AppTheme.primaryNavy),
            SizedBox(width: 8),
            Text(
              "Yeni Grup Oluştur",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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

              if (selectedUsernames.isNotEmpty) ...[
                const Text(
                  "Eklenecek Katılımcılar:",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: selectedUsernames.map((username) {
                    return Chip(
                      backgroundColor: AppTheme.primaryNavy.withOpacity(0.1),
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
                      label: Text(
                        "@$username",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                        ),
                      ),
                      deleteIcon: const Icon(
                        Icons.cancel_rounded,
                        size: 16,
                        color: AppTheme.primaryNavy,
                      ),
                      onDeleted: () {
                        setState(() {
                          selectedUsernames.remove(username);
                        });
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
                      onSubmitted: (value) => addUserToList(value),
                      decoration: InputDecoration(
                        labelText: "Katılımcı Ara / Yaz",
                        hintText: "Örn: kullanici123",
                        prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryNavy,
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

              if (searchSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: searchSuggestions.map((user) {
                      final username = user["user_name"].toString();
                      final bool isAdded = selectedUsernames.contains(username);

                      return ListTile(
                        dense: true,
                        title: Text(
                          user["full_name"] ?? username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("@$username"),
                        trailing: Icon(
                          isAdded
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          color: isAdded ? Colors.green : AppTheme.primaryNavy,
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
            child: Text("Oluştur (${selectedUsernames.length})"),
          ),
        ],
      ),
    );
  }
}
