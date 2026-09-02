import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/laporan_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  // ── State ─────────────────────────────────────────────────────────────────
  bool _loading = true;
  String? _error;
  LaporanSummary? _summary;
  List<LaporanProduk> _data = [];

  // Filter & sort
  DateTime? _dari;
  DateTime? _sampai;
  String _searchQ = '';
  String _sort = 'terjual_desc';

  final _searchCtrl = TextEditingController();
  final _fmt = NumberFormat.decimalPattern('id');
  final _fmtDate = DateFormat('dd MMM yyyy');

  // Sort options
  final _sortOptions = const {
    'terjual_desc': 'Terjual Terbanyak',
    'pendapatan_desc': 'Pendapatan Tertinggi',
    'nama_asc': 'Nama A–Z',
    'terjual_asc': 'Terjual Tersedikit',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await ApiService.getLaporanProduk(
        token,
        dari: _dari != null ? DateFormat('yyyy-MM-dd').format(_dari!) : null,
        sampai:
            _sampai != null ? DateFormat('yyyy-MM-dd').format(_sampai!) : null,
        q: _searchQ.isNotEmpty ? _searchQ : null,
        sort: _sort,
      );
      if (res['success'] == true) {
        _summary = LaporanSummary.fromJson(res['summary']);
        _data = (res['data'] as List<dynamic>)
            .map((e) => LaporanProduk.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _error = res['message']?.toString() ?? 'Gagal memuat laporan';
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: $e';
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Date picker helper ────────────────────────────────────────────────────
  Future<void> _pickDate({required bool isDari}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDari ? (_dari ?? now) : (_sampai ?? now),
      firstDate: DateTime(2024),
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.black,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isDari) {
        _dari = picked;
        if (_sampai != null && _sampai!.isBefore(picked)) _sampai = null;
      } else {
        _sampai = picked;
        if (_dari != null && _dari!.isAfter(picked)) _dari = null;
      }
    });
    _load();
  }

  void _clearFilter() {
    setState(() {
      _dari = null;
      _sampai = null;
      _searchQ = '';
      _searchCtrl.clear();
      _sort = 'terjual_desc';
    });
    _load();
  }

  bool get _hasFilter =>
      _dari != null ||
      _sampai != null ||
      _searchQ.isNotEmpty ||
      _sort != 'terjual_desc';

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        if (_hasFilter)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _buildFilterLabel(),
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _clearFilter,
                  child: Text('Reset',
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.accent)),
                )
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
              : _error != null
                  ? _buildError()
                  : _data.isEmpty
                      ? _buildEmpty()
                      : _buildContent(),
        ),
      ],
    );
  }

  // ── Filter bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchCtrl,
            style:
                GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari nama produk…',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              suffixIcon: _searchQ.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQ = '');
                        _load();
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (v) {
              setState(() => _searchQ = v.trim());
              _load();
            },
          ),
          const SizedBox(height: 10),
          // Date range + sort row
          Row(
            children: [
              // Dari
              Expanded(
                child: _FilterChip(
                  icon: Icons.calendar_today_outlined,
                  label:
                      _dari != null ? _fmtDate.format(_dari!) : 'Dari tanggal',
                  active: _dari != null,
                  onTap: () => _pickDate(isDari: true),
                ),
              ),
              const SizedBox(width: 8),
              // Sampai
              Expanded(
                child: _FilterChip(
                  icon: Icons.event_rounded,
                  label: _sampai != null
                      ? _fmtDate.format(_sampai!)
                      : 'Sampai tanggal',
                  active: _sampai != null,
                  onTap: () => _pickDate(isDari: false),
                ),
              ),
              const SizedBox(width: 8),
              // Sort
              _FilterChip(
                icon: Icons.swap_vert_rounded,
                label: 'Urut',
                active: _sort != 'terjual_desc',
                onTap: _showSortSheet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildFilterLabel() {
    final parts = <String>[];
    if (_dari != null || _sampai != null) {
      final a = _dari != null ? _fmtDate.format(_dari!) : '...';
      final b = _sampai != null ? _fmtDate.format(_sampai!) : '...';
      parts.add('$a – $b');
    }
    if (_searchQ.isNotEmpty) parts.add('"$_searchQ"');
    parts.add(_sortOptions[_sort]!);
    return parts.join(' · ');
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Urutkan',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: 12),
          ..._sortOptions.entries.map((e) => ListTile(
                tileColor: Colors.transparent,
                title: Text(e.value,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary, fontSize: 14)),
                trailing: _sort == e.key
                    ? const Icon(Icons.check_rounded, color: AppColors.accent)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _sort = e.key);
                  _load();
                },
              )),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Summary + list ────────────────────────────────────────────────────────
  Widget _buildContent() {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.card,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          if (_summary != null) ...[
            _buildSummaryCards(),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produk Terjual',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_data.length} produk',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._data.map((p) => _buildProdukCard(p)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final s = _summary!;
    return Column(
      children: [
        // Top row: pendapatan (full width)
        _SummaryCard(
          icon: Icons.payments_outlined,
          label: 'Total Pendapatan',
          value: 'Rp ${_fmt.format(s.totalPendapatan.toInt())}',
          color: AppColors.accent,
          fullWidth: true,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.inventory_2_outlined,
                label: 'Produk Terjual',
                value: '${s.totalProdukTerjual}',
                color: const Color(0xFF58A6FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: Icons.local_shipping_outlined,
                label: 'Unit Terjual',
                value: '${s.totalUnitTerjual}',
                color: const Color(0xFF3FB950),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                icon: Icons.receipt_long_outlined,
                label: 'Transaksi',
                value: '${s.totalTransaksi}',
                color: const Color(0xFFD29922),
              ),
            ),
          ],
        ),
        if (s.produkStokHabis > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.danger.withOpacity(0.30)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.produkStokHabis} produk stok habis — perlu restock segera',
                    style: GoogleFonts.dmSans(
                        fontSize: 12, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Produk card ───────────────────────────────────────────────────────────
  Widget _buildProdukCard(LaporanProduk p) {
    final pct = _summary != null && _summary!.totalPendapatan > 0
        ? p.totalPendapatan / _summary!.totalPendapatan
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(
          dividerColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(primary: AppColors.accent),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          childrenPadding: EdgeInsets.zero,
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textMuted,
          // ── Tile header ───────────────────────────────────────────────────
          title: Row(
            children: [
              // Foto / placeholder
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: p.foto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(p.foto!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                color: AppColors.textMuted)),
                      )
                    : const Icon(Icons.inventory_2_outlined,
                        color: AppColors.textMuted, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.namaProduk,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.kategori != null) ...[
                          _KategoriChip(p.kategori!),
                          const SizedBox(width: 6),
                        ],
                        _StokBadge(p.statusStok, p.stokSekarang),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.totalTerjual} unit',
                    style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent),
                  ),
                  Text(
                    'Rp ${_fmt.format(p.totalPendapatan.toInt())}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          // ── Expanded detail ───────────────────────────────────────────────
          children: [
            Container(
              color: AppColors.surface.withOpacity(0.5),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),

                  // Progress bar pendapatan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kontribusi Pendapatan',
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text('${(pct * 100).toStringAsFixed(1)}%',
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stat row
                  Row(
                    children: [
                      _StatTile(
                          label: 'Transaksi',
                          value: '${p.jumlahTransaksi}x',
                          icon: Icons.receipt_long_outlined),
                      const SizedBox(width: 12),
                      _StatTile(
                          label: 'Stok Sekarang',
                          value: '${p.stokSekarang}',
                          icon: Icons.warehouse_outlined),
                    ],
                  ),

                  // Varian breakdown
                  if (p.varianTerjual.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('Penjualan per Varian',
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    ...p.varianTerjual.map((v) => _VarianRow(
                          v: v,
                          fmt: _fmt,
                          maxTerjual: p.totalTerjual,
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error / empty ─────────────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('Belum ada produk terjual',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Coba ubah rentang tanggal atau hapus filter pencarian.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            if (_hasFilter)
              OutlinedButton(
                onPressed: _clearFilter,
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border)),
                child: Text('Reset Filter',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withOpacity(0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.accent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? AppColors.accent : AppColors.textMuted),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color:
                        active ? AppColors.accent : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(fullWidth ? 16 : 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: fullWidth
          ? Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(label,
                        style: GoogleFonts.dmSans(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(height: 8),
                Text(value,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
    );
  }
}

class _KategoriChip extends StatelessWidget {
  final String label;
  const _KategoriChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 10, color: AppColors.textSecondary)),
    );
  }
}

class _StokBadge extends StatelessWidget {
  final String status;
  final int stok;
  const _StokBadge(this.status, this.stok);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'habis'        => AppColors.danger,
      'hampir_habis' => AppColors.warning,
      _              => AppColors.success,
    };
    final label = switch (status) {
      'habis'        => 'Habis',
      'hampir_habis' => 'Sisa $stok',
      _              => 'Stok $stok',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VarianRow extends StatelessWidget {
  final VarianTerjual v;
  final NumberFormat fmt;
  final int maxTerjual;
  const _VarianRow(
      {required this.v, required this.fmt, required this.maxTerjual});

  @override
  Widget build(BuildContext context) {
    final pct = maxTerjual > 0 ? v.terjual / maxTerjual : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              v.labelVarian,
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accent.withOpacity(0.7)),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${v.terjual} unit · Rp ${fmt.format(v.pendapatan.toInt())}',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
