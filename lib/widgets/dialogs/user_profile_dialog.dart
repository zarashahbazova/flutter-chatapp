import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../themes/tema1.dart';

class UserProfileDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserProfileDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    final String name = user["full_name"] ?? user["user_name"] ?? "Kullanıcı";

    final String username = user["user_name"] ?? "";

    final String? birthDate = user["birth_date"];

    final String? photoPath = user["profile_photo"] ?? user["display_photo"];

    final String firstLetter =
        name.isNotEmpty ? name[0].toUpperCase() : "?";

    final String? fullPhotoUrl =
        (photoPath != null && photoPath.isNotEmpty)
            ? "${ApiClient.baseUrl}${photoPath.startsWith('/') ? photoPath : '/$photoPath'}"
            : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurfaceColor,
        title: const Text(
          "Profil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
          child: Column(
            children: [
              // PROFİL FOTOĞRAFI
              Container(
                width: 120,
                height: 120,
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
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
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
                    : Text(
                        firstLetter,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // AD SOYAD
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceColor,
                ),
              ),

              const SizedBox(height: 6),

              // KULLANICI ADI
              Text(
                "@$username",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryNavy,
                ),
              ),

              const SizedBox(height: 32),

              // BİLGİLER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: onSurfaceColor.withAlpha(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kullanıcı Bilgileri",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
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
                            color: AppTheme.primaryNavy.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.cake_rounded,
                            color: AppTheme.primaryNavy,
                            size: 21,
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
                                  color: onSurfaceColor.withAlpha(130),
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
            ],
          ),
        ),
      ),
    );
  }
}