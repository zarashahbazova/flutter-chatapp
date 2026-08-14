import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Lafla/main.dart';
import 'package:Lafla/themes/tema1.dart';
import '../services/api_client.dart';
import 'edit_profile_page.dart';
import 'login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiClient api = ApiClient();
  final ImagePicker _picker = ImagePicker();

  String _currentName = "";
  String _currentUsername = "";
  String _currentEmail = "";
  String _currentPhone = "";
  String _currentBirthDate = "";
  String? _profilePhotoUrl;
  bool _isDarkMode = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _isDarkMode = themeNotifier.value == ThemeMode.dark;
    _loadProfile();
  }

  Future<void> _handleExpiredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!mounted) return;
    AppTheme.showSnackBar(
      context,
      message: "Oturum süreniz doldu. Lütfen tekrar giriş yapın.",
      isError: true,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        _logout();
        return;
      }

      final response = await api.profile(token);

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleExpiredToken();
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          final profile = data["data"];

          _currentName = profile["full_name"] ?? "";
          _currentUsername = profile["user_name"] ?? "";
          _currentEmail = profile["email"] ?? "";
          _currentPhone = profile["phone"] ?? "";
          _profilePhotoUrl = profile["profile_photo"];

          final birthDate = profile["birth_date"];

          if (birthDate != null && birthDate.toString().isNotEmpty) {
            DateTime parsedDate = DateFormat(
              "dd-MM-yyyy",
            ).parseStrict(birthDate);
            _currentBirthDate = DateFormat("dd-MM-yyyy").format(parsedDate);
          } else {
            _currentBirthDate = "";
          }
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    PermissionStatus status;

    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      status = await Permission.photos.request();
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
    }

    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Lütfen ayarlardan gerekli izni verin.",
        isError: true,
      );
      openAppSettings();
      return;
    }

    if (status.isGranted || status.isLimited) {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        await _uploadProfilePhoto(image.path);
      }
    } else {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Gerekli izin verilmedi.",
        isError: true,
      );
    }
  }

  Future<void> _uploadProfilePhoto(String filePath) async {
    setState(() => _isUploadingPhoto = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        _logout();
        return;
      }

      final response = await api.updateProfilePhoto(
        token: token,
        filePath: filePath,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profilePhotoUrl = data["data"]["photo_url"];
        });

        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message: "Profil fotoğrafı güncellendi.",
          isError: false,
        );
      } else {
        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message: "Fotoğraf yüklenemedi.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Bir hata oluştu: $e",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _updateProfile({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String birth_date,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        _logout();
        return;
      }

      final response = await api.updateProfile(
        token: token,
        body: {
          "full_name": name,
          "user_name": username,
          "email": email,
          "phone": phone,
          "birth_date": birth_date,
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleExpiredToken();
        return;
      }

      if (response.statusCode == 200) {
        await _loadProfile();

        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message: "Profil başarıyla güncellendi.",
          isError: false,
        );
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message: data["error"] ?? "Güncelleme başarısız.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Bir hata oluştu: $e",
        isError: true,
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        _logout();
        return;
      }

      final response = await api.deleteAccount(token);

      if (response.headers['content-type']?.contains('application/json') ??
          false) {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          await prefs.clear();

          if (!mounted) return;
          AppTheme.showSnackBar(
            context,
            message: "Hesabınız başarıyla silindi.",
            isError: false,
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        } else {
          if (!mounted) return;
          AppTheme.showSnackBar(
            context,
            message: data["error"] ?? "Hesap silinemedi.",
            isError: true,
          );
        }
      } else {
        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message:
              "Sunucu hatası (${response.statusCode}). Lütfen API yolunu kontrol edin.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Hesap silinirken hata oluştu: $e",
        isError: true,
      );
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          currentName: _currentName,
          currentUsername: _currentUsername,
          currentEmail: _currentEmail,
          currentPhone: _currentPhone,
          currentBirthDate: _currentBirthDate,
          currentPhotoUrl: _profilePhotoUrl,
          onSave: _updateProfile,
          onPickPhoto: _pickAndUploadImage,
        ),
      ),
    ).then((_) => _loadProfile());
  }

  void _confirmDeleteAccount() {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Hesabınızı Silmek İstiyor musunuz?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: onSurfaceColor,
            ),
          ),
          content: Text(
            "Tüm mesajlarınız ve kişisel verileriniz kalıcı olarak silinecektir.",
            style: TextStyle(color: onSurfaceColor.withAlpha(160)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "İptal",
                style: TextStyle(color: onSurfaceColor.withAlpha(180)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                elevation: 0,
                minimumSize: const Size(90, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              child: const Text(
                "Hesabımı Sil",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
            color: isDark ? const Color(0xFF8E8B94) : const Color(0xFF827E8C),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? const Color(0xFF8E8B94) : const Color(0xFF827E8C);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color.fromARGB(255, 87, 84, 92)
                  : const Color(0xFFF3F2F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: isDark ? Colors.white70 : const Color(0xFF2C2A31),
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
    final surfaceColor = isDark
        ? AppTheme.darkSurfaceColor
        : AppTheme.surfaceColor;
    final onSurfaceColor = theme.colorScheme.onSurface;

    final String firstLetter = _currentName.isNotEmpty
        ? _currentName[0].toUpperCase()
        : "?";

    final String? fullPhotoUrl =
        (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
        ? "${ApiClient.baseUrl}${_profilePhotoUrl!.startsWith('/') ? _profilePhotoUrl : '/$_profilePhotoUrl'}?v=${DateTime.now().millisecondsSinceEpoch}"
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Profil",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 📸 SADE VE ŞIK PROFİL FOTOĞRAFI (Fotoğraf üstünde buton yok)
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1D1C21) : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C2A31)
                        : const Color(0xFFE2E0E7),
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
                child: _isUploadingPhoto
                    ? const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black54,
                      )
                    : fullPhotoUrl != null
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
              _currentName.isNotEmpty ? _currentName : "Kullanıcı",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: onSurfaceColor,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 24),

            // 1. BÖLÜM: BİLGİ KARTI & PROFİLİ DÜZENLE
            // profile.dart -> 1. BÖLÜM: BİLGİ KARTI & PROFİLİ DÜZENLE
            _buildSectionHeader("Kullanıcı Bilgileri", isDark),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : const Color.fromARGB(255, 255, 255, 255),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.alternate_email_rounded,
                    label: "Kullanıcı Adı",
                    value: _currentUsername.isNotEmpty
                        ? "@$_currentUsername"
                        : "",
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
                    icon: Icons.phone_outlined,
                    label: "Telefon Numarası",
                    value: _currentPhone,
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
                    icon: Icons.mail_outline_rounded,
                    label: "E-Posta Adresi",
                    value: _currentEmail,
                    isDark: isDark,
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.7,
                    indent: 16,
                    endIndent: 16,
                    color: onSurfaceColor.withAlpha(isDark ? 16 : 10),
                  ),
                  // 🎂 DOĞUM TARİHİ ALANI
                  _buildInfoRow(
                    icon: Icons.cake_outlined,
                    label: "Doğum Tarihi",
                    value: _currentBirthDate,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 8),

                  // PROFİLİ DÜZENLE (TextButton)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF19181B),
                        ),
                        label: Text(
                          "Profili Düzenle",
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF19181B),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withAlpha(8)
                              : Colors.black.withAlpha(5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _navigateToEditProfile,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. BÖLÜM: TEMA VE TERCİHLER KARTI (Ayarlar içeriği)
            _buildSectionHeader("Tercihler", isDark),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : const Color.fromARGB(255, 255, 255, 255),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                value: _isDarkMode,
                activeThumbColor: isDark ? Colors.white : Colors.black,
                activeTrackColor: isDark
                    ? const Color(0xFF3F3D45)
                    : const Color(0xFFCCCCCC),
                secondary: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141316)
                        : const Color(0xFFF3F2F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: 19,
                    color: isDark ? Colors.white70 : const Color(0xFF2C2A31),
                  ),
                ),
                title: Text(
                  "Koyu Tema",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: onSurfaceColor,
                  ),
                ),
                onChanged: (value) async {
                  setState(() => _isDarkMode = value);
                  themeNotifier.value = value
                      ? ThemeMode.dark
                      : ThemeMode.light;

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("isDarkMode", value);
                },
              ),
            ),

            const SizedBox(height: 20),

            // 3. BÖLÜM: HESAP İŞLEMLERİ (Çıkış & Silme Kartı)
            _buildSectionHeader("Hesap", isDark),
            Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? const Color.fromARGB(255, 0, 0, 0)
                      : const Color.fromARGB(255, 255, 255, 255),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 50 : 6),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF141316)
                            : const Color(0xFFF3F2F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        size: 19,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF2C2A31),
                      ),
                    ),
                    title: Text(
                      "Çıkış Yap",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: onSurfaceColor.withAlpha(100),
                    ),
                    onTap: _logout,
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.7,
                    indent: 16,
                    endIndent: 16,
                    color: onSurfaceColor.withAlpha(isDark ? 16 : 10),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withAlpha(isDark ? 25 : 15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    title: const Text(
                      "Hesabı Sil",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppTheme.errorColor.withAlpha(140),
                    ),
                    onTap: _confirmDeleteAccount,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}
