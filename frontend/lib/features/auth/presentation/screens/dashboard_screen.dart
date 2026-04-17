import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_service.dart';
import '../../../products/presentation/providers/product_provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _summary;
  List<dynamic> _topProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final db = await DatabaseService().database;

      // Summary hari ini — langsung dari SQLite lokal
      final summaryRes = await db.rawQuery("""
        SELECT
          SUM(total)    as total_revenue,
          COUNT(id)     as total_transactions,
          SUM(tax)      as total_tax,
          SUM(discount) as total_discount
        FROM transactions
        WHERE date(created_at) = date('now')
      """);

      // Top produk bulan ini — langsung dari SQLite lokal
      final topRes = await db.rawQuery("""
        SELECT d.product_id, d.name as product_name,
               SUM(d.quantity) as total_qty,
               SUM(d.subtotal) as total_revenue
        FROM transaction_details d
        JOIN transactions t ON t.id = d.transaction_id
        WHERE strftime('%Y-%m', t.created_at) = strftime('%Y-%m', 'now')
        GROUP BY d.product_id, d.name
        ORDER BY total_qty DESC
        LIMIT 5
      """);

      if (!mounted) return;
      await context.read<ProductProvider>().fetchLowStock();

      setState(() {
        _summary     = Map<String, dynamic>.from(summaryRes.first);
        _topProducts = topRes;
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dashboard',
                                style: GoogleFonts.inter(
                                  fontSize:   24,
                                  fontWeight: FontWeight.w700,
                                  color:      AppColors.textPrimary,
                                )),
                            Text(
                              DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now()),
                              style: GoogleFonts.inter(
                                  fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Summary cards
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing:  12,
                      childAspectRatio: 1.5,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _SummaryCard(
                          title: 'Pendapatan Hari Ini',
                          value: fmt.format(_summary?['total_revenue'] ?? 0),
                          icon:  Icons.trending_up_rounded,
                          color: AppColors.primary,
                        ),
                        _SummaryCard(
                          title: 'Transaksi Hari Ini',
                          value: '${_summary?['total_transactions'] ?? 0}',
                          icon:  Icons.receipt_long_rounded,
                          color: AppColors.success,
                        ),
                        _SummaryCard(
                          title: 'Total Pajak',
                          value: fmt.format(_summary?['total_tax'] ?? 0),
                          icon:  Icons.percent_rounded,
                          color: AppColors.warning,
                        ),
                        _SummaryCard(
                          title: 'Total Diskon',
                          value: fmt.format(_summary?['total_discount'] ?? 0),
                          icon:  Icons.local_offer_rounded,
                          color: AppColors.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Low stock alert
                    Consumer<ProductProvider>(
                      builder: (_, p, __) => p.lowStock.isEmpty
                          ? const SizedBox.shrink()
                          : _LowStockAlert(items: p.lowStock),
                    ),

                    const SizedBox(height: 24),

                    // Top products
                    Text('Produk Terlaris (Bulan Ini)',
                        style: GoogleFonts.inter(
                          fontSize:   16,
                          fontWeight: FontWeight.w600,
                          color:      AppColors.textPrimary,
                        )),
                    const SizedBox(height: 12),
                    ..._topProducts.take(5).map((p) => _TopProductRow(
                          name:    p['product_name'] as String,
                          qty:     (p['total_qty'] as num).toInt(),
                          revenue: fmt.format(p['total_revenue']),
                        )),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value,
              style: GoogleFonts.inter(
                fontSize:   18,
                fontWeight: FontWeight.w700,
                color:      AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.inter(
                fontSize: 11,
                color:    AppColors.textSecondary,
              ),
              maxLines: 2),
        ],
      ),
    );
  }
}

class _LowStockAlert extends StatelessWidget {
  final List items;
  const _LowStockAlert({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.warning.withOpacity(0.1),
        border:       Border.all(color: AppColors.warning.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('Stok Menipis (${items.length} produk)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color:      AppColors.warning,
                )),
          ]),
          const SizedBox(height: 8),
          ...items.take(3).map((p) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child:   Text('• ${p.name} — sisa ${p.stock}',
                    style: GoogleFonts.inter(fontSize: 13)),
              )),
        ],
      ),
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final String name;
  final int    qty;
  final String revenue;
  const _TopProductRow(
      {required this.name, required this.qty, required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
            child: Text(name,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize:   14))),
        Text('$qty terjual  ',
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 13)),
        Text(revenue,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color:      AppColors.primary,
                fontSize:   13)),
      ]),
    );
  }
}