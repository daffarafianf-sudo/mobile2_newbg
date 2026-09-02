class Promo {
  final int id;
  final String namaPromo;
  final String? deskripsi;
  final double diskon;
  final String tipeDiskon;
  final double minPembelian;
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  String status;
  final int diajukanOleh;
  final int? disetujuiOleh;
  final String? namaKaryawan;
  final String? namaPenyetuju;
  final String? foto;

  Promo({
    required this.id,
    required this.namaPromo,
    this.deskripsi,
    required this.diskon,
    required this.tipeDiskon,
    required this.minPembelian,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.status,
    required this.diajukanOleh,
    this.disetujuiOleh,
    this.namaKaryawan,
    this.namaPenyetuju,
    this.foto,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json['id'],
      namaPromo: json['nama_promo'] ?? '',
      deskripsi: json['deskripsi'],
      diskon: double.tryParse(json['diskon'].toString()) ?? 0,
      tipeDiskon: json['tipe_diskon'] ?? 'persen',
      minPembelian: double.tryParse(json['min_pembelian'].toString()) ?? 0,
      tanggalMulai: DateTime.parse(json['tanggal_mulai']),
      tanggalSelesai: DateTime.parse(json['tanggal_selesai']),
      status: json['status'] ?? 'pending',
      diajukanOleh: json['diajukan_oleh'],
      disetujuiOleh: json['disetujui_oleh'],
      namaKaryawan: json['pengaju']?['nama'],
      namaPenyetuju: json['penyetuju']?['nama'],
      foto: json['foto'],
    );
  }

  String get labelDiskon =>
      tipeDiskon == 'persen' ? '${diskon.toStringAsFixed(0)}%' : 'Rp ${diskon.toStringAsFixed(0)}';
}