import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'riwayat_model.dart';

/// Catatan manual (pemasukan lain / pengeluaran) yang disimpan di perangkat.
class CashEntry {
  final String id;
  final bool masuk;
  final String kategori;
  final double jumlah;
  final String catatan;
  final DateTime tanggal;

  CashEntry({
    required this.id,
    required this.masuk,
    required this.kategori,
    required this.jumlah,
    required this.catatan,
    required this.tanggal,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'masuk': masuk,
        'kategori': kategori,
        'jumlah': jumlah,
        'catatan': catatan,
        'tanggal': tanggal.toIso8601String(),
      };

  factory CashEntry.fromJson(Map<String, dynamic> j) => CashEntry(
        id: j['id'].toString(),
        masuk: j['masuk'] == true,
        kategori: j['kategori']?.toString() ?? 'Lainnya',
        jumlah: (j['jumlah'] as num).toDouble(),
        catatan: j['catatan']?.toString() ?? '',
        tanggal: DateTime.parse(j['tanggal'].toString()),
      );
}

/// Satu baris arus kas gabungan (transaksi penjualan + catatan manual).
class ArusKas {
  final String id;
  final bool masuk;
  final String judul;
  final String subjudul;
  final String metode; // dipakai untuk pengelompokan pemasukan
  final String kanal; // Online / Offline / Lainnya
  final String kategori; // dipakai untuk pengelompokan pengeluaran
  final double jumlah;
  final DateTime tanggal;
  final bool manual;

  ArusKas({
    required this.id,
    required this.masuk,
    required this.judul,
    required this.subjudul,
    required this.metode,
    required this.kanal,
    required this.kategori,
    required this.jumlah,
    required this.tanggal,
    required this.manual,
  });
}

class PieSlice {
  final String label;
  final double value;
  final Color color;
  const PieSlice(this.label, this.value, this.color);
}

class KeuanganService {
  static const _key = 'keuangan_manual_v1';

  static const kategoriKeluar = [
    'Restock Barang',
    'Gaji Karyawan',
    'Sewa Tempat',
    'Listrik & Air',
    'Promosi & Iklan',
    'Operasional',
    'Lainnya',
  ];

  static const kategoriMasuk = ['Modal Tambahan', 'Pemasukan Lain'];

  static const palette = <Color>[
    Color(0xFFD4A853),
    Color(0xFF2E9E3F),
    Color(0xFF3B82F6),
    Color(0xFFE5484D),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF64748B),
  ];

  static Future<List<CashEntry>> loadManual() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CashEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveManual(List<CashEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static String _cap(String s) {
    if (s.isEmpty || s == '-') return 'Lainnya';
    return s[0].toUpperCase() + s.substring(1);
  }

  /// Gabungkan transaksi selesai + catatan manual, terbaru di atas.
  static List<ArusKas> merge(
      List<RiwayatItem> riwayat, List<CashEntry> manual) {
    final out = <ArusKas>[];
    for (final r in riwayat) {
      if (!r.isSelesai) continue;
      out.add(ArusKas(
        id: 'trx_${r.tipe}_${r.id}',
        masuk: true,
        judul: r.kode,
        subjudul: r.itemsPreview.isNotEmpty
            ? r.itemsPreview
            : (r.pembeli ?? 'Penjualan'),
        metode: _cap(r.metodeBayar),
        kanal: r.isOnline ? 'Online' : 'Offline',
        kategori: 'Penjualan',
        jumlah: r.total,
        tanggal: r.createdAt,
        manual: false,
      ));
    }
    for (final m in manual) {
      out.add(ArusKas(
        id: m.id,
        masuk: m.masuk,
        judul: m.catatan.isNotEmpty ? m.catatan : m.kategori,
        subjudul: m.kategori,
        metode: m.kategori,
        kanal: 'Lainnya',
        kategori: m.kategori,
        jumlah: m.jumlah,
        tanggal: m.tanggal,
        manual: true,
      ));
    }
    out.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return out;
  }

  /// [mode]: 'metode' | 'kanal' (pemasukan) atau 'kategori' (pengeluaran).
  static List<PieSlice> group(List<ArusKas> items, String mode) {
    final map = <String, double>{};
    for (final it in items) {
      final key = mode == 'metode'
          ? it.metode
          : mode == 'kanal'
              ? it.kanal
              : it.kategori;
      map[key] = (map[key] ?? 0) + it.jumlah;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slices = <PieSlice>[];
    for (var i = 0; i < entries.length; i++) {
      slices.add(PieSlice(
          entries[i].key, entries[i].value, palette[i % palette.length]));
    }
    return slices;
  }
}
