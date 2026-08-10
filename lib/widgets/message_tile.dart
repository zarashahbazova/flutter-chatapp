import 'package:flutter/material.dart';
import 'package:stajapp/services/api_client.dart';
import 'package:stajapp/themes/tema1.dart';

class MessageTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;

  const MessageTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int unread = user["unread"] ?? 0;
    final String name = user["name"] ?? "";
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final String? photoPath = user["display_photo"] ?? user["profile_photo"];

    final String? fullPhotoUrl = (photoPath != null && photoPath.isNotEmpty)
        ? "${ApiClient.baseUrl}${photoPath.startsWith('/') ? photoPath : '/$photoPath'}"
        : null;

    final cardBgColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: unread > 0 ? cardBgColor : cardBgColor.withAlpha(210),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unread > 0
                ? primaryColor.withAlpha(50)
                : cardBgColor.withAlpha(100),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: primaryColor.withAlpha(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // --- AVATAR VEYA PROFİL FOTOĞRAFI ---
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: fullPhotoUrl == null
                          ? const LinearGradient(
                              colors: [
                                AppTheme.primaryNavy,
                                AppTheme.secondaryNavy,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNavy.withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: fullPhotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              fullPhotoUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                firstLetter,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Text(
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
                                  color: onSurfaceColor,
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
                                    ? primaryColor
                                    : onSurfaceColor.withAlpha(120),
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
                                      ? onSurfaceColor
                                      : onSurfaceColor.withAlpha(150),
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
                                  color: primaryColor,
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






//liste göürnümü

// import 'package:flutter/material.dart';
// import 'package:stajapp/themes/tema1.dart';

// class MessageTile extends StatelessWidget {
//   final Map<String, dynamic> user;
//   final VoidCallback onTap;

//   const MessageTile({
//     super.key,
//     required this.user,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final int unread = user["unread"] ?? 0;
//     final String name = user["name"] ?? "";
//     final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

//     // Tema dinamik renkleri
//     final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
//     final primaryColor = Theme.of(context).colorScheme.primary;

//     return Material(
//       color: unread > 0 ? primaryColor.withAlpha(15) : Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         splashColor: primaryColor.withAlpha(30),
//         highlightColor: primaryColor.withAlpha(10),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//               child: Row(
//                 children: [
//                   // --- AVATAR KISMI ---
//                   Container(
//                     width: 52,
//                     height: 52,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       gradient: const LinearGradient(
//                         colors: [
//                           AppTheme.primaryNavy,
//                           AppTheme.secondaryNavy,
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: AppTheme.primaryNavy.withAlpha(40),
//                           blurRadius: 8,
//                           offset: const Offset(0, 3),
//                         ),
//                       ],
//                     ),
//                     alignment: Alignment.center,
//                     child: Text(
//                       firstLetter,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 14),

//                   // --- METİN VE BİLDİRİM KISMI ---
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 name,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: unread > 0
//                                       ? FontWeight.w700
//                                       : FontWeight.w600,
//                                   color: onSurfaceColor,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               user["time"] ?? "",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: unread > 0
//                                     ? FontWeight.w600
//                                     : FontWeight.w400,
//                                 color: unread > 0
//                                     ? primaryColor
//                                     : onSurfaceColor.withAlpha(120),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Text(
//                                 user["message"] ?? "",
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: unread > 0
//                                       ? FontWeight.w500
//                                       : FontWeight.w400,
//                                   color: unread > 0
//                                       ? onSurfaceColor
//                                       : onSurfaceColor.withAlpha(150),
//                                 ),
//                               ),
//                             ),
//                             if (unread > 0) ...[
//                               const SizedBox(width: 8),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 7,
//                                 ),
//                                 height: 20,
//                                 constraints: const BoxConstraints(minWidth: 20),
//                                 alignment: Alignment.center,
//                                 decoration: BoxDecoration(
//                                   color: primaryColor,
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: Text(
//                                   unread > 99 ? "99+" : unread.toString(),
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 11,
//                                     fontWeight: FontWeight.w700,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // --- KENARLARDAN BOŞLUKLU İNCE ÇİZGİ ---
//             Divider(
//               height: 1,
//               thickness: 0.6,
//               indent: 86, // Soldan avatar hizasına kadar boşluk bırakır
//               endIndent: 20, // Sağdan 20px boşluk bırakır (tam genişlemez)
//               color: onSurfaceColor.withAlpha(25), // Çok hafif şeffaf çizgi
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }