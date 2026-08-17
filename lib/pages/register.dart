import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Lafla/pages/messages_page.dart';
import 'package:Lafla/themes/tema1.dart';
import '../services/api_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final ApiClient api = ApiClient();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Adınızı giriniz.";
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Kullanıcı adınızı giriniz.";
    }
    if (value.length < 3 || value.length > 20) {
      return "3-20 karakter olmalıdır.";
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value)) {
      return "Sadece harf, rakam ve _ kullanılabilir.";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "E-posta giriniz.";
    }
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!regex.hasMatch(value.trim())) {
      return "Geçerli bir e-posta giriniz.";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Şifre giriniz.";
    }
    if (value.length < 6) {
      return "Şifre en az 6 karakter olmalıdır.";
    }
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return "Şifre en az 1 küçük harf içermelidir.";
    }
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return "Şifre en az 1 büyük harf içermelidir.";
    }
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return "Şifre en az 1 rakam içermelidir.";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Şifreyi tekrar giriniz.";
    }
    if (value != _passwordController.text) {
      return "Şifreler uyuşmuyor.";
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await api.post(
        url: "auth/register",
        body: {
          "full_name": _nameController.text.trim(),
          "user_name": _usernameController.text.trim(),
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        final token = data["data"]["token"];
        final user = data["data"]["user"];

        await prefs.setString("token", token);
        if (user != null && user["id"] != null) {
          final userId = user["id"] is int
              ? user["id"]
              : int.parse(user["id"].toString());
          await prefs.setInt("userId", userId);
        }

        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await api.put(
            url: "auth/fcm-token",
            token: token,
            body: {"fcm_token": fcmToken},
          );
        }

        if (!mounted) return;

        AppTheme.showSnackBar(
          context,
          message: "Kayıt başarılı, yönlendiriliyorsunuz...",
          isError: false,
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MessagesPage()),
          (route) => false,
        );
      } else {
        String errorMsg = data["error"] ?? "Kayıt işlemi başarısız.";
        if (data["errors"] != null && data["errors"].isNotEmpty) {
          errorMsg = data["errors"][0]["msg"];
        }
        if (!mounted) return;
        AppTheme.showSnackBar(context, message: errorMsg, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Sunucuya bağlanılamadı: $e",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = AppTheme.getSectionHeaderColor(isDark);
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: const Text(
          "Kayıt Ol",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    "HESAP BİLGİLERİ",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: subColor,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: onSurfaceColor),
                  validator: _validateName,
                  decoration: InputDecoration(
                    labelText: "Ad Soyad",
                    prefixIcon: Icon(Icons.person, color: subColor),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: onSurfaceColor),
                  validator: _validateUsername,
                  decoration: InputDecoration(
                    labelText: "Kullanıcı Adı",
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: subColor),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: onSurfaceColor),
                  validator: _validateEmail,
                  decoration: InputDecoration(
                    labelText: "E-posta",
                    prefixIcon: Icon(Icons.email, color: subColor),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: onSurfaceColor),
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: "Şifre",
                    prefixIcon: Icon(Icons.lock, color: subColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: subColor,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(color: onSurfaceColor),
                  validator: _validateConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Şifre Tekrar",
                    prefixIcon: Icon(Icons.lock_reset, color: subColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: subColor,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: AppTheme.standardButtonStyle(context),
                    onPressed: _isLoading ? null : _register,
                    child: _isLoading
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: isDark ? const Color(0xFF121114) : Colors.white,
                            ),
                          )
                        : const Text("Kayıt Ol"),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}