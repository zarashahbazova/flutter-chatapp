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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String name = user["full_name"] ?? user["user_name"] ?? "Kullanıcı";
    final String username = user["user_name"] ?? "";
    final String? birthDate = user["birth_date"];
    final String? photoPath = user["profile_photo"] ?? user["display_photo"];

    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    final String? fullPhotoUrl = (photoPath != null && photoPath.isNotEmpty)
        ? "${ApiClient.baseUrl}${photoPath.startsWith('/') ? photoPath : '/$photoPath'}"
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurfaceColor,
        title: const Text("Profil", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Üstte yumuşak, marka renkli bir aydınlatma
            Positioned(
              top: -80,
              left: -60,
              right: -60,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryNavy.withAlpha(isDark ? 40 : 55),
                      AppTheme.primaryNavy.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 90, 20, 40),
              child: Column(
                children: [
                  // PROFİL FOTOĞRAFI
                  Container(
                    width: 128,
                    height: 128,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryNavy, AppTheme.secondaryNavy],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryNavy.withAlpha(45),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceColor,
                      ),
                      alignment: Alignment.center,
                      child: fullPhotoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                fullPhotoUrl,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryNavy,
                                          AppTheme.secondaryNavy,
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      firstLetter,
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 120,
                              height: 120,
                              alignment: Alignment.center,
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
                              child: Text(
                                firstLetter,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // AD SOYAD
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: onSurfaceColor,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // KULLANICI ADI
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy.withAlpha(18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "@$username",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryNavy,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // BİLGİLER
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: surfaceColor.withAlpha(isDark ? 170 : 210),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: onSurfaceColor.withAlpha(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? Colors.black : AppTheme.primaryNavy)
                                  .withAlpha(isDark ? 60 : 12),
                              blurRadius: 20,
                              spreadRadius: -6,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Kullanıcı Bilgileri",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: onSurfaceColor.withAlpha(150),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // DOĞUM TARİHİ
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryNavy.withAlpha(200),
                                        AppTheme.secondaryNavy.withAlpha(200),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(
                                    Icons.cake_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Doğum Tarihi",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: onSurfaceColor.withAlpha(
                                            130,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        (birthDate != null &&
                                                birthDate.isNotEmpty)
                                            ? birthDate
                                            : "Belirtilmemiş",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: onSurfaceColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}