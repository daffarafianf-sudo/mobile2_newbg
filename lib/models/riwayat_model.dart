class RiwayatItem {
  final int id;
  final String tipe; // 'online' | 'offline'
  final String kode;
  final String? pembeli;
  final String? kasir;
  final double total;
  final double subtotal;
  final double diskon;
  final String status;
  final String statusLabel;
  final String metodeBayar;
  final String? promo;
  final DateTime createdAt;
  final int itemsCount;
  final String itemsPreview;

  RiwayatItem({
    required this.id,
    required this.tipe,
    required this.kode,
    this.pembeli,
    this.kasir,
    required this.total,
    required this.subtotal,
    required this.diskon,
    required this.status,
    required this.statusLabel,
    required this.metodeBayar,
    this.promo,
    required this.createdAt,
    required this.itemsCount,
    required this.itemsPreview,
  });

  factory RiwayatItem.fromJson(Map<String, dynamic> json) {
    return RiwayatItem(
      id: json['id'],
      tipe: json['tipe'] ?? 'offline',
      kode: json['kode'] ?? '',
      pembeli: json['pembeli'],
      kasir: json['kasir'],
      total: (json['total'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      diskon: (json['diskon'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      statusLabel: json['status_label'] ?? '',
      metodeBayar: json['metode_bayar'] ?? '-',
      promo: json['promo'],
      createdAt: DateTime.parse(json['created_at']),
      itemsCount: json['items_count'] ?? 0,
      itemsPreview: json['items_preview'] ?? '',
    );
  }

  bool get isOnline => tipe == 'online';
  bool get isSelesai => status == 'selesai';
  bool get isDibatalkan => status == 'dibatalkan';
}

class RiwayatItemDetail extends RiwayatItem {
  final List<RiwayatItemLine> items;

  // Offline specific
  final double uangDiterima;
  final double kembalian;
  final String? catatan;

  // Online specific
  final RiwayatPembayaran? pembayaran;

  RiwayatItemDetail({
    required super.id,
    required super.tipe,
    required super.kode,
    super.pembeli,
    super.kasir,
    required super.total,
    required super.subtotal,
    required super.diskon,
    required super.status,
    required super.statusLabel,
    required super.metodeBayar,
    super.promo,
    required super.createdAt,
    required super.itemsCount,
    required super.itemsPreview,
    required this.items,
    this.uangDiterima = 0,
    this.kembalian = 0,
    this.catatan,
    this.pembayaran,
  });

  factory RiwayatItemDetail.fromJson(Map<String, dynamic> json) {
    final base = RiwayatItem.fromJson(json);
    return RiwayatItemDetail(
      id: base.id,
      tipe: base.tipe,
      kode: base.kode,
      pembeli: base.pembeli,
      kasir: base.kasir,
      total: base.total,
      subtotal: base.subtotal,
      diskon: base.diskon,
      status: base.status,
      statusLabel: base.statusLabel,
      metodeBayar: base.metodeBayar,
      promo: base.promo,
      createdAt: base.createdAt,
      itemsCount: base.itemsCount,
      itemsPreview: base.itemsPreview,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => RiwayatItemLine.fromJson(i))
          .toList(),
      uangDiterima: (json['uang_diterima'] ?? 0).toDouble(),
      kembalian: (json['kembalian'] ?? 0).toDouble(),
      catatan: json['catatan'],
      pembayaran: json['pembayaran'] != null
          ? RiwayatPembayaran.fromJson(json['pembayaran'])
          : null,
    );
  }
}

class RiwayatItemLine {
  final String namaProduk;
  final String varian;
  final int jumlah;
  final double harga;
  final double subtotal;
  final String? foto;

  RiwayatItemLine({
    required this.namaProduk,
    required this.varian,
    required this.jumlah,
    required this.harga,
    required this.subtotal,
    this.foto,
  });

  factory RiwayatItemLine.fromJson(Map<String, dynamic> json) {
    return RiwayatItemLine(
      namaProduk: json['nama_produk'] ?? '',
      varian: json['varian'] ?? 'Default',
      jumlah: json['jumlah'] ?? 1,
      harga: (json['harga'] ?? 0).toDouble(),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      foto: json['foto'],
    );
  }
}

class RiwayatPembayaran {
  final String metode;
  final String status;
  final String statusLabel;
  final double jumlahBayar;
  final String? tanggalBayar;
  final String? buktiPembayaran;

  RiwayatPembayaran({
    required this.metode,
    required this.status,
    required this.statusLabel,
    required this.jumlahBayar,
    this.tanggalBayar,
    this.buktiPembayaran,
  });

  factory RiwayatPembayaran.fromJson(Map<String, dynamic> json) {
    return RiwayatPembayaran(
      metode: json['metode'] ?? '-',
      status: json['status'] ?? '',
      statusLabel: json['status_label'] ?? '',
      jumlahBayar: (json['jumlah_bayar'] ?? 0).toDouble(),
      tanggalBayar: json['tanggal_bayar'],
      buktiPembayaran: json['bukti_pembayaran'],
    );
  }
}
