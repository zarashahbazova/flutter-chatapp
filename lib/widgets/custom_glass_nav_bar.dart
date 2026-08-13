import 'dart:ui';
import 'package:flutter/material.dart';

class CustomGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final double currentPage;
  final PageController pageController;
  final Function(int index) onPageSelected;
  final Function(double page) onPageDragged;
  final int totalUnread; // 👈 Toplam okunmamış mesaj sayısı eklendi

  const CustomGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.currentPage,
    required this.pageController,
    required this.onPageSelected,
    required this.onPageDragged,
    this.totalUnread = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Sadece Sohbetler ve Profil sekmeleri
    final navItems = [
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Sohbetler'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profil'},
    ];

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      height: 64,
      width: 220, // Tam ortada durması için sabit şık bir genişlik
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 25,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(90),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: theme.colorScheme.onSurface.withAlpha(25),
                width: 1.2,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemWidth = totalWidth / navItems.length;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    double targetPage = (details.localPosition.dx / itemWidth)
                        .clamp(0.0, (navItems.length - 1).toDouble());
                    onPageDragged(targetPage);
                    if (pageController.hasClients) {
                      pageController.jumpTo(
                        targetPage * pageController.position.viewportDimension,
                      );
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    int targetIndex = currentPage.round().clamp(
                          0,
                          navItems.length - 1,
                        );
                    onPageSelected(targetIndex);
                    pageController.animateToPage(
                      targetIndex,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Stack(
                    children: [
                      // Arka Plan Seçim İndikatörü
                      Positioned(
                        left: (currentPage * itemWidth).clamp(
                          0.0,
                          totalWidth - itemWidth,
                        ),
                        width: itemWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(200),
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),

                      // Sekme İkon ve Metinleri
                      Row(
                        children: List.generate(navItems.length, (index) {
                          double distance = (currentPage - index).abs();
                          double selectionRatio =
                              (1.0 - distance).clamp(0.0, 1.0);

                          Color dynamicColor = Color.lerp(
                            theme.colorScheme.onSurface.withAlpha(190),
                            Colors.white,
                            selectionRatio,
                          )!;

                          final bool isChatTab = index == 0;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                onPageSelected(index);
                                pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        navItems[index]['icon'] as IconData,
                                        color: dynamicColor,
                                        size: 22,
                                      ),

                                      // 🔴 Toplam Okunmamış Mesaj Rozeti (Total Unread)
                                      if (isChatTab && totalUnread > 0)
                                        Positioned(
                                          right: -8,
                                          top: -4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.2,
                                              ),
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            child: Text(
                                              totalUnread > 99
                                                  ? "99+"
                                                  : totalUnread.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    navItems[index]['label'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: selectionRatio > 0.5
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: dynamicColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}