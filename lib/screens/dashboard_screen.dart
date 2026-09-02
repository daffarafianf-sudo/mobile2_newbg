import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topProducts = [
      Product(name: "Kemeja Flanel Premium", stock: 45, price: 189000, sold: 87),
      Product(name: "Hoodie Oversize", stock: 12, price: 249000, sold: 64),
      Product(name: "Celana Jeans Slim", stock: 78, price: 159000, sold: 51),
    ];

    final fmt = NumberFormat.decimalPattern('id');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Selamat datang,\n',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: 'Owner Hayki 👋',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Revenue card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E8), Color(0xFFFFF3D0), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'PENDAPATAN HARI INI',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Rp 4.820.000',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatBadge(
                      icon: Icons.shopping_bag_outlined,
                      label: '23 transaksi',
                    ),
                    const SizedBox(width: 12),
                    _StatBadge(
                      icon: Icons.people_outline_rounded,
                      label: '19 pelanggan',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Mini stats row
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'Total Stok',
                  value: '138',
                  unit: 'produk',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF58A6FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  title: 'Promo Aktif',
                  value: '2',
                  unit: 'promo',
                  icon: Icons.local_offer_outlined,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  title: 'Stok Rendah',
                  value: '3',
                  unit: 'item',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Top products header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produk Terlaris',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Lihat semua',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...topProducts.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return _ProductCard(
              rank: i + 1,
              name: p.name,
              sold: p.sold,
              price: 'Rp ${fmt.format(p.price)}',
            );
          }),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title, value, unit;
  final IconData icon;
  final Color color;
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final int rank;
  final String name, price;
  final int sold;
  const _ProductCard({
    required this.rank,
    required this.name,
    required this.sold,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final rankColors = [AppColors.accent, AppColors.textSecondary, const Color(0xFF8B6914)];
    final rankColor = rankColors[rank - 1];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Terjual $sold pcs',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
