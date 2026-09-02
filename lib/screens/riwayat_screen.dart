import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/riwayat_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<RiwayatItem> _all = [];
  bool _loading = true;
  String? _error;
  String _token = '';

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      final res = await ApiService.getRiwayat(_token, tipe: 'semua');
      if (res['success'] == true) {
        final list = (res['data'] as List<dynamic>)
            .map((e) => RiwayatItem.fromJson(e))
            .toList();
        setState(() {
          _all = list;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Gagal memuat data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<RiwayatItem> _filtered(String tipe) {
    return _all.where((r) {
      final matchTipe = tipe == 'semua' || r.tipe == tipe;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          r.kode.toLowerCase().contains(q) ||
          (r.pembeli?.toLowerCase().contains(q) ?? false) ||
          (r.kasir?.toLowerCase().contains(q) ?? false) ||
          r.itemsPreview.toLowerCase().contains(q);
      return matchTipe && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari kode, pembeli, atau produk...',
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMuted, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.black,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Semua'),
                    const SizedBox(width: 4),
                    _CountBadge(count: _filtered('semua').length),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Online'),
                    const SizedBox(width: 4),
                    _CountBadge(count: _filtered('online').length),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Offline'),
                    const SizedBox(width: 4),
                    _CountBadge(count: _filtered('offline').length),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Content
        Expanded(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _loadData)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _RiwayatList(
                          items: _filtered('semua'),
                          token: _token,
                          onRefresh: _loadData,
                        ),
                        _RiwayatList(
                          items: _filtered('online'),
                          token: _token,
                          onRefresh: _loadData,
                        ),
                        _RiwayatList(
                          items: _filtered('offline'),
                          token: _token,
                          onRefresh: _loadData,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ─── List widget ──────────────────────────────────────────────────────────────

class _RiwayatList extends StatelessWidget {
  final List<RiwayatItem> items;
  final String token;
  final VoidCallback onRefresh;

  const _RiwayatList({
    required this.items,
    required this.token,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.textMuted, size: 52),
            const SizedBox(height: 12),
            Text(
              'Belum ada riwayat transaksi',
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: items.length,
        itemBuilder: (context, i) => _RiwayatCard(
          item: items[i],
          onTap: () => _openDetail(context, items[i]),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, RiwayatItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiwayatDetailScreen(item: item, token: token),
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _RiwayatCard extends StatelessWidget {
  final RiwayatItem item;
  final VoidCallback onTap;

  const _RiwayatCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('id');
    final isOnline = item.isOnline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.kode,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  // Online / Offline badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF0369A1).withOpacity(0.15)
                          : const Color(0xFF92400E).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOnline
                            ? const Color(0xFF0369A1).withOpacity(0.3)
                            : const Color(0xFF92400E).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isOnline ? 'Online' : 'Offline',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isOnline
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFFFBBF24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                      status: item.status, label: item.statusLabel),
                ],
              ),
              const SizedBox(height: 10),

              // Pembeli / Kasir
              Row(
                children: [
                  Icon(
                    isOnline
                        ? Icons.person_outline_rounded
                        : Icons.badge_outlined,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline
                        ? (item.pembeli ?? '-')
                        : 'Kasir: ${item.kasir ?? '-'}',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (item.promo != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '🏷 ${item.promo}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),

              // Items preview
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.itemsCount} item — ${item.itemsPreview}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10),

              // Footer: tanggal + total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy • HH:mm')
                        .format(item.createdAt.toLocal()),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'Rp ${fmt.format(item.total)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detail Screen ────────────────────────────────────────────────────────────

class RiwayatDetailScreen extends StatefulWidget {
  final RiwayatItem item;
  final String token;

  const RiwayatDetailScreen(
      {super.key, required this.item, required this.token});

  @override
  State<RiwayatDetailScreen> createState() => _RiwayatDetailScreenState();
}

class _RiwayatDetailScreenState extends State<RiwayatDetailScreen> {
  RiwayatItemDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> res;
      if (widget.item.isOnline) {
        res = await ApiService.getRiwayatDetailPesanan(
            widget.token, widget.item.id);
      } else {
        res = await ApiService.getRiwayatDetailTransaksi(
            widget.token, widget.item.id);
      }

      if (res['success'] == true) {
        setState(() {
          _detail = RiwayatItemDetail.fromJson(res['data']);
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Gagal memuat detail';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern('id');
    final item = widget.item;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Transaksi',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadDetail)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card
                      _DetailCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.kode,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                _TipeBadge(tipe: item.tipe),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMMM yyyy, HH:mm')
                                  .format(item.createdAt.toLocal()),
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(
                                color: AppColors.border, height: 1),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _InfoCell(
                                    label: item.isOnline
                                        ? 'Pembeli'
                                        : 'Kasir',
                                    value: item.isOnline
                                        ? (item.pembeli ?? '-')
                                        : (item.kasir ?? '-'),
                                  ),
                                ),
                                Expanded(
                                  child: _InfoCell(
                                    label: 'Metode Bayar',
                                    value: item.metodeBayar
                                        .toUpperCase(),
                                  ),
                                ),
                              ],
                            ),
                            if (item.promo != null) ...[
                              const SizedBox(height: 12),
                              _InfoCell(
                                  label: 'Promo', value: item.promo!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Items
                      _DetailCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Produk Dibeli',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(_detail?.items ?? []).map(
                              (it) => _ProductRow(item: it, fmt: fmt),
                            ),
                            const SizedBox(height: 12),
                            const Divider(
                                color: AppColors.border, height: 1),
                            const SizedBox(height: 12),

                            // Subtotal
                            _SummaryRow(
                              label: 'Subtotal',
                              value: 'Rp ${fmt.format(item.subtotal)}',
                            ),
                            if (item.diskon > 0)
                              _SummaryRow(
                                label: 'Diskon',
                                value:
                                    '-Rp ${fmt.format(item.diskon)}',
                                valueColor: AppColors.danger,
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Rp ${fmt.format(item.total)}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cash info (offline only)
                      if (!item.isOnline &&
                          (_detail?.uangDiterima ?? 0) > 0)
                        _DetailCard(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Info Pembayaran',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _SummaryRow(
                                label: 'Uang Diterima',
                                value:
                                    'Rp ${fmt.format(_detail!.uangDiterima)}',
                              ),
                              _SummaryRow(
                                label: 'Kembalian',
                                value:
                                    'Rp ${fmt.format(_detail!.kembalian)}',
                                valueColor: AppColors.success,
                              ),
                            ],
                          ),
                        ),

                      // Online pembayaran info
                      if (item.isOnline && _detail?.pembayaran != null)
                        _DetailCard(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Info Pembayaran',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _InfoCell(
                                      label: 'Metode',
                                      value: _detail!.pembayaran!.metode
                                          .toUpperCase(),
                                    ),
                                  ),
                                  Expanded(
                                    child: _InfoCell(
                                      label: 'Status',
                                      value: _detail!
                                          .pembayaran!.statusLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      // Catatan
                      if (_detail?.catatan != null &&
                          _detail!.catatan!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _DetailCard(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catatan',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _detail!.catatan!,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

// ─── Small sub-widgets ────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final Widget child;
  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 3),
        Text(value,
            style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final RiwayatItemLine item;
  final NumberFormat fmt;
  const _ProductRow({required this.item, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text('🧥', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.namaProduk,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${item.varian} · ${item.jumlah}x '
                  'Rp ${fmt.format(item.harga)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rp ${fmt.format(item.subtotal)}',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String label;
  const _StatusChip({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'selesai':
        color = AppColors.success;
        break;
      case 'dibatalkan':
        color = AppColors.danger;
        break;
      default:
        color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TipeBadge extends StatelessWidget {
  final String tipe;
  const _TipeBadge({required this.tipe});

  @override
  Widget build(BuildContext context) {
    final isOnline = tipe == 'online';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF0369A1).withOpacity(0.15)
            : const Color(0xFF92400E).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF0369A1).withOpacity(0.3)
              : const Color(0xFF92400E).withOpacity(0.3),
        ),
      ),
      child: Text(
        isOnline ? 'Pesanan Online' : 'Transaksi Offline',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOnline
              ? const Color(0xFF38BDF8)
              : const Color(0xFFFBBF24),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.textMuted.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text('Coba Lagi',
                style: GoogleFonts.dmSans(
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
