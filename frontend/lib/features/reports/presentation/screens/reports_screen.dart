import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _period       = 'daily';
  Map<String, dynamic>? _summary;
  List<dynamic>  _topProducts = [];
  bool   _loading      = true;
  bool   _exporting    = false;

  final _fmt = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final db = await DatabaseService().database;
      
      String dateCondition;
      if (_period == 'daily') {
        dateCondition = "date(t.created_at) = date('now', 'localtime')";
      } else if (_period == 'weekly') {
        dateCondition = "date(t.created_at) >= date('now', '-7 days', 'localtime')";
      } else {
        dateCondition = "strftime('%Y-%m', t.created_at) = strftime('%Y-%m', 'now', 'localtime')";
      }

      final summaryRes = await db.rawQuery('''
        SELECT 
          SUM(total) as total_revenue,
          COUNT(id) as total_transactions,
          SUM(tax) as total_tax,
          SUM(discount) as total_discount
        FROM transactions t
        WHERE $dateCondition
      ''');

      final methodsRes = await db.rawQuery('''
        SELECT payment_method, COUNT(id) as count, SUM(total) as revenue
        FROM transactions t
        WHERE $dateCondition
        GROUP BY payment_method
      ''');

      Map<String, dynamic> sum = Map<String, dynamic>.from(summaryRes.first);
      sum['by_payment_method'] = methodsRes;

      final topRes = await db.rawQuery('''
        SELECT d.product_id, d.name as product_name, SUM(d.quantity) as total_qty, SUM(d.subtotal) as total_revenue
        FROM transaction_details d
        JOIN transactions t ON t.id = d.transaction_id
        WHERE $dateCondition
        GROUP BY d.product_id, d.name
        ORDER BY total_qty DESC
        LIMIT 10
      ''');

      setState(() {
        _summary     = sum;
        _topProducts = topRes;
        _loading     = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final db = await DatabaseService().database;
      final txns = await db.rawQuery('SELECT * FROM transactions ORDER BY id DESC');
      
      List<List<dynamic>> csvData = [
        ['ID', 'No Invoice', 'Metode Bayar', 'Subtotal', 'Pajak', 'Diskon', 'Total', 'Dibayar', 'Kembalian', 'Tanggal']
      ];
      
      for (var t in txns) {
        csvData.add([
          t['id'], t['invoice_number'], t['payment_method'],
          t['subtotal'], t['tax'], t['discount'], t['total'],
          t['paid_amount'], t['change_amount'], t['created_at']
        ]);
      }
      
      String csv = const ListToCsvConverter().convert(csvData);
      
      final temp = await getTemporaryDirectory();
      final file = File('${temp.path}/laporan_transaksi_pos.csv');
      await file.writeAsString(csv);
      
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')], 
        text: 'Laporan Excel Transaksi POS'
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal export: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Laporan',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
              fontSize:   20,
            )),
        actions: [
          // Export button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              icon: _exporting
                  ? const SizedBox(
                      height: 16, width: 16,
                      child:  CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_rounded),
              label:    const Text('Export'),
              onPressed: _exporting ? null : _export,
              style:    TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
        bottom: TabBar(
          controller:    _tabCtrl,
          labelColor:    AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Terlaris'),
            Tab(text: 'Metode Bayar'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PeriodChip(label: 'Hari Ini', value: 'daily',   selected: _period, onTap: _setPeriod),
                  _PeriodChip(label: 'Minggu Ini', value: 'weekly', selected: _period, onTap: _setPeriod),
                  _PeriodChip(label: 'Bulan Ini', value: 'monthly', selected: _period, onTap: _setPeriod),
                ],
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildSummaryTab(),
                      _buildTopProductsTab(),
                      _buildPaymentTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _setPeriod(String v) {
    setState(() => _period = v);
    _load();
  }

  Widget _buildSummaryTab() {
    final revenue      = _summary?['total_revenue']      ?? 0;
    final transactions = _summary?['total_transactions'] ?? 0;
    final tax          = _summary?['total_tax']          ?? 0;
    final discount     = _summary?['total_discount']     ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GridView.count(
          crossAxisCount:  2,
          shrinkWrap:      true,
          crossAxisSpacing: 12,
          mainAxisSpacing:  12,
          childAspectRatio: 1.4,
          physics:         const NeverScrollableScrollPhysics(),
          children: [
            _ReportCard(label: 'Total Pendapatan',
                value: _fmt.format(revenue),
                icon:  Icons.attach_money_rounded,
                color: AppColors.primary),
            _ReportCard(label: 'Jumlah Transaksi',
                value: '$transactions',
                icon:  Icons.receipt_long_rounded,
                color: AppColors.success),
            _ReportCard(label: 'Total Pajak',
                value: _fmt.format(tax),
                icon:  Icons.percent_rounded,
                color: AppColors.warning),
            _ReportCard(label: 'Total Diskon',
                value: _fmt.format(discount),
                icon:  Icons.local_offer_rounded,
                color: AppColors.info),
          ],
        ),
      ]),
    );
  }

  Widget _buildTopProductsTab() {
    if (_topProducts.isEmpty) {
      return Center(
          child: Text('Tidak ada data',
              style: GoogleFonts.inter(color: AppColors.textSecondary)));
    }
    return ListView.separated(
      padding:          const EdgeInsets.all(16),
      itemCount:        _topProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = _topProducts[i];
        return Container(
          padding:     const EdgeInsets.all(14),
          decoration:  BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            CircleAvatar(
              radius:          16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text('${i + 1}',
                  style: GoogleFonts.inter(
                      color:      AppColors.primary,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(p['product_name'] as String,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${p['total_qty']} terjual',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12)),
              Text(_fmt.format(p['total_revenue']),
                  style: GoogleFonts.inter(
                      color:      AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize:   14)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildPaymentTab() {
    final byMethod =
        (_summary?['by_payment_method'] as List?) ?? [];

    if (byMethod.isEmpty) {
      return Center(
          child: Text('Tidak ada data',
              style: GoogleFonts.inter(color: AppColors.textSecondary)));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        ...byMethod.map((m) {
          final isCash = m['payment_method'] == 'cash';
          return Container(
            margin:  const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Container(
                padding:     const EdgeInsets.all(10),
                decoration:  BoxDecoration(
                  color:        (isCash ? AppColors.success : AppColors.info)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCash
                      ? Icons.payments_outlined
                      : Icons.qr_code_scanner_rounded,
                  color: isCash ? AppColors.success : AppColors.info,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isCash ? 'Tunai' : 'Digital',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      Text('${m['count']} transaksi',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ]),
              ),
              Text(_fmt.format(m['revenue']),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color:      AppColors.primary,
                      fontSize:   15)),
            ]),
          );
        }),
      ]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;
  const _ReportCard(
      {required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.all(16),
      decoration:  BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
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
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary),
              maxLines: 2),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String   label;
  final String   value;
  final String   selected;
  final ValueChanged<String> onTap;
  const _PeriodChip(
      {required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:   const EdgeInsets.only(right: 8),
        padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
              color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color:      isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize:   13,
            )),
      ),
    );
  }
}