import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/keuangan_model.dart';
import '../models/riwayat_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/donut_chart.dart';

class KeuanganScreen extends StatefulWidget {
  const KeuanganScreen({super.key});

  @override
  State<KeuanganScreen> createState() => _KeuanganScreenState();
}

class _KeuanganScreenState extends State<KeuanganScreen> {
  List<RiwayatItem> _riwayat = [];
  List<CashEntry> _manual = [];
  bool _loading = true;
  String? _error;

  bool _tabMasuk = true;
  int _period = 1; // 0: 7 hari, 1: 30 hari, 2: bulan ini, 3: semua
  String _groupMasuk = 'metode'; // 'metode' | 'kanal'
  int? _selected;

  static const _periodLabels = ['7 Hari', '30 Hari', 'Bulan Ini', 'Semua'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    _manual = await KeuanganService.loadManual();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await ApiService.getRiwayat(token, tipe: 'semua');
      if (res['success'] == true) {
        _riwayat = (res['data'] as List<dynamic>)
            .map((e) => RiwayatItem.fromJson(e))
            .toList();
      } else {
        _error = res['message']?.toString() ?? 'Gagal memuat transaksi';
      }
    } catch (e) {
      _error = 'Tidak dapat terhubung ke server';
    }
    if (mounted) setState(() => _loading = false);
  }

  bool _inPeriod(DateTime d) {
    final now = DateTime.now();
    switch (_period) {
      case 0:
        return d.isAfter(now.subtract(const Duration(days: 7)));
      case 1:
        return d.isAfter(now.subtract(const Duration(days: 30)));
      case 2:
        return d.year == now.year && d.month == now.month;
      default:
        return true;
    }
  }

  Future<void> _openAdd() async {
    final result = await showModalBottomSheet<CashEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEntrySheet(initialMasuk: _tabMasuk),
    );
    if (result != null) {
      setState(() => _manual = [..._manual, result]);
      await KeuanganService.saveManual(_manual);
    }
  }

  Future<void> _deleteManual(String id) async {
    setState(() => _manual = _manual.where((e) => e.id != id).toList());
    await KeuanganService.saveManual(_manual);
  }

  @override
  Widget build(BuildContext context) {
    final all = KeuanganService.merge(_riwayat, _manual)
        .where((e) => _inPeriod(e.tanggal))
        .toList();
    final masuk = all.where((e) => e.masuk).toList();
    final keluar = all.where((e) => !e.masuk).toList();
    final totalMasuk = masuk.fold<double>(0, (a, b) => a + b.jumlah);
    final totalKeluar = keluar.fold<double>(0, (a, b) => a + b.jumlah);
    final laba = totalMasuk - totalKeluar;

    final shown = _tabMasuk ? masuk : keluar;
    final slices = KeuanganService.group(
        shown, _tabMasuk ? _groupMasuk : 'kategori');
    final shownTotal = _tabMasuk ? totalMasuk : totalKeluar;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.accentLight,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text('Catat',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                children: [
                  if (_error != null) _notice(_error!),
                  _periodChips(),
                  const SizedBox(height: 16),
                  _heroCard(laba, totalMasuk, totalKeluar),
                  const SizedBox(height: 20),
                  _segment(),
                  const SizedBox(height: 16),
                  _chartCard(slices, shownTotal),
                  const SizedBox(height: 24),
                  Text(
                    _tabMasuk ? 'Riwayat Pemasukan' : 'Riwayat Pengeluaran',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  if (shown.isEmpty)
                    _empty()
                  else
                    ...shown.take(50).map(_tile),
                ],
              ),
            ),
    );
  }

  Widget _notice(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$msg. Menampilkan catatan manual saja.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.warning),
            ),
          ),
          GestureDetector(
            onTap: _load,
            child: Text('Coba lagi',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentDark)),
          ),
        ],
      ),
    );
  }

  Widget _periodChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _periodLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = _period == i;
          return GestureDetector(
            onTap: () => setState(() {
              _period = i;
              _selected = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.textPrimary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? AppColors.textPrimary : AppColors.border),
              ),
              child: Text(
                _periodLabels[i],
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.accentLight : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heroCard(double laba, double masuk, double keluar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1710), Color(0xFF3A2F17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3A2F17).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LABA BERSIH',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
              color: AppColors.accentLight.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              rupiah(laba),
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                  child: _heroStat(Icons.south_west_rounded, 'Pemasukan',
                      masuk, const Color(0xFF4ADE80))),
              const SizedBox(width: 12),
              Expanded(
                  child: _heroStat(Icons.north_east_rounded, 'Pengeluaran',
                      keluar, const Color(0xFFFF7A7A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String label, double v, Color c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: c),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: Colors.white70)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(rupiahCompact(v),
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment() {
    Widget item(String label, IconData icon, bool masuk, Color color) {
      final active = _tabMasuk == masuk;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _tabMasuk = masuk;
            _selected = null;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: active ? AppShadows.soft : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16, color: active ? color : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color:
                        active ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          item('Pemasukan', Icons.south_west_rounded, true, AppColors.success),
          item('Pengeluaran', Icons.north_east_rounded, false,
              AppColors.danger),
        ],
      ),
    );
  }

  Widget _chartCard(List<PieSlice> slices, double total) {
    final sel = (_selected != null && _selected! < slices.length)
        ? slices[_selected!]
        : null;
    final pct = (sel != null && total > 0)
        ? '${(sel.value / total * 100).toStringAsFixed(1)}%'
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _tabMasuk ? 'Sumber Pemasukan' : 'Alokasi Pengeluaran',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ),
              if (_tabMasuk) ...[
                _miniToggle('Metode', 'metode'),
                const SizedBox(width: 6),
                _miniToggle('Kanal', 'kanal'),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (slices.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.donut_large_rounded,
                        size: 48, color: AppColors.border),
                    const SizedBox(height: 10),
                    Text('Belum ada data pada periode ini',
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppColors.textMuted)),
                  ],
                ),
              ),
            )
          else ...[
            Center(
              child: DonutChart(
                slices: slices,
                selected: _selected,
                size: 210,
                centerLabel: sel != null ? '${sel.label} • $pct' : 'Total',
                centerValue:
                    sel != null ? rupiahCompact(sel.value) : rupiahCompact(total),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(slices.length, (i) {
              final s = slices[i];
              final p = total > 0 ? s.value / total : 0.0;
              final active = _selected == i;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selected = active ? null : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? s.color.withOpacity(0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: s.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(s.label,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                      Text(rupiah(s.value),
                          style: GoogleFonts.dmSans(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 46,
                        child: Text(
                          '${(p * 100).toStringAsFixed(1)}%',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _miniToggle(String label, String value) {
    final active = _groupMasuk == value;
    return GestureDetector(
      onTap: () => setState(() {
        _groupMasuk = value;
        _selected = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withOpacity(0.18) : AppColors.cardAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.accentDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 44, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            _tabMasuk
                ? 'Belum ada pemasukan pada periode ini'
                : 'Belum ada pengeluaran. Tekan "Catat" untuk menambah.',
            textAlign: TextAlign.center,
            style:
                GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _tile(ArusKas e) {
    final color = e.masuk ? AppColors.success : AppColors.danger;
    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              e.masuk ? Icons.south_west_rounded : Icons.north_east_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                  '${tanggalJam(e.tanggal)}  •  ${e.manual ? e.kategori : e.metode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${e.masuk ? '+' : '-'}${rupiah(e.jumlah)}',
            style: GoogleFonts.dmSans(
                fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );

    if (!e.manual) return card;
    return Dismissible(
      key: ValueKey(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteManual(e.id),
      child: card,
    );
  }
}

// ─── Form tambah catatan ──────────────────────────────────────────────────────

class _AddEntrySheet extends StatefulWidget {
  final bool initialMasuk;
  const _AddEntrySheet({required this.initialMasuk});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  late bool _masuk;
  late String _kategori;
  DateTime _tanggal = DateTime.now();
  final _jumlah = TextEditingController();
  final _catatan = TextEditingController();

  @override
  void initState() {
    super.initState();
    _masuk = widget.initialMasuk;
    _kategori = _kategoriList.first;
  }

  @override
  void dispose() {
    _jumlah.dispose();
    _catatan.dispose();
    super.dispose();
  }

  List<String> get _kategoriList => _masuk
      ? KeuanganService.kategoriMasuk
      : KeuanganService.kategoriKeluar;

  double get _nilai => double.tryParse(_jumlah.text) ?? 0;

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d != null) setState(() => _tanggal = d);
  }

  void _simpan() {
    if (_nilai <= 0) return;
    Navigator.pop(
      context,
      CashEntry(
        id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
        masuk: _masuk,
        kategori: _kategori,
        jumlah: _nilai,
        catatan: _catatan.text.trim(),
        tanggal: _tanggal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _masuk ? AppColors.success : AppColors.danger;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Catat Transaksi',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _toggle('Pemasukan', true, AppColors.success),
                    _toggle('Pengeluaran', false, AppColors.danger),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _jumlah,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                  helperText: _nilai > 0 ? rupiah(_nilai) : null,
                ),
              ),
              const SizedBox(height: 16),
              Text('Kategori',
                  style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kategoriList.map((k) {
                  final active = k == _kategori;
                  return GestureDetector(
                    onTap: () => setState(() => _kategori = k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? accent.withOpacity(0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: active ? accent : AppColors.border),
                      ),
                      child: Text(k,
                          style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? accent : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _catatan,
                style: GoogleFonts.dmSans(
                    fontSize: 14, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Text(tanggalPendek(_tanggal),
                          style: GoogleFonts.dmSans(
                              fontSize: 14, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nilai > 0 ? _simpan : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: AppColors.accentLight,
                    disabledBackgroundColor: AppColors.border,
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toggle(String label, bool masuk, Color color) {
    final active = _masuk == masuk;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _masuk = masuk;
          _kategori = _kategoriList.first;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active ? AppShadows.soft : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? color : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
