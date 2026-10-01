import 'package:intl/intl.dart';

final NumberFormat _nf = NumberFormat.decimalPattern('id');

String rupiah(num v) => 'Rp ${_nf.format(v.round())}';

String rupiahCompact(num v) {
  final a = v.abs();
  final sign = v < 0 ? '-' : '';
  if (a >= 1000000000) return '${sign}Rp ${(a / 1000000000).toStringAsFixed(1)} M';
  if (a >= 1000000) return '${sign}Rp ${(a / 1000000).toStringAsFixed(1)} jt';
  if (a >= 1000) return '${sign}Rp ${(a / 1000).toStringAsFixed(0)} rb';
  return '${sign}Rp ${a.round()}';
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

String tanggalPendek(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String tanggalJam(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_bulan[d.month - 1]} • $h:$m';
}
