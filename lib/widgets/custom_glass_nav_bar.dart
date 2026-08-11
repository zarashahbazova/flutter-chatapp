import 'dart:ui';
import 'package:flutter/material.dart';

class CustomGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final double currentPage;
  final PageController pageController;
  final Function(int index) onPageSelected; 
  final Function(double page) onPageDragged;

  const CustomGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.currentPage,
    required this.pageController,
    required this.onPageSelected,
    required this.onPageDragged,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Sohbetler'},
      {'icon': Icons.explore_outlined, 'label': 'Keşfet'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profil'},
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 44, 44, 44).withAlpha(20),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect( 
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: const Color.fromARGB(255, 38, 21, 59).withAlpha(20),
                width: 1.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth; //toplam genislik
                final itemWidth = totalWidth / navItems.length;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    double targetPage = (details.localPosition.dx / itemWidth)
                        .clamp(0.0, (navItems.length - 1).toDouble());
                    onPageDragged(targetPage);
                    if (pageController.hasClients) { //konuma bağlı mı
                      pageController.jumpTo(
                        targetPage * pageController.position.viewportDimension,
                      );
                    }
                  },
                  onHorizontalDragEnd: (details) { //yuvarla
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
                            color: const Color.fromARGB(240, 35, 25, 63),
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(navItems.length, (index) {
                          double distance = (currentPage - index).abs();
                          double selectionRatio = (1.0 - distance).clamp(
                            0.0,
                            1.0,
                          );
                          Color dynamicColor = Color.lerp(
                            Theme.of(context).colorScheme.onSurface.withAlpha(180),
                            const Color.fromARGB(227, 232, 219, 255),
                            selectionRatio,
                          )!;

                          return Expanded( // eşit paylasim
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
                                  Icon(
                                    navItems[index]['icon'] as IconData,
                                    color: dynamicColor,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    navItems[index]['label'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: selectionRatio > 0.5
                                          ? FontWeight.w600
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