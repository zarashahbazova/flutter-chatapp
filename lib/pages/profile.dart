import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stajapp/main.dart';
import 'package:stajapp/themes/tema1.dart';
import 'login.dart';
import '../services/api_client.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll('-', '');

    if (text.length > 8) {
      text = text.substring(0, 8);
    }

    String formatted = "";

    for (int i = 0; i < text.length; i++) {
      formatted += text[i];

      if ((i == 1 || i == 3) && i != text.length - 1) {
        formatted += "-";
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiClient api = ApiClient();

  String _currentName = "";
  String _currentUsername = "";
  String _currentEmail = "";
  String _currentPhone = "";
  String _currentBirthDate = "";
  bool _isDarkMode = false; // Tema kontrol değişkeni

  @override
  void initState() {
    super.initState();
    _isDarkMode = themeNotifier.value == ThemeMode.dark;
    _loadProfile();
  }

  // Token Süresi Dolduğunda Çıkış
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
    print("LOAD PROFILE CALISTI");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      print("TOKEN: $token");
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
        print("PROFILE STATUS: ${response.statusCode}");
        print("PROFILE BODY: ${response.body}");
        setState(() {
          final profile = data["data"];

          _currentName = profile["full_name"] ?? "";
          _currentUsername = profile["user_name"] ?? "";
          _currentEmail = profile["email"] ?? "";
          _currentPhone = profile["phone"] ?? "";

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

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

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

  // Çıkış Yap
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

  // bottom sheet
  void _showEditBottomSheet() {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: _currentName);
    final usernameController = TextEditingController(text: _currentUsername);
    final emailController = TextEditingController(text: _currentEmail);
    final phoneController = TextEditingController(text: _currentPhone);
    final birth_dateController = TextEditingController(text: _currentBirthDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Profili Düzenle",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Ad Soyad",
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Adınızı giriniz."
                        : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: "Kullanıcı Adı",
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Kullanıcı adınızı giriniz.";
                      }
                      if (v.length < 3 || v.length > 20) {
                        return "3-20 karakter olmalıdır.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "E-posta",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "E-posta giriniz.";
                      }
                      final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!regex.hasMatch(v.trim())) {
                        return "Geçerli bir e-posta giriniz.";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Telefon",
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }

                      if (!RegExp(r'^\d{11}$').hasMatch(v.trim())) {
                        return "Telefon numarası 11 haneli olmalıdır.";
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: birth_dateController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      DateInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Doğum Tarihi",
                      hintText: "gg-aa-yyyy",
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null;
                      }

                      try {
                        DateFormat("dd-MM-yyyy").parseStrict(v.trim());
                      } catch (_) {
                        return "Tarih gg-aa-yyyy formatında olmalıdır.";
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await _updateProfile(
                            name: nameController.text.trim(),
                            username: usernameController.text.trim(),
                            email: emailController.text.trim(),
                            phone: phoneController.text.trim(),
                            birth_date: birth_dateController.text.trim(),
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: const Text("Bilgileri Güncelle"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String firstLetter = _currentName.isNotEmpty
        ? _currentName[0].toUpperCase()
        : "?";

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.edit_note_rounded, size: 28),
          onPressed: _showEditBottomSheet,
        ),
        title: Text(
          "Profil",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Fotoğraf Ekleme İkonlu Profil Avatarı
            Center(
              child: SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ana Profil Avatarı
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryNavy,
                            AppTheme.secondaryNavy,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryNavy.withAlpha(50),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Sağ Alt Köşedeki Fotoğraf Ekleme Dairesi
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: InkWell(
                        onTap: () {
                          // Fotoğraf seçme mantığı
                        },
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

            const SizedBox(height: 100),

            // Koyu / Açık Tema Switch Kartı
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withAlpha(200),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SwitchListTile(
                value: _isDarkMode,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                secondary: Icon(
                  _isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  "Koyu Tema",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                onChanged: (value) async {
                  setState(() {
                    _isDarkMode = value;
                  });

                  // Temayı tüm uygulamada anında güncelle
                  themeNotifier.value = value
                      ? ThemeMode.dark
                      : ThemeMode.light;

                  // Tercihi kalıcı kaydet
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("isDarkMode", value);
                },
              ),
            ),

            const SizedBox(height: 30),

            // Çıkış Yap Butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.primary.withAlpha(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text(
                  "Çıkış Yap",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}