import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../themes/tema1.dart';

class UserProfileDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserProfileDialog({super.key, required this.user});

  Widget _buildSectionHeader(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppTheme.getSectionHeaderColor(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final subColor = AppTheme.getSectionHeaderColor(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.getIconBg(isDark),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: AppTheme.getIconFg(isDark),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : "Belirtilmemiş",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = AppTheme.getSurfaceColor(isDark);
    final onSurfaceColor = theme.colorScheme.onSurface;

    final String name = user["full_name"] ?? user["user_name"] ?? "Kullanıcı";
    final String username = user["user_name"] ?? "";
    final String? birthDate = user["birth_date"];
    final String? photoPath = user["profile_photo"] ?? user["display_photo"];

    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    final String? fullPhotoUrl = (photoPath != null && photoPath.isNotEmpty)
        ? "${ApiClient.baseUrl}${photoPath.startsWith('/') ? photoPath : '/$photoPath'}"
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Kullanıcı Profili"),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // PROFİL FOTOĞRAFI (ProfilePage ile birebir aynı)
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor,
                  border: Border.all(
                    color: AppTheme.getAvatarBorder(isDark),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 80 : 10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: fullPhotoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          fullPhotoUrl,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            firstLetter,
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        firstLetter,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: onSurfaceColor,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // İSİM
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: onSurfaceColor,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 24),

            // KULLANICI BİLGİLERİ KARTI
            _buildSectionHeader("Kullanıcı Bilgileri", isDark),
            Container(
              decoration: AppTheme.profileCardDecoration(isDark),
              child: Column(
                children: [
                  _buildInfoRow(
                    context: context,
                    icon: Icons.alternate_email_rounded,
                    label: "Kullanıcı Adı",
                    value: username.isNotEmpty ? "@$username" : "",
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.7,
                    indent: 16,
                    endIndent: 16,
                    color: onSurfaceColor.withAlpha(isDark ? 16 : 10),
                  ),
                  _buildInfoRow(
                    context: context,
                    icon: Icons.cake_outlined,
                    label: "Doğum Tarihi",
                    value: (birthDate != null && birthDate.isNotEmpty)
                        ? birthDate
                        : "Belirtilmemiş",
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}