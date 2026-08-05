import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    print("INIT STATE CALISTI");
    _loadProfile();
  }

  // Token Süresi Dolduğunda Çıkış
  Future<void> _handleExpiredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Oturum süreniz doldu. Lütfen tekrar giriş yapın."),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _loadProfile() async {
    print("LOAD PROFILE CALISTI");
    //backendden kullanici bilgilerini ceker
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      print("TOKEN: $token");
      if (token == null) {
        _logout();
        return;
      }

      final response = await api.get(url: "auth/profile", token: token);

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

      final response = await api.put(
        url: "auth/profile",
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
        // Ekrandaki bilgileri backend'den tekrar çek
        await _loadProfile();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil başarıyla güncellendi.")),
        );
      } else {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["error"] ?? "Güncelleme başarısız.")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bir hata oluştu: $e")));
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  Text(
                    "Profili Düzenle",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Ad Soyad",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "Adınızı giriniz."
                        : null,
                  ),
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: "Kullanıcı Adı",
                      prefixIcon: Icon(Icons.account_circle),
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
                  const SizedBox(height: 18),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "E-posta",
                      prefixIcon: Icon(Icons.email),
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
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,

                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                    decoration: const InputDecoration(
                      labelText: "Telefon",
                      prefixIcon: Icon(Icons.phone),
                    ),

                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return null; // Boş bırakılabilir
                      }

                      if (!RegExp(r'^\d{11}$').hasMatch(v.trim())) {
                        return "Telefon numarası 11 haneli olmalıdır.";
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
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
                      prefixIcon: Icon(Icons.cake),
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
                  const SizedBox(height: 35),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          await _updateProfile(
                            name: nameController.text.trim(),
                            username: usernameController.text.trim(),
                            email: emailController.text.trim(),
                            phone: phoneController.text.trim(),
                            birth_date: birth_dateController.text.trim(),
                            //birth_date: "",
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.edit),
          tooltip: "Profili Düzenle",
          onPressed: _showEditBottomSheet,
        ),
        title: Text(
          "Profil",
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 100),

              const Icon(Icons.account_circle, size: 140),

              const SizedBox(height: 20),

              Text(
                _currentName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "@$_currentUsername",
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 100),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  child: const Text("Çıkış Yap"),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
