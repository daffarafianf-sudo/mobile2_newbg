class VarianStok {
  final int id;
  final String label;
  final String? warna;
  final String? size;
  final double harga;
  int stok;
  final String? sku;
  String? tanggalRestok;

  VarianStok({
    required this.id,
    required this.label,
    this.warna,
    this.size,
    required this.harga,
    required this.stok,
    this.sku,
    this.tanggalRestok,
  });

  factory VarianStok.fromJson(Map<String, dynamic> json) {
    return VarianStok(
      id: json['id'] as int,
      label: (json['label'] ?? '').toString(),
      warna: json['warna']?.toString(),
      size: json['size']?.toString(),
      harga: (json['harga'] as num).toDouble(),
      stok: json['stok'] as int,
      sku: json['sku']?.toString(),
      tanggalRestok: json['tanggal_restok']?.toString(),
    );
  }
}

class StokProduk {
  final int id;
  final String namaProduk;
  final String? kategori;
  final String? foto;
  int totalStok;
  final double? hargaMin;
  String statusStok; // 'habis' | 'hampir_habis' | 'aman'
  final List<VarianStok> varians;

  StokProduk({
    required this.id,
    required this.namaProduk,
    this.kategori,
    this.foto,
    required this.totalStok,
    this.hargaMin,
    required this.statusStok,
    required this.varians,
  });

  factory StokProduk.fromJson(Map<String, dynamic> json) {
    return StokProduk(
      id: json['id'] as int,
      namaProduk: json['nama_produk'].toString(),
      kategori: json['kategori']?.toString(),
      foto: json['foto']?.toString(),
      totalStok: json['total_stok'] as int,
      hargaMin: json['harga_min'] != null
          ? (json['harga_min'] as num).toDouble()
          : null,
      statusStok: json['status_stok'].toString(),
      varians: (json['varians'] as List<dynamic>)
          .map((v) => VarianStok.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StokSummary {
  final int totalProduk;
  final int stokHabis;
  final int hampirHabis;
  final int totalStok;

  StokSummary({
    required this.totalProduk,
    required this.stokHabis,
    required this.hampirHabis,
    required this.totalStok,
  });

  factory StokSummary.fromJson(Map<String, dynamic> json) {
    return StokSummary(
      totalProduk: json['total_produk'] as int,
      stokHabis: json['stok_habis'] as int,
      hampirHabis: json['hampir_habis'] as int,
      totalStok: json['total_stok'] as int,
    );
  }
}
