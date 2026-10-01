import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/promo.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  List<Promo> promos = [];
  bool isLoading = true;
  String _role = '';
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _role = prefs.getString('role') ?? '';
    await _fetchPromos();
  }

  Future<void> _fetchPromos() async {
    setState(() => isLoading = true);
    try {
      final result = await ApiService.getPromos(_token);
      if (result['success'] == true) {
        setState(() {
          promos = (result['data'] as List)
              .map((e) => Promo.fromJson(e))
              .toList();
        });
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? 'Gagal memuat promo');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Koneksi gagal');
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _approve(Promo promo) async {
    try {
      final result = await ApiService.approvePromo(_token, promo.id);
      if (result['success'] == true) {
        setState(() => promo.status = 'aktif');
        Fluttertoast.showToast(msg: 'Promo disetujui ✅');
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? 'Gagal menyetujui');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Koneksi gagal');
    }
  }

  Future<void> _reject(Promo promo) async {
    try {
      final result = await ApiService.rejectPromo(_token, promo.id);
      if (result['success'] == true) {
        setState(() => promo.status = 'ditolak');
        Fluttertoast.showToast(msg: 'Promo ditolak ❌');
      } else {
        Fluttertoast.showToast(msg: result['message'] ?? 'Gagal menolak');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Koneksi gagal');
    }
  }

  void _showAjukanBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AjukanPromoSheet(
        token: _token,
        onSuccess: _fetchPromos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPemilik = _role == 'pemilik';
    final pending = promos.where((p) => p.status == 'pending').length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Banner notifikasi pending
          if (pending > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_actions_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    isPemilik
                        ? '$pending promo menunggu persetujuan Anda'
                        : '$pending promo sedang menunggu persetujuan',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // List promo
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent))
                : promos.isEmpty
                    ? _EmptyState(
                        isKaryawan: !isPemilik,
                        onAjukan: _showAjukanBottomSheet,
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPromos,
                        color: AppColors.accent,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 12, 20, 100),
                          itemCount: promos.length,
                          itemBuilder: (context, i) {
                            final p = promos[i];
                            return _PromoCard(
                              promo: p,
                              isPemilik: isPemilik,
                              onApprove: () => _approve(p),
                              onReject: () => _reject(p),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      // FAB hanya untuk karyawan
      floatingActionButton: (!isPemilik)
          ? FloatingActionButton.extended(
              onPressed: _showAjukanBottomSheet,
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Ajukan Promo',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isKaryawan;
  final VoidCallback onAjukan;
  const _EmptyState({required this.isKaryawan, required this.onAjukan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                const Icon(Icons.local_offer_rounded, size: 36, color: Colors.black),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada promo',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isKaryawan
                ? 'Tap tombol di bawah untuk mengajukan\npromo kepada pemilik toko'
                : 'Promo yang diajukan karyawan\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (isKaryawan) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAjukan,
              icon: const Icon(Icons.add_rounded, color: Colors.black),
              label: Text('Ajukan Promo',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, color: Colors.black)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Promo card ────────────────────────────────────────────────────────────────
class _PromoCard extends StatelessWidget {
  final Promo promo;
  final bool isPemilik;
  final VoidCallback onApprove, onReject;

  const _PromoCard({
    required this.promo,
    required this.isPemilik,
    required this.onApprove,
    required this.onReject,
  });

  Color get _statusColor {
    switch (promo.status) {
      case 'aktif':
        return AppColors.success;
      case 'ditolak':
        return AppColors.danger;
      default:
        return AppColors.warning; // pending
    }
  }

  String get _statusLabel {
    switch (promo.status) {
      case 'aktif':
        return 'AKTIF';
      case 'ditolak':
        return 'DITOLAK';
      case 'nonaktif':
        return 'NONAKTIF';
      default:
        return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = promo.status == 'pending';
    final fmt = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header gradien
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _statusColor.withOpacity(0.12),
                  Colors.transparent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge diskon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    promo.labelDiskon,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: promo.tipeDiskon == 'persen' ? 15 : 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.namaPromo,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (promo.namaKaryawan != null)
                        Text(
                          'Diajukan oleh: ${promo.namaKaryawan}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                // Badge status
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    _statusLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info tanggal & min pembelian
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      '${fmt.format(promo.tanggalMulai)} — ${fmt.format(promo.tanggalSelesai)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (promo.minPembelian > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Min. pembelian: Rp ${NumberFormat('#,###', 'id_ID').format(promo.minPembelian)}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (promo.deskripsi != null &&
                    promo.deskripsi!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    promo.deskripsi!,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tombol approve/reject — hanya pemilik & hanya saat pending
          if (isPemilik && isPending) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(
                        'Tolak',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check_rounded,
                          size: 16, color: Colors.black),
                      label: Text(
                        'Setujui',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Info siapa yang menyetujui/menolak
          if (!isPending && promo.namaPenyetuju != null) ...[
            const Divider(color: AppColors.border, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    promo.status == 'aktif'
                        ? Icons.verified_outlined
                        : Icons.cancel_outlined,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${promo.status == 'aktif' ? 'Disetujui' : 'Ditolak'} oleh: ${promo.namaPenyetuju}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom sheet form ajukan promo ────────────────────────────────────────────
class _AjukanPromoSheet extends StatefulWidget {
  final String token;
  final VoidCallback onSuccess;
  const _AjukanPromoSheet(
      {required this.token, required this.onSuccess});

  @override
  State<_AjukanPromoSheet> createState() => _AjukanPromoSheetState();
}

class _AjukanPromoSheetState extends State<_AjukanPromoSheet> {
  final _namaCtrl = TextEditingController();
  final _deskCtrl = TextEditingController();
  final _diskonCtrl = TextEditingController();
  final _minCtrl = TextEditingController(text: '0');

  String _tipeDiskon = 'persen';
  DateTime? _mulai;
  DateTime? _selesai;
  bool _isLoading = false;

  Future<void> _pickDate(bool isMulai) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.black,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _mulai = picked;
        } else {
          _selesai = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_namaCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Nama promo wajib diisi');
      return;
    }
    if (_diskonCtrl.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Nilai diskon wajib diisi');
      return;
    }
    if (_mulai == null || _selesai == null) {
      Fluttertoast.showToast(msg: 'Tanggal mulai & selesai wajib diisi');
      return;
    }
    if (_selesai!.isBefore(_mulai!)) {
      Fluttertoast.showToast(
          msg: 'Tanggal selesai harus setelah tanggal mulai');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.ajukanPromo(
        widget.token,
        namaPromo: _namaCtrl.text.trim(),
        deskripsi: _deskCtrl.text.trim(),
        diskon: double.tryParse(_diskonCtrl.text) ?? 0,
        tipeDiskon: _tipeDiskon,
        minPembelian: double.tryParse(_minCtrl.text) ?? 0,
        tanggalMulai:
            DateFormat('yyyy-MM-dd').format(_mulai!),
        tanggalSelesai:
            DateFormat('yyyy-MM-dd').format(_selesai!),
      );

      if (result['success'] == true) {
        Fluttertoast.showToast(
            msg: 'Promo berhasil diajukan, menunggu persetujuan pemilik 🎉');
        if (mounted) Navigator.pop(context);
        widget.onSuccess();
      } else {
        Fluttertoast.showToast(
            msg: result['message'] ?? 'Gagal mengajukan promo');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Koneksi gagal');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Ajukan Promo',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Promo akan dikirim ke pemilik untuk disetujui',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            _label('Nama Promo *'),
            const SizedBox(height: 8),
            TextField(
              controller: _namaCtrl,
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: _inputDeco('cth. Diskon Lebaran 20%'),
            ),
            const SizedBox(height: 16),

            _label('Deskripsi'),
            const SizedBox(height: 8),
            TextField(
              controller: _deskCtrl,
              maxLines: 2,
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: _inputDeco('Keterangan singkat promo...'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Nilai Diskon *'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _diskonCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'))
                        ],
                        style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: _inputDeco(
                            _tipeDiskon == 'persen' ? '0–100' : '10000'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Tipe Diskon *'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _tipeDiskon,
                        dropdownColor: AppColors.card,
                        style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: _inputDeco('').copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'persen', child: Text('Persen (%)')),
                          DropdownMenuItem(
                              value: 'nominal',
                              child: Text('Nominal (Rp)')),
                        ],
                        onChanged: (v) =>
                            setState(() => _tipeDiskon = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _label('Min. Pembelian (Rp)'),
            const SizedBox(height: 8),
            TextField(
              controller: _minCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly
              ],
              style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: _inputDeco('0 = tidak ada minimum'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Tanggal Mulai *'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickDate(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border), boxShadow: AppShadows.soft,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                _mulai != null
                                    ? fmt.format(_mulai!)
                                    : 'Pilih tanggal',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: _mulai != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Tanggal Selesai *'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickDate(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border), boxShadow: AppShadows.soft,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Text(
                                _selesai != null
                                    ? fmt.format(_selesai!)
                                    : 'Pilih tanggal',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: _selesai != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.black),
                      )
                    : Text(
                        'KIRIM PENGAJUAN',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle:
            GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}