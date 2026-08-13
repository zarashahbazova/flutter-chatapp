import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stajapp/main.dart';
import 'package:stajapp/themes/tema1.dart';
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

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryNavy.withAlpha(15),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  title: const Text(
                    "Kamera ile Çek",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryNavy.withAlpha(15),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppTheme.primaryNavy,
                    ),
                  ),
                  title: const Text(
                    "Galeriden Seç",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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

      // Yanıtın JSON olup olmadığını kontrol ediyoruz
      if (response.headers['content-type']?.contains('application/json') ?? false) {
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
        // Backend HTML hatası veya 404 döndürdüyse
        if (!mounted) return;
        AppTheme.showSnackBar(
          context,
          message: "Sunucu hatası (${response.statusCode}). Lütfen API yolunu kontrol edin.",
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
          onSave: _updateProfile,
        ),
      ),
    );
  }

  // ⚙️ AYARLAR EKRANI DİYALOĞU / EKRANI (ANLIK TEMA DEĞİŞİMLİ)
  void _openSettingsPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Arka planı transparent yapıp içeride dinamik temalıyoruz
      builder: (modalContext) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            // Anlık değişen tema rengini doğrudan alıyoruz
            final isDark = currentMode == ThemeMode.dark;
            final surfaceColor = isDark
                ? AppTheme.darkSurfaceColor
                : AppTheme.surfaceColor;
            final onSurfaceColor = isDark
                ? AppTheme.darkTextColor
                : AppTheme.textColor;

            return Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: onSurfaceColor.withAlpha(50),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      "Ayarlar",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. KOYU TEMA SWITCH (ANINDA RENGİ DEĞİŞİR)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkBackgroundColor
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SwitchListTile(
                        value: _isDarkMode,
                        activeThumbColor: isDark
                            ? AppTheme.darkAccentBlue
                            : AppTheme.primaryNavy,
                        secondary: Icon(
                          _isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: isDark
                              ? AppTheme.darkAccentBlue
                              : AppTheme.primaryNavy,
                        ),
                        title: Text(
                          "Koyu Tema",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: onSurfaceColor,
                          ),
                        ),
                        onChanged: (value) async {
                          setState(() => _isDarkMode = value);

                          // Global tema notifier'ı tetikliyoruz (ValueListenableBuilder anında rebuild eder)
                          themeNotifier.value =
                              value ? ThemeMode.dark : ThemeMode.light;

                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool("isDarkMode", value);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2. ÇIKIŞ YAP
                    ListTile(
                      leading: Icon(
                        Icons.logout_rounded,
                        color: isDark
                            ? AppTheme.darkAccentBlue
                            : AppTheme.primaryNavy,
                      ),
                      title: Text(
                        "Çıkış Yap",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: onSurfaceColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(modalContext);
                        _logout();
                      },
                    ),

                    Divider(color: onSurfaceColor.withAlpha(30)),

                    // 3. HESABI SİL
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever_rounded,
                        color: AppTheme.errorColor,
                      ),
                      title: const Text(
                        "Hesabı Sil",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      subtitle: Text(
                        "Bu işlem geri alınamaz.",
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurfaceColor.withAlpha(130),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(modalContext);
                        _confirmDeleteAccount();
                      },
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Hesabınızı Silmek İstiyor musunuz?",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: const Text(
            "Tüm mesajlarınız ve kişisel verileriniz kalıcı olarak silinecektir.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
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
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String firstLetter = _currentName.isNotEmpty
        ? _currentName[0].toUpperCase()
        : "?";

    final String? fullPhotoUrl =
        (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty)
        ? "${ApiClient.baseUrl}${_profilePhotoUrl!.startsWith('/') ? _profilePhotoUrl : '/$_profilePhotoUrl'}?v=${DateTime.now().millisecondsSinceEpoch}"
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        // SOL ÜST - AYARLAR BUTONU
        leading: IconButton(
          icon: const Icon(Icons.settings, size: 26),
          onPressed: _openSettingsPage,
        ),
        title: Text(
          "Profil",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        // SAĞ ÜST - DÜZENLEME BUTONU
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 28),
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 90),

            // Profil Avatarı
            Center(
              child: SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
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
                            color: AppTheme.primaryNavy.withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isUploadingPhoto
                          ? const CircularProgressIndicator(color: Colors.white)
                          : fullPhotoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                fullPhotoUrl,
                                width: 170,
                                height: 170,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              firstLetter,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: InkWell(
                        onTap: _showImagePickerSheet,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add_a_photo_rounded,
                            size: 19,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              _currentName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "@$_currentUsername",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
