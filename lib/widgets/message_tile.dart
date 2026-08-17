import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Lafla/services/api_client.dart';
import 'package:Lafla/themes/tema1.dart';

class MessageTile extends StatelessWidget {
  static const double avatarSize =
      56.0; // Fotoğrafın genişlik ve yüksekliği (Kare)
  static const double avatarRadius = 13.0; // Fotoğrafın köşe yuvarlaklığı
  static const double cardRadius = 17.0; // Mesaj kutusunun köşe yuvarlaklığı
  static const double cardVerticalMargin =
      3.0; // Kutuların alt alta olan dikey mesafesi
  static const double cardHorizontalMargin =
      16.0; // Kutunun ekran kenarlarına mesafesi
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(
    8,
    8,
    16,
    8,
  ); // Kutu içi dolgu (Sol, Üst, Sağ, Alt)
  static const double avatarTextSpacing =
      16.0; // Fotoğraf ile yazı arasındaki boşluk

  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const MessageTile({
    super.key,
    required this.user,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final int unread = user["unread"] ?? 0;
    final bool isGroup = user["is_group"] == true;
    final String name = user["name"] ?? "";
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final String? photoPath = user["display_photo"] ?? user["profile_photo"];

    final String? fullPhotoUrl = (photoPath != null && photoPath.isNotEmpty)
        ? "${ApiClient.baseUrl}${photoPath.startsWith('/') ? photoPath : '/$photoPath'}"
        : null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBgColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: cardHorizontalMargin,
        vertical: cardVerticalMargin,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: unread > 0
                  ? cardBgColor.withAlpha(isDark ? 190 : 245)
                  : cardBgColor.withAlpha(isDark ? 110 : 225),
              borderRadius: BorderRadius.circular(cardRadius),
              border: Border.all(
                color: unread > 0
                    ? primaryColor.withAlpha(70)
                    : onSurfaceColor.withAlpha(isDark ? 16 : 10),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : primaryColor).withAlpha(
                    isDark ? 85 : 12,
                  ),
                  blurRadius: 20,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // İnce cam parlaklığı efekti
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withAlpha(isDark ? 10 : 90),
                            Colors.white.withAlpha(0),
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),
                ),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: primaryColor.withAlpha(16),
                    highlightColor: primaryColor.withAlpha(6),
                    onTap: onTap,
                    onLongPress: onLongPress,
                    child: Padding(
                      padding: cardPadding,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Okunmamış mesaj sinyal çizgisi
                          if (unread > 0)
                            Container(
                              width: 3.5,
                              height: avatarSize * 0.7,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    primaryColor,
                                    AppTheme.secondaryNavy,
                                  ],
                                ),
                              ),
                            ),

                          // Fotoğraf / Avatar Alanı (Profil rozeti kaldırıldı)
                          _Avatar(
                            photoUrl: fullPhotoUrl,
                            firstLetter: firstLetter,
                            highlighted: unread > 0,
                            size: avatarSize,
                            radius: avatarRadius,
                          ),

                          const SizedBox(width: avatarTextSpacing),

                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          if (isGroup) ...[
                                            Icon(
                                              Icons.groups_rounded,
                                              size: 16,
                                              color: AppTheme.secondaryNavy,
                                            ),
                                            const SizedBox(width: 5),
                                          ],
                                          Expanded(
                                            child: Text(
                                              name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16,
                                                letterSpacing: -0.2,
                                                fontWeight: unread > 0
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: onSurfaceColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        user["message"] ?? "",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: unread > 0
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          color: unread > 0
                                              ? onSurfaceColor.withAlpha(215)
                                              : onSurfaceColor.withAlpha(130),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // SAAT + OKUNMAMIŞ ROZET
                                SizedBox(
                                  width: 38,
                                  height: avatarSize,
                                  child: Stack(
                                    children: [
                                      // SAAT — her zaman üstte
                                      Positioned(
                                        top: 2,
                                        right: 0,
                                        child: Text(
                                          user["time"] ?? "",
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: unread > 0
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: unread > 0
                                                ? primaryColor
                                                : onSurfaceColor.withAlpha(105),
                                          ),
                                        ),
                                      ),

                                      // ROZET — saatten bağımsız, dikey ortada
                                      if (unread > 0)
                                        Positioned(
                                          right: 0,
                                          top: (avatarSize - 20) / 2,
                                          child: _UnreadBadge(
                                            count: unread,
                                            color: primaryColor,
                                          ),
                                        ),
                                    ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String firstLetter;
  final bool highlighted;
  final double size;
  final double radius;

  const _Avatar({
    required this.photoUrl,
    required this.firstLetter,
    required this.highlighted,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(highlighted ? 2.5 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: highlighted
              ? const LinearGradient(
                  colors: [AppTheme.primaryNavy, AppTheme.secondaryNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              highlighted ? radius - 2 : radius,
            ),
            gradient: photoUrl == null
                ? const LinearGradient(
                    colors: [AppTheme.primaryNavy, AppTheme.secondaryNavy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryNavy.withAlpha(30),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: photoUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(
                    highlighted ? radius - 2 : radius,
                  ),
                  child: Image.network(
                    photoUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Text(
                      firstLetter,
                      style: TextStyle(
                        fontSize: size * 0.38,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Text(
                  firstLetter,
                  style: TextStyle(
                    fontSize: size * 0.38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _UnreadBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      height: 20,
      constraints: const BoxConstraints(minWidth: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, AppTheme.secondaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(90),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count > 99 ? "99+" : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
