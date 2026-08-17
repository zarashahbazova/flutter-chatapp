import 'package:flutter/material.dart';
import 'package:Lafla/themes/tema1.dart';

class NewChatSheet extends StatelessWidget {
  const NewChatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = AppTheme.getSurfaceColor(isDark);
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: onSurfaceColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Yeni Sohbet",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: onSurfaceColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Nasıl başlamak istersin?",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getSectionHeaderColor(isDark),
                ),
              ),
              const SizedBox(height: 18),
              _NewChatOption(
                icon: Icons.person_add_rounded,
                title: "Kişisel Sohbet Başlat",
                subtitle: "Kullanıcı adı veya isim arayarak sohbet edin",
                isDark: isDark,
                onTap: () => Navigator.pop(context, "single"),
              ),
              const SizedBox(height: 10),
              _NewChatOption(
                icon: Icons.groups_rounded,
                title: "Yeni Grup Oluştur",
                subtitle: "Birden fazla kişiyi seçerek sohbet grubu kurun",
                isDark: isDark,
                onTap: () => Navigator.pop(context, "group"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewChatOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _NewChatOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getSurfaceColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getCardBorder(isDark),
          width: 1.1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.getIconBg(isDark),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.getIconFg(isDark),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            color: onSurfaceColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getSectionHeaderColor(isDark),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: onSurfaceColor.withAlpha(100),
        ),
        onTap: onTap,
      ),
    );
  }
}