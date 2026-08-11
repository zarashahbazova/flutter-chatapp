import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../themes/tema1.dart';

class UserProfileDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserProfileDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    final String name = user["full_name"] ?? user["user_name"] ?? "Kullanıcı";
    final String username = user["user_name"] ?? "";
    final String? birthDate = user["birth_date"];
    final String? photoPath = user["profile_photo"] ?? user["display_photo"];

    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    final String? fullPhotoUrl = (photoPath != null && photoPath.isNotEmpty)
        ? "${ApiClient.baseUrl}${photoPath.startsWith('/') ? photoPath : '/$photoPath'}"
        : null;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: surfaceColor.withAlpha(235),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: onSurfaceColor.withAlpha(20),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // AVATAR / PROFİL FOTOĞRAFI
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: fullPhotoUrl == null
                    ? const LinearGradient(
                        colors: [AppTheme.primaryNavy, AppTheme.secondaryNavy],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withAlpha(40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: fullPhotoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        fullPhotoUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          firstLetter,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // AD SOYAD
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: onSurfaceColor,
              ),
            ),
            const SizedBox(height: 4),

            // KULLANICI ADI
            Text(
              "@$username",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryNavy,
              ),
            ),

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // DOĞUM GÜNÜ BİLGİSİ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.cake_rounded,
                    color: AppTheme.primaryNavy,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Doğum Tarihi",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: onSurfaceColor.withAlpha(140),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (birthDate != null && birthDate.isNotEmpty)
                            ? birthDate
                            : "Belirtilmemiş",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onSurfaceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // KAPAT BUTONU
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Kapat"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}