import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stajapp/pages/messages_page.dart';
import 'package:stajapp/themes/tema1.dart';
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
      print(response.statusCode);
      print(response.body);

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

        print("REGISTER FCM TOKEN: $fcmToken");

        await api.put(
          url: "auth/fcm-token",
          token: token,
          body: {"fcm_token": fcmToken},
        );

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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        title: Text(
          "Kayıt Ol",
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  validator: _validateName,
                  decoration: const InputDecoration(
                    labelText: "Ad Soyad",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _usernameController,
                  validator: _validateUsername,
                  decoration: const InputDecoration(
                    labelText: "Kullanıcı Adı",
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                  decoration: const InputDecoration(
                    labelText: "E-posta",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: "Şifre",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Şifre Tekrar",
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _register,
                    child: const Text("Kayıt Ol"),
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