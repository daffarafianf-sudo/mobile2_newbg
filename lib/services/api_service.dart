import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ── Auth ─────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );
    return jsonDecode(response.body);
  }

  // ── Transaksi ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getTransaksi(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/transaksi'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  // ── Riwayat ───────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getRiwayat(
    String token, {
    String tipe = 'semua',
    String? dari,
    String? sampai,
    String? q,
  }) async {
    final params = <String, String>{'tipe': tipe};
    if (dari != null) params['dari'] = dari;
    if (sampai != null) params['sampai'] = sampai;
    if (q != null && q.isNotEmpty) params['q'] = q;

    final uri = Uri.parse('$baseUrl/riwayat').replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRiwayatDetailPesanan(
      String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/riwayat/pesanan/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRiwayatDetailTransaksi(
      String token, int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/riwayat/transaksi/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }
  // ── Stok ──────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStok(
    String token, {
    String? filter, // 'habis' | 'hampir_habis' | 'aman'
    String? q,
  }) async {
    final params = <String, String>{};
    if (filter != null && filter.isNotEmpty) params['filter'] = filter;
    if (q != null && q.isNotEmpty) params['q'] = q;

    final uri = Uri.parse('$baseUrl/stok').replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> tambahStok(
    String token,
    int varianId,
    int jumlah,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/stok/$varianId/tambah'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {'jumlah': jumlah.toString()},
    );
    return jsonDecode(response.body);
  }

  // ── Promo ─────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPromos(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/promo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  // ── Promo: karyawan ajukan promo baru ─────────────────────────────────────────
  static Future<Map<String, dynamic>> ajukanPromo(
    String token, {
    required String namaPromo,
    String? deskripsi,
    required double diskon,
    required String tipeDiskon,
    double minPembelian = 0,
    required String tanggalMulai,
    required String tanggalSelesai,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/promo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: {
        'nama_promo': namaPromo,
        if (deskripsi != null && deskripsi.isNotEmpty) 'deskripsi': deskripsi,
        'diskon': diskon.toString(),
        'tipe_diskon': tipeDiskon,
        'min_pembelian': minPembelian.toString(),
        'tanggal_mulai': tanggalMulai,
        'tanggal_selesai': tanggalSelesai,
      },
    );
    return jsonDecode(response.body);
  }

  // ── Promo: pemilik setujui ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> approvePromo(
      String token, int promoId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/promo/$promoId/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  // ── Promo: pemilik tolak ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> rejectPromo(
      String token, int promoId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/promo/$promoId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  // ── Laporan Produk Terjual ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getLaporanProduk(
    String token, {
    String? dari,
    String? sampai,
    String? q,
    String sort = 'terjual_desc',
  }) async {
    final params = <String, String>{'sort': sort};
    if (dari != null && dari.isNotEmpty) params['dari'] = dari;
    if (sampai != null && sampai.isNotEmpty) params['sampai'] = sampai;
    if (q != null && q.isNotEmpty) params['q'] = q;

    final uri =
        Uri.parse('$baseUrl/laporan/produk').replace(queryParameters: params);
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }
}
