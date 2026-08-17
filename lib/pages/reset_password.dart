import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Lafla/themes/tema1.dart';
import '../services/api_client.dart';

class ResetPasswordPage extends StatefulWidget {
  final String resetToken;

  const ResetPasswordPage({
    super.key,
    required this.resetToken,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiClient api = ApiClient();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Yeni şifrenizi giriniz.";
    }
    if (value.length < 6) {
      return "Şifre en az 6 karakter olmalıdır.";
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "En az 1 küçük harf içermelidir.";
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "En az 1 büyük harf içermelidir.";
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return "En az 1 rakam içermelidir.";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Şifrenizi tekrar giriniz.";
    }
    if (value != _passwordController.text) {
      return "Şifreler eşleşmiyor.";
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final response = await api.resetPassword(
        resetToken: widget.resetToken,
        newPassword: _passwordController.text,
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        AppTheme.showSnackBar(
          context,
          message: "Şifreniz başarıyla değiştirildi.",
          isError: false,
        );

        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        );
      } else {
        AppTheme.showSnackBar(
          context,
          message: data["error"] ?? "Şifre sıfırlanamadı.",
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppTheme.showSnackBar(
        context,
        message: "Sunucuya bağlanılamadı.\n$e",
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Şifre"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                Icon(
                  Icons.password_rounded,
                  size: 70,
                  color: isDark ? AppTheme.primaryNavy : const Color(0xFF19181B),
                ),
                const SizedBox(height: 24),
                Text(
                  "Yeni şifreni oluştur",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Yeni şifreni belirle ve hesabına tekrar giriş yap.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  decoration: InputDecoration(
                    labelText: "Yeni Şifre",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "Yeni Şifre Tekrar",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  style: AppTheme.standardButtonStyle(context),
                  onPressed: _loading ? null : _resetPassword,
                  child: _loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? const Color(0xFF121114) : Colors.white,
                          ),
                        )
                      : const Text("Şifreyi Sıfırla"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}