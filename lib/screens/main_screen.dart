import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

import 'dashboard_screen.dart';
import 'keuangan_screen.dart';
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

  static const _titles = ['Beranda', 'Riwayat', 'Keuangan', 'Stok', 'Laporan'];
  static const _icons = [
    Icons.home_rounded,
    Icons.history_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.inventory_2_rounded,
    Icons.bar_chart_rounded,
  ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _openPromo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            title: const Text('Promo'),
            backgroundColor: AppColors.bg,
          ),
          body: const PromoScreen(),
        ),
      ),
    );
  }

  Widget _body() {
    switch (currentIndex) {
      case 0:
        return DashboardScreen(
            onNavigate: (i) => setState(() => currentIndex = i));
      case 1:
        return const RiwayatScreen();
      case 2:
        return const KeuanganScreen();
      case 3:
        return const StokScreen();
      default:
        return const LaporanScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
              ),
              child: Center(
                child: Text('H',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1710))),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _titles[currentIndex],
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Promo',
            icon: const Icon(Icons.local_offer_outlined,
                color: AppColors.textSecondary, size: 22),
            onPressed: _openPromo,
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_rounded,
                color: AppColors.textSecondary, size: 20),
            onPressed: _logout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: KeyedSubtree(key: ValueKey(currentIndex), child: _body()),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1405).withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_titles.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => currentIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.accent.withOpacity(0.16)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icons[i],
                            size: 22,
                            color: active
                                ? AppColors.accentDark
                                : AppColors.textMuted),
                        const SizedBox(height: 3),
                        Text(
                          _titles[i],
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? AppColors.accentDark
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
