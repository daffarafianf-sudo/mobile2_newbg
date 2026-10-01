import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/keuangan_model.dart';
import '../models/laporan_model.dart';
import '../models/riwayat_model.dart';
import '../models/stok_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'promo_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// Dipanggil untuk pindah tab: 1 Riwayat, 2 Keuangan, 3 Stok, 4 Laporan
  final ValueChanged<int>? onNavigate;
  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  List<RiwayatItem> _riwayat = [];
  List<CashEntry> _manual = [];
  List<LaporanProduk> _top = [];
  StokSummary? _stok;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _manual = await KeuanganService.loadManual();

    try {
      final res = await ApiService.getRiwayat(token, tipe: 'semua');
      if (res['success'] == true) {
        _riwayat = (res['data'] as List<dynamic>)
            .map((e) => RiwayatItem.fromJson(e))
            .toList();
      }
    } catch (_) {}

    try {
      final res = await ApiService.getLaporanProduk(token);
      if (res['success'] == true) {
        _top = (res['data'] as List<dynamic>)
            .map((e) => LaporanProduk.fromJson(e as Map<String, dynamic>))
            .take(3)
            .toList();
      }
    } catch (_) {}

    try {
      final res = await ApiService.getStok(token);
      if (res['success'] == true) {
        _stok = StokSummary.fromJson(res['summary']);
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final selesai = _riwayat.where((r) => r.isSelesai).toList();
    final hariIni = selesai.where((r) => _sameDay(r.createdAt, now)).toList();
    final pendapatanHariIni = hariIni.fold<double>(0, (a, b) => a + b.total);

    final bulanIni =
        selesai.where((r) => r.createdAt.year == now.year && r.createdAt.month == now.month);
    var masukBulan = bulanIni.fold<double>(0, (a, b) => a + b.total);
    var keluarBulan = 0.0;
    for (final m in _manual) {
      if (m.tanggal.year == now.year && m.tanggal.month == now.month) {
        if (m.masuk) {
          masukBulan += m.jumlah;
        } else {
          keluarBulan += m.jumlah;
        }
      }
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selamat datang,',
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text('Owner Hayki',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 20),

            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B1710), Color(0xFF3A2F17)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3A2F17).withOpacity(0.28),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up_rounded,
                          color: AppColors.accentLight, size: 16),
                      const SizedBox(width: 6),
                      Text('PENDAPATAN HARI INI',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentLight)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _loading
                      ? const SizedBox(
                          height: 42,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.accentLight),
                            ),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(rupiah(pendapatanHariIni),
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text('${hariIni.length} transaksi selesai',
                            style: GoogleFonts.dmSans(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pemasukan / pengeluaran bulan ini
            Row(
              children: [
                Expanded(
                  child: _FlowCard(
                    label: 'Pemasukan',
                    value: masukBulan,
                    icon: Icons.south_west_rounded,
                    color: AppColors.success,
                    onTap: () => widget.onNavigate?.call(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FlowCard(
                    label: 'Pengeluaran',
                    value: keluarBulan,
                    icon: Icons.north_east_rounded,
                    color: AppColors.danger,
                    onTap: () => widget.onNavigate?.call(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Text('Total bulan ini',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
            const SizedBox(height: 22),

            // Aksi cepat
            Text('Menu Cepat',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickAction(
                    icon: Icons.history_rounded,
                    label: 'Riwayat',
                    onTap: () => widget.onNavigate?.call(1)),
                _QuickAction(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Keuangan',
                    onTap: () => widget.onNavigate?.call(2)),
                _QuickAction(
                    icon: Icons.inventory_2_rounded,
                    label: 'Stok',
                    badge: (_stok?.stokHabis ?? 0) + (_stok?.hampirHabis ?? 0),
                    onTap: () => widget.onNavigate?.call(3)),
                _QuickAction(
                    icon: Icons.local_offer_rounded,
                    label: 'Promo',
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: AppColors.bg,
                              appBar: AppBar(
                                  title: const Text('Promo'),
                                  backgroundColor: AppColors.bg),
                              body: const PromoScreen(),
                            ),
                          ),
                        )),
              ],
            ),
            const SizedBox(height: 26),

            // Terlaris
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Produk Terlaris',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: () => widget.onNavigate?.call(4),
                  child: Text('Lihat semua',
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.accentDark,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_top.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _loading ? 'Memuat...' : 'Belum ada data penjualan produk',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              )
            else
              ..._top.asMap().entries.map(
                    (e) => _ProductCard(rank: e.key + 1, p: e.value),
                  ),
          ],
        ),
      ),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _FlowCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(rupiahCompact(value),
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Icon(icon, color: AppColors.accentDark, size: 24),
                ),
                if (badge > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$badge',
                          style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final int rank;
  final LaporanProduk p;
  const _ProductCard({required this.rank, required this.p});

  @override
  Widget build(BuildContext context) {
    final rankColors = [
      AppColors.accent,
      const Color(0xFF8E8E93),
      const Color(0xFFB07A3A)
    ];
    final c = rankColors[(rank - 1).clamp(0, 2)];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('#$rank',
                style: GoogleFonts.dmSans(
                    fontSize: 13, fontWeight: FontWeight.w800, color: c)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.namaProduk,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text('Terjual ${p.totalTerjual} pcs',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Text(rupiahCompact(p.totalPendapatan),
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentDark)),
        ],
      ),
    );
  }
}
