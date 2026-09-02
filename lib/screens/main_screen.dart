import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

import 'dashboard_screen.dart';
import 'laporan_screen.dart';
import 'login_screen.dart';
import 'promo_screen.dart';
import 'riwayat_screen.dart';
import 'stok_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    DashboardScreen(),
    RiwayatScreen(),
    StokScreen(),
    LaporanScreen(),
    PromoScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Riwayat',
    'Stok',
    'Laporan',
    'Promo',
  ];

  final List<IconData> _icons = [
    Icons.grid_view_rounded,
    Icons.history_rounded,
    Icons.inventory_2_rounded,
    Icons.bar_chart_rounded,
    Icons.local_offer_rounded,
  ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
              ),
              child: const Icon(Icons.healing_rounded, size: 18, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[currentIndex],
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: _logout,
          ),
        ],
      ),
      body: screens[currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 10),
          onTap: (i) => setState(() => currentIndex = i),
          items: List.generate(
            _titles.length,
            (i) => BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Icon(_icons[i], size: 22),
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_icons[i], size: 22, color: AppColors.accent),
              ),
              label: _titles[i],
            ),
          ),
        ),
      ),
    );
  }
}
