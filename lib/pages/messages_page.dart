import 'dart:ui';
import 'package:flutter/material.dart';
import 'chats_page.dart';
import 'discover_page.dart';
import 'profile.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {

  int _selectedIndex = 0; 
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;

  bool _showSmallTitle = false;
  String _searchText = "";
  double _currentPage = 0.0; // Dynamic page scroll position indicator

  final List<Map<String, dynamic>> users = [
    {
      "name": "Ahmet Yılmaz",
      "message": "Yarınki toplantı saat kaçtaydı?",
      "time": "17:45",
      "icon": Icons.person,
      "unread": 7,
    },
    {
      "name": "Zeynep Kaya",
      "message": "Gönderdiğin dosyaları inceledim, harika görünüyor! 🚀",
      "time": "16:20",
      "icon": Icons.person,
      "unread": 3,
    },
    {
      "name": "Mehmet Demir",
      "message": "Kahve içmeye ne dersin?",
      "time": "14:15",
      "icon": Icons.person,
      "unread": 4,
    },
    {
      "name": "Elif Şahin",
      "message": "Projeyi bugün teslim etmemiz gerekiyor mu?",
      "time": "12:05",
      "icon": Icons.person,
    },
    {
      "name": "Caner Öztürk",
      "message": "Tamamdır, haberleşiriz.",
      "time": "Dün",
      "icon": Icons.person,
    },
    {
      "name": "Selin Aydın",
      "message": "Fotoğrafları gruba atabilir misin?",
      "time": "Dün",
      "icon": Icons.person,
    },
    {
      "name": "Burak Çelik",
      "message": "Arayabilir misin musait olduğunda?",
      "time": "Pazartesi",
      "icon": Icons.person,
    },
    {
      "name": "Merve Yıldız",
      "message": "Teşekkür ederim, çok yardımcı oldun!",
      "time": "Pazartesi",
      "icon": Icons.person,
    },
    {
      "name": "Emre Kurtuluş",
      "message": "Konumu attım, bekliyorum.",
      "time": "12.05.2026",
      "icon": Icons.person,
    },
    {
      "name": "Deniz Arslan",
      "message": "İyi haftasonları! 🎉",
      "time": "10.05.2026",
      "icon": Icons.person,
    },
    {
      "name": "Gözde Doğan",
      "message": "Son güncellemeleri koda pushladım.",
      "time": "08.05.2026",
      "icon": Icons.person,
    },
    {
      "name": "Kaan Özkan",
      "message": "Ses kaydı gönderdi (0:24)",
      "time": "01.05.2026",
      "icon": Icons.person,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex); //ilk sohbet sayfası aciliyor
    _scrollController.addListener(() {
      final show = _scrollController.offset > 55;
      if (show != _showSmallTitle) { //kücük sohbetler basligi
        setState(() {
          _showSmallTitle = show;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      extendBody: true,
      body: Stack(
        children: [
          // İçerik Katmanı 
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                setState(() {
                  _currentPage =
                      _pageController.page ?? _selectedIndex.toDouble();
                });
              }
              return false;
            },
            child: PageView( // sayfayı sağa sola kaydırır
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedIndex = index);
              },
              children: [_page(), const DiscoverPage(), const ProfilePage()],
            ),
          ),

          // 2. Üst Cam AppBar
          if (_selectedIndex == 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 20),
                opacity: _showSmallTitle ? 1.0 : 0.0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: MediaQuery.of(context).padding.top + 52,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(190),
                        border: Border(
                          bottom: BorderSide(
                            color: const Color(0xFF08314D).withAlpha(15),
                            width: 0.8,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Sohbetler",
                        style: TextStyle(
                          color: Color.fromARGB(255, 6, 44, 65),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // sürüklenen bar
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: _buildCustomGlassNavBar(),
          ),
        ],
      ),
    );
  }

  // Sürüklenebilir Kapsüllü Glass Navigation Bar (Tüm Renk ve Ayarları Birebir Korundu)
  Widget _buildCustomGlassNavBar() {
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
            color: Colors.black.withAlpha(20),
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
                color: Colors.white.withAlpha(180),
                width: 1.5,
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
                    setState(() {
                      _currentPage = targetPage;
                    });
                    if (_pageController.hasClients) {
                      _pageController.jumpTo(
                        targetPage * _pageController.position.viewportDimension,
                      );
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    int targetIndex = _currentPage.round().clamp(
                      0,
                      navItems.length - 1,
                    );
                    setState(() {
                      _selectedIndex = targetIndex;
                      _currentPage = targetIndex.toDouble();
                    });
                    _pageController.animateToPage(
                      targetIndex,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: Stack(
                    children: [
                      // Sürüklenebilir Mavi Kapsül (Pill)
                      Positioned(
                        left: (_currentPage * itemWidth).clamp(
                          0.0,
                          totalWidth - itemWidth,
                        ),
                        width: itemWidth,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              4,
                              38,
                              73,
                            ).withAlpha(215),
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),

                      // İkonlar ve Metinler
                      Row(
                        children: List.generate(navItems.length, (index) {
                          double distance = (_currentPage - index).abs();
                          double selectionRatio = (1.0 - distance).clamp(
                            0.0,
                            1.0,
                          );

                          Color dynamicColor = Color.lerp(
                            const Color(0xFF4A5568),
                            Colors.white,
                            selectionRatio,
                          )!;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                  _currentPage = index.toDouble();
                                });
                                _pageController.animateToPage(
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

  Widget _page() {
    switch (_selectedIndex) {
      case 0:
        final filteredUsers = users.where((user) {
          return user["name"].toString().toLowerCase().contains(
            _searchText.toLowerCase(),
          );
        }).toList();

        final totalUnread = users.fold<int>(
          0,
          (sum, item) => sum + ((item["unread"] as int?) ?? 0),
        );

        return ListView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 120,
          ),
          children: [
            // Üst Başlık & Okunmayan Mesaj Rozeti
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    "Sohbetler",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF041B2A),
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (totalUnread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF08314D).withAlpha(18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$totalUnread yeni",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF08314D),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Arama Kutusu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(210),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF08314D).withAlpha(8),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      child: Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 44),
                    suffixIcon: _searchText.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchText = "";
                              });
                            },
                            child: const Icon(
                              Icons.cancel_rounded,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                          )
                        : null,
                    hintText: "Sohbetlerde ara...",
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Mesaj Listesi
            if (filteredUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Sonuç bulunamadı",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredUsers.map((user) {
                return _buildMessageTile(user);
              }),
          ],
        );

      case 1:
        return const DiscoverPage();
      case 2:
        return const ProfilePage();
      default:
        return const SizedBox();
    }
  }

  // Yenilenmiş Sohbet Kartı (Tüm Avatarlar Şık Lacivert/Mavi Gradyanlı)
  Widget _buildMessageTile(Map<String, dynamic> user) {
    final int unread = user["unread"] ?? 0;
    final String name = user["name"] ?? "";
    final String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: unread > 0 ? Colors.white : Colors.white.withAlpha(210),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: unread > 0
                ? const Color(0xFF08314D).withAlpha(20)
                : Colors.white,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFF08314D).withAlpha(15),
            highlightColor: const Color(0xFF08314D).withAlpha(8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatsPage(userName: user["name"]),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Tek Tip Şık Lacivert-Mavi Gradyan Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 14, 56, 84),
                          Color(0xFF1E5276),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF08314D).withAlpha(40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // İçerik Alanı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Üst Satır: İsim ve Tarih
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: unread > 0
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user["time"] ?? "",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: unread > 0
                                    ? const Color(0xFF08314D)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Alt Satır: Mesaj & Unread Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                user["message"] ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: unread > 0
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: unread > 0
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                height: 20,
                                constraints: const BoxConstraints(minWidth: 20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF08314D),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unread > 99 ? "99+" : unread.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
