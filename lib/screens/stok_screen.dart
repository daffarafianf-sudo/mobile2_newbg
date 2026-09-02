import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../models/stok_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class StokScreen extends StatefulWidget {
  const StokScreen({super.key});

  @override
  State<StokScreen> createState() => _StokScreenState();
}

class _StokScreenState extends State<StokScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  List<StokProduk> _produks = [];
  StokSummary? _summary;

  String _activeFilter = ''; // '' | 'habis' | 'hampir_habis' | 'aman'
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  String _token = '';
  String _role = '';

  final _fmt = NumberFormat.decimalPattern('id');

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data fetching ──────────────────────────────────────────────────────────
  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader) setState(() { _isLoading = true; _error = null; });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';
      _role  = prefs.getString('role')  ?? '';

      final res = await ApiService.getStok(
        _token,
        filter: _activeFilter.isEmpty ? null : _activeFilter,
        q: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (res['success'] == true) {
        setState(() {
          _summary = StokSummary.fromJson(res['summary']);
          _produks = (res['data'] as List)
              .map((e) => StokProduk.fromJson(e))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = res['message'] ?? 'Gagal memuat data stok';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Tidak dapat terhubung ke server';
        _isLoading = false;
      });
    }
  }

  // ── Tambah stok dialog ─────────────────────────────────────────────────────
  void _showTambahStokDialog(StokProduk produk, VarianStok varian) {
    final ctrl = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.border),
                left: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_box_rounded,
                          color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Stok',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${produk.namaProduk} · ${varian.label.isNotEmpty ? varian.label : 'Default'}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stok saat ini
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stok sekarang',
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        '${varian.stok} pcs',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: varian.stok <= 10
                              ? AppColors.danger
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Input jumlah
                Text(
                  'Jumlah tambah',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 50',
                    suffixText: 'pcs',
                    suffixStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final jumlah = int.tryParse(ctrl.text.trim()) ?? 0;
                            if (jumlah <= 0) {
                              Fluttertoast.showToast(
                                  msg: 'Masukkan jumlah yang valid');
                              return;
                            }
                            setModal(() => saving = true);
                            try {
                              final res = await ApiService.tambahStok(
                                  _token, varian.id, jumlah);
                              if (res['success'] == true) {
                                Navigator.pop(ctx);
                                Fluttertoast.showToast(msg: res['message']);
                                _loadData(showLoader: false);
                              } else {
                                Fluttertoast.showToast(
                                    msg: res['message'] ?? 'Gagal tambah stok');
                                setModal(() => saving = false);
                              }
                            } catch (_) {
                              Fluttertoast.showToast(
                                  msg: 'Tidak dapat terhubung ke server');
                              setModal(() => saving = false);
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Simpan Tambah Stok'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchAndFilter(),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
        else if (_error != null)
          _buildError()
        else
          Expanded(child: _buildContent()),
      ],
    );
  }

  // ── Search + filter bar ───────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchCtrl,
            style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
            onSubmitted: (v) {
              setState(() => _searchQuery = v.trim());
              _loadData(showLoader: false);
            },
            onChanged: (v) {
              if (v.isEmpty) {
                setState(() => _searchQuery = '');
                _loadData(showLoader: false);
              }
            },
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                        _loadData(showLoader: false);
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 10),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                    label: 'Semua',
                    value: '',
                    active: _activeFilter == '',
                    color: AppColors.accent,
                    onTap: () {
                      setState(() => _activeFilter = '');
                      _loadData(showLoader: false);
                    }),
                const SizedBox(width: 8),
                _FilterChip(
                    label: '⚠ Hampir Habis',
                    value: 'hampir_habis',
                    active: _activeFilter == 'hampir_habis',
                    color: AppColors.warning,
                    onTap: () {
                      setState(() => _activeFilter = 'hampir_habis');
                      _loadData(showLoader: false);
                    }),
                const SizedBox(width: 8),
                _FilterChip(
                    label: '✕ Habis',
                    value: 'habis',
                    active: _activeFilter == 'habis',
                    color: AppColors.danger,
                    onTap: () {
                      setState(() => _activeFilter = 'habis');
                      _loadData(showLoader: false);
                    }),
                const SizedBox(width: 8),
                _FilterChip(
                    label: '✓ Aman',
                    value: 'aman',
                    active: _activeFilter == 'aman',
                    color: AppColors.success,
                    onTap: () {
                      setState(() => _activeFilter = 'aman');
                      _loadData(showLoader: false);
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildError() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.dmSans(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _loadData(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent() {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      onRefresh: () => _loadData(showLoader: false),
      child: CustomScrollView(
        slivers: [
          // Summary cards
          if (_summary != null)
            SliverToBoxAdapter(child: _buildSummary()),

          // Alert: stok bermasalah
          if ((_summary?.stokHabis ?? 0) + (_summary?.hampirHabis ?? 0) > 0)
            SliverToBoxAdapter(child: _buildAlert()),

          // Empty state
          if (_produks.isEmpty)
            SliverFillRemaining(child: _buildEmpty()),

          // List produk
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildProdukCard(_produks[i]),
                childCount: _produks.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary row ───────────────────────────────────────────────────────────
  Widget _buildSummary() {
    final s = _summary!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Row(
        children: [
          _SummaryBadge(
            label: 'Total Stok',
            value: '${_fmt.format(s.totalStok)} pcs',
            color: AppColors.accent,
          ),
          const SizedBox(width: 8),
          _SummaryBadge(
            label: 'Hampir Habis',
            value: '${s.hampirHabis} produk',
            color: AppColors.warning,
          ),
          const SizedBox(width: 8),
          _SummaryBadge(
            label: 'Habis',
            value: '${s.stokHabis} produk',
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  // ── Alert banner ──────────────────────────────────────────────────────────
  Widget _buildAlert() {
    final jumlah =
        (_summary?.stokHabis ?? 0) + (_summary?.hampirHabis ?? 0);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: AppColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$jumlah produk perlu diperhatikan stoknya',
              style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.textMuted, size: 52),
          const SizedBox(height: 12),
          Text('Tidak ada produk ditemukan',
              style:
                  GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14)),
        ],
      ),
    );
  }

  // ── Produk card ───────────────────────────────────────────────────────────
  Widget _buildProdukCard(StokProduk produk) {
    final isKaryawan = _role == 'karyawan' || _role == 'pemilik';
    final Color statusColor = produk.statusStok == 'habis'
        ? AppColors.danger
        : produk.statusStok == 'hampir_habis'
            ? AppColors.warning
            : AppColors.success;

    final String statusLabel = produk.statusStok == 'habis'
        ? '✕ Stok Habis'
        : produk.statusStok == 'hampir_habis'
            ? '⚠ Hampir Habis'
            : '✓ Stok Aman';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: produk.statusStok != 'aman'
              ? statusColor.withOpacity(0.35)
              : AppColors.border,
        ),
      ),
      // ExpansionTile untuk tampilkan varian
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              produk.statusStok == 'habis'
                  ? Icons.remove_shopping_cart_rounded
                  : produk.statusStok == 'hampir_habis'
                      ? Icons.warning_rounded
                      : Icons.checkroom_rounded,
              size: 18,
              color: statusColor,
            ),
          ),
          title: Text(
            produk.namaProduk,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  // Total stok besar
                  Text(
                    '${produk.totalStok} pcs',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (produk.hargaMin != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Mulai Rp ${_fmt.format(produk.hargaMin)}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 6),
              // Progress bar total stok (maks 100 unit sebagai referensi)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (produk.totalStok / 100).clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${produk.varians.length} varian tersedia — ketuk untuk detail',
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
          // ── Daftar varian ────────────────────────────────────────────────
          children: [
            const Divider(color: AppColors.border, height: 1),
            ...produk.varians.map((v) => _buildVarianRow(produk, v, isKaryawan)),
          ],
        ),
      ),
    );
  }

  // ── Varian row ─────────────────────────────────────────────────────────────
  Widget _buildVarianRow(
      StokProduk produk, VarianStok v, bool isKaryawan) {
    final isLow = v.stok <= 10;
    final Color stockColor = v.stok == 0
        ? AppColors.danger
        : isLow
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Label varian
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.label.isNotEmpty ? v.label : 'Default',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (v.sku != null)
                  Text(
                    'SKU: ${v.sku}',
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
                if (v.tanggalRestok != null)
                  Text(
                    'Restok: ${v.tanggalRestok}',
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),

          // Harga
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rp ${_fmt.format(v.harga)}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${v.stok} pcs',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: stockColor,
                ),
              ),
            ],
          ),

          // Tombol tambah stok — hanya karyawan/pemilik
          if (isKaryawan) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _showTambahStokDialog(produk, v),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.accent, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label, value;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : AppColors.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label, value;
  final Color color;

  const _SummaryBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
