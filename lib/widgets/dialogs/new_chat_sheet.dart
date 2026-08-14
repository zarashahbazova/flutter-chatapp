import 'package:flutter/material.dart';
import 'package:Lafla/themes/tema1.dart';

class NewChatSheet extends StatelessWidget {
  const NewChatSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor =
        Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurfaceColor.withAlpha(45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Yeni Sohbet",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: onSurfaceColor,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Nasıl başlamak istersin?",
              style: TextStyle(
                fontSize: 13,
                color: onSurfaceColor.withAlpha(130),
              ),
            ),

            const SizedBox(height: 16),

            _NewChatOption(
              icon: Icons.person_add_rounded,
              title: "Kişisel Sohbet Başlat",
              subtitle:
                  "Kullanıcı adı veya isim arayarak sohbet edin",
              onTap: () {
                Navigator.pop(context, "single");
              },
            ),

            const SizedBox(height: 10),

            _NewChatOption(
              icon: Icons.groups_rounded,
              title: "Yeni Grup Oluştur",
              subtitle:
                  "Birden fazla kişiyi seçerek sohbet grubu kurun",
              onTap: () {
                Navigator.pop(context, "group");
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NewChatOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NewChatOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceColor =
        Theme.of(context).colorScheme.onSurface;

    return Material(
      color: onSurfaceColor.withAlpha(8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        splashColor: AppTheme.primaryNavy.withAlpha(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: onSurfaceColor.withAlpha(14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      AppTheme.primaryNavy,
                      AppTheme.secondaryNavy,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppTheme.primaryNavy.withAlpha(50),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
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
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            onSurfaceColor.withAlpha(130),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color: onSurfaceColor.withAlpha(90),
              ),
            ],
          ),
        ),
      ),
    );
  }
}