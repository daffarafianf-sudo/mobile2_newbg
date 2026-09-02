/// Model untuk fitur Laporan Produk Terjual
/// Endpoint: GET /api/laporan/produk

class VarianTerjual {
  final int varianId;
  final String labelVarian;
  final int terjual;
  final double pendapatan;

  VarianTerjual({
    required this.varianId,
    required this.labelVarian,
    required this.terjual,
    required this.pendapatan,
  });

  factory VarianTerjual.fromJson(Map<String, dynamic> json) {
    return VarianTerjual(
      varianId: json['varian_id'] as int,
      labelVarian: json['label_varian']?.toString() ?? 'Default',
      terjual: (json['terjual'] as num).toInt(),
      pendapatan: (json['pendapatan'] as num).toDouble(),
    );
  }
}

class LaporanProduk {
  final int produkId;
  final String namaProduk;
  final String? kategori;
  final String? foto;
  final int totalTerjual;
  final double totalPendapatan;
  final int jumlahTransaksi;
  final int stokSekarang;
  final String statusStok; // 'habis' | 'hampir_habis' | 'aman'
  final List<VarianTerjual> varianTerjual;

  LaporanProduk({
    required this.produkId,
    required this.namaProduk,
    this.kategori,
    this.foto,
    required this.totalTerjual,
    required this.totalPendapatan,
    required this.jumlahTransaksi,
    required this.stokSekarang,
    required this.statusStok,
    required this.varianTerjual,
  });

  factory LaporanProduk.fromJson(Map<String, dynamic> json) {
    return LaporanProduk(
      produkId: json['produk_id'] as int,
      namaProduk: json['nama_produk']?.toString() ?? '',
      kategori: json['kategori']?.toString(),
      foto: json['foto']?.toString(),
      totalTerjual: (json['total_terjual'] as num).toInt(),
      totalPendapatan: (json['total_pendapatan'] as num).toDouble(),
      jumlahTransaksi: (json['jumlah_transaksi'] as num).toInt(),
      stokSekarang: (json['stok_sekarang'] as num).toInt(),
      statusStok: json['status_stok']?.toString() ?? 'aman',
      varianTerjual: (json['varian_terjual'] as List<dynamic>? ?? [])
          .map((v) => VarianTerjual.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LaporanSummary {
  final int totalProdukTerjual;
  final int totalUnitTerjual;
  final double totalPendapatan;
  final int totalTransaksi;
  final int produkStokHabis;

  LaporanSummary({
    required this.totalProdukTerjual,
    required this.totalUnitTerjual,
    required this.totalPendapatan,
    required this.totalTransaksi,
    required this.produkStokHabis,
  });

  factory LaporanSummary.fromJson(Map<String, dynamic> json) {
    return LaporanSummary(
      totalProdukTerjual: (json['total_produk_terjual'] as num).toInt(),
      totalUnitTerjual: (json['total_unit_terjual'] as num).toInt(),
      totalPendapatan: (json['total_pendapatan'] as num).toDouble(),
      totalTransaksi: (json['total_transaksi'] as num).toInt(),
      produkStokHabis: (json['produk_stok_habis'] as num).toInt(),
    );
  }
}
