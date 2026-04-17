import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/data/models/product_model.dart';
import '../providers/kasir_provider.dart';
import '../../../../core/services/printer_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class KasirScreen extends StatefulWidget {
  const KasirScreen({super.key});

  @override
  State<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends State<KasirScreen> {
  final _searchCtrl = TextEditingController();
  int? _selectedCategoryId;
  final _fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Kasir',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
              fontSize:   20,
            )),
        actions: [
          Consumer<KasirProvider>(
            builder: (_, kasir, __) => Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.textPrimary),
                  onPressed: isWide
                      ? null
                      : () => _showCartBottomSheet(context, kasir),
                ),
                if (kasir.itemCount > 0)
                  Positioned(
                    top:   4,
                    right: 4,
                    child: Container(
                      padding:     const EdgeInsets.all(4),
                      decoration:  const BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle),
                      child: Text('${kasir.itemCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: isWide
          ? Row(children: [
              Expanded(flex: 3, child: _buildProductPanel()),
              Container(width: 1, color: AppColors.divider),
              SizedBox(width: 360, child: _buildCartPanel()),
            ])
          : _buildProductPanel(),
    );
  }

  // ── Product grid panel ───────────────────────────────────────────────

  Widget _buildProductPanel() {
    return Consumer<ProductProvider>(
      builder: (_, p, __) => Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:  'Cari produk...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                filled:    true,
                fillColor: AppColors.surface,
                border:    OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   const BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (v) {
                p.fetchProducts(
                    search:     v,
                    categoryId: _selectedCategoryId);
              },
            ),
          ),

          // Category filter
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:        const EdgeInsets.symmetric(horizontal: 16),
              itemCount:      p.categories.length + 1,
              itemBuilder:    (_, i) {
                if (i == 0) {
                  return _CategoryChip(
                    label:    'Semua',
                    selected: _selectedCategoryId == null,
                    onTap:    () {
                      setState(() => _selectedCategoryId = null);
                      p.fetchProducts(search: _searchCtrl.text);
                    },
                  );
                }
                final cat = p.categories[i - 1];
                return _CategoryChip(
                  label:    cat.name,
                  selected: _selectedCategoryId == cat.id,
                  onTap:    () {
                    setState(() => _selectedCategoryId = cat.id);
                    p.fetchProducts(
                        search:     _searchCtrl.text,
                        categoryId: cat.id);
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Products
          Expanded(
            child: p.isLoading
                ? const Center(child: CircularProgressIndicator())
                : p.products.isEmpty
                    ? Center(
                        child: Text('Tidak ada produk',
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:  2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing:  12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount:   p.products.length,
                        itemBuilder: (_, i) =>
                            _ProductCard(product: p.products[i]),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Cart panel (sidebar on desktop) ─────────────────────────────────

  Widget _buildCartPanel() {
    return Consumer<KasirProvider>(
      builder: (_, kasir, __) => Container(
        color: AppColors.surface,
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Keranjang',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize:   18,
                      )),
                  if (!kasir.cartEmpty)
                    TextButton(
                      onPressed: () => kasir.clearCart(),
                      child:     const Text('Hapus Semua',
                          style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Cart items
            Expanded(
              child: kasir.cartEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('Belum ada produk',
                              style: GoogleFonts.inter(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding:       const EdgeInsets.all(12),
                      itemCount:     kasir.cart.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder:   (_, i) {
                        final item = kasir.cart[i];
                        return _CartItemRow(
                          item:     item,
                          fmt:      _fmt,
                          onRemove: () =>
                              kasir.removeFromCart(item.productId),
                          onQtyChange: (q) =>
                              kasir.updateQty(item.productId, q),
                        );
                      },
                    ),
            ),

            // Summary
            if (!kasir.cartEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _SummaryRow('Subtotal', _fmt.format(kasir.subtotal)),
                    _SummaryRow(
                        'Pajak (${kasir.taxPercentage.toInt()}%)',
                        _fmt.format(kasir.tax)),
                    _SummaryRow('Diskon',
                        '- ${_fmt.format(kasir.discount)}',
                        valueColor: AppColors.success),
                    const Divider(height: 16),
                    _SummaryRow('TOTAL', _fmt.format(kasir.total),
                        bold: true, fontSize: 16),
                    const SizedBox(height: 16),
                    SizedBox(
                      width:  double.infinity,
                      height: 52,
                      child:  ElevatedButton.icon(
                        icon:  const Icon(Icons.payment_rounded),
                        label: const Text('Proses Pembayaran'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize:   15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            _showCheckoutDialog(context, kasir),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCartBottomSheet(BuildContext ctx, KasirProvider kasir) {
    showModalBottomSheet(
      context:    ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize:     0.95,
        minChildSize:     0.4,
        expand: false,
        builder: (_, scrollCtrl) => ChangeNotifierProvider.value(
          value: kasir,
          child: _buildCartPanel(),
        ),
      ),
    );
  }

  void _showCheckoutDialog(BuildContext ctx, KasirProvider kasir) {
    final paidCtrl = TextEditingController(
        text: kasir.total.toStringAsFixed(0));
    // Simpan scaffold context di sini (sebelum dialog dibuka)
    final scaffoldCtx = ctx;

    showDialog(
      context: ctx,
      builder: (_) => ChangeNotifierProvider.value(
        value: kasir,
        child: _CheckoutDialog(
          paidCtrl: paidCtrl,
          fmt: _fmt,
          scaffoldCtx: scaffoldCtx,
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:   const EdgeInsets.only(right: 8),
        padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:        selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color:      selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize:   13,
            )),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final fmt    = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final kasir  = context.read<KasirProvider>();
    final noStock = product.stock == 0;

    return GestureDetector(
      onTap: noStock ? null : () => kasir.addToCart(product),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color:        noStock
              ? AppColors.background
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color:     Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset:    const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: product.imageUrl != null
                    ? Image.network(product.imageUrl!,
                        fit:     BoxFit.cover,
                        width:   double.infinity,
                        errorBuilder: (_, __, ___) => _PlaceholderImage())
                    : _PlaceholderImage(),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child:   Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize:   13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(fmt.format(product.price),
                      style: GoogleFonts.inter(
                        color:      AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        noStock ? 'Habis' : 'Stok: ${product.stock}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color:    noStock
                              ? AppColors.error
                              : product.isLowStock
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                        ),
                      ),
                      if (!noStock)
                        Container(
                          padding:     const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:        AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 14),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: const Center(
          child: Icon(Icons.fastfood_rounded,
              color: AppColors.textHint, size: 32)),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final dynamic item;
  final NumberFormat fmt;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;

  const _CartItemRow({
    required this.item,
    required this.fmt,
    required this.onRemove,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.all(10),
      decoration:  BoxDecoration(
        color:        AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              Text(fmt.format(item.price),
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
        Row(children: [
          _QtyButton(
              icon: Icons.remove, onTap: () => onQtyChange(item.quantity - 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child:   Text('${item.quantity}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
          _QtyButton(
              icon: Icons.add, onTap: () => onQtyChange(item.quantity + 1)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap:  onRemove,
            child:  const Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 18),
          ),
        ]),
      ]),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  26,
        height: 26,
        decoration: BoxDecoration(
          color:        AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: AppColors.textPrimary),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool   bold;
  final double fontSize;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.fontSize = 14, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child:   Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize:   fontSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                color:      AppColors.textSecondary,
              )),
          Text(value,
              style: GoogleFonts.inter(
                fontSize:   fontSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color:      valueColor ?? AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

class _CheckoutDialog extends StatefulWidget {
  final TextEditingController paidCtrl;
  final NumberFormat fmt;
  final BuildContext scaffoldCtx;
  const _CheckoutDialog({
    required this.paidCtrl,
    required this.fmt,
    required this.scaffoldCtx,
  });

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kasir = context.read<KasirProvider>();
      kasir.setPaidAmount(kasir.total);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KasirProvider>(
      builder: (_, kasir, __) => AlertDialog(
        shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:   Text('Proses Pembayaran',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Payment method
              Row(children: [
                _PayMethodBtn(
                    label:    'Tunai',
                    icon:     Icons.payments_outlined,
                    selected: kasir.paymentMethod == 'cash',
                    onTap:    () => kasir.setPaymentMethod('cash')),
                const SizedBox(width: 12),
                _PayMethodBtn(
                    label:    'Digital',
                    icon:     Icons.qr_code_scanner_rounded,
                    selected: kasir.paymentMethod == 'digital',
                    onTap:    () => kasir.setPaymentMethod('digital')),
              ]),
              const SizedBox(height: 16),

              // Discount
              TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText:  'Diskon (Rp)',
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  border:     OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (v) => kasir.setDiscount(double.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 12),

              // Paid amount
              TextField(
                controller:  widget.paidCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText:  'Jumlah Dibayar',
                  prefixIcon: const Icon(Icons.money_rounded),
                  border:     OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (v) =>
                    kasir.setPaidAmount(double.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 16),

              // Total
              Container(
                padding:     const EdgeInsets.all(16),
                decoration:  BoxDecoration(
                  color:        AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  _SummaryRow('Total', widget.fmt.format(kasir.total),
                      bold: true, fontSize: 16),
                  const SizedBox(height: 4),
                  _SummaryRow(
                      'Kembalian',
                      kasir.change >= 0
                          ? widget.fmt.format(kasir.change)
                          : '— kurang ${widget.fmt.format(-kasir.change)}',
                      valueColor: kasir.change >= 0
                          ? AppColors.success
                          : AppColors.error),
                ]),
              ),

              if (kasir.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child:   Text(kasir.errorMessage!,
                      style: const TextStyle(color: AppColors.error)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:     const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: kasir.isProcessing || kasir.change < 0
                ? null
                : () async {
                    final itemsCopy = List.from(kasir.cart);
                    final result = await kasir.checkout();
                    if (result != null && context.mounted) {
                      Navigator.pop(context);
                      _showSuccessDialog(
                        widget.scaffoldCtx,
                        result,
                        widget.fmt,
                        kasir,
                        itemsCopy,
                      );
                    }
                  },
            child: kasir.isProcessing
                ? const SizedBox(
                    height: 18, width: 18,
                    child:  CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Bayar Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext ctx, result, fmt, kasir, items) {
    // ctx adalah scaffoldCtx yang valid (bukan context dialog)
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 72),
              const SizedBox(height: 16),
              Text('Transaksi Berhasil!',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 20)),
              const SizedBox(height: 8),
              Text(result.invoiceNumber,
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Container(
                padding:     const EdgeInsets.all(16),
                decoration:  BoxDecoration(
                  color:        AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  _SummaryRow('Total', fmt.format(result.total), bold: true),
                  _SummaryRow('Dibayar', fmt.format(result.paidAmount)),
                  _SummaryRow('Kembalian', fmt.format(result.changeAmount),
                      valueColor: AppColors.success),
                ]),
              ),
            ],
          ),
        ),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tombol Cetak Nota — penuh lebar
              ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded),
                label: const Text('Cetak Nota'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final capturedCtx = ctx;
                  Navigator.pop(dialogCtx);
                  // addPostFrameCallback tidak async gap — context aman digunakan
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _printNota(capturedCtx, result, items);
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Lewati'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        context.read<ProductProvider>().loadAll();
                      },
                      child: const Text('Transaksi Baru'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mencetak nota ke printer Bluetooth Eyes (atau merek lain)
  void _printNota(BuildContext scaffoldCtx, dynamic transaction, dynamic items) async {
    final printerService = PrinterService();

    // 1. Minta izin Bluetooth
    bool granted = false;
    try {
      granted = await printerService.checkPermissions();
    } catch (_) {}

    if (!granted) {
      if (scaffoldCtx.mounted) {
        ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
          const SnackBar(
            content: Text('Izin Bluetooth diperlukan. Buka Pengaturan & izinkan.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // 2. Tampilkan loading sementara memindai devices
    if (scaffoldCtx.mounted) {
      showDialog(
        context: scaffoldCtx,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Mencari printer Bluetooth...'),
            ],
          ),
        ),
      );
    }

    // 3. Cek Bluetooth nyala & dapatkan paired devices
    List<BluetoothDevice> devices = [];
    try {
      devices = await printerService.getPairedDevices();
    } catch (e) {
      // Tutup loading
      if (scaffoldCtx.mounted) Navigator.of(scaffoldCtx, rootNavigator: true).pop();
      if (scaffoldCtx.mounted) {
        ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
          SnackBar(
            content: Text('Error Bluetooth: $e\nPastikan Bluetooth aktif.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Tutup loading
    if (scaffoldCtx.mounted) Navigator.of(scaffoldCtx, rootNavigator: true).pop();

    if (devices.isEmpty) {
      if (scaffoldCtx.mounted) {
        ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak ada printer yang ter-pair.\n'
              'Pair printer Eyes via Pengaturan → Bluetooth HP terlebih dahulu.',
            ),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    if (!scaffoldCtx.mounted) return;

    // 4. Tampilkan daftar printer di BottomSheet
    showModalBottomSheet(
      context: scaffoldCtx,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.bluetooth_searching_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text('Pilih Printer Bluetooth',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${devices.length} printer ter-pair ditemukan',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...devices.map((d) => ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.print_rounded,
                      color: AppColors.primary, size: 22),
                ),
                title: Text(
                  d.name ?? 'Unknown Device',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  d.address ?? '',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint),
                onTap: () async {
                  Navigator.pop(sheetCtx); // tutup sheet

                  // Tampilkan progress
                  if (scaffoldCtx.mounted) {
                    showDialog(
                      context: scaffoldCtx,
                      barrierDismissible: false,
                      builder: (_) => AlertDialog(
                        content: Row(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Menghubungkan ke ${d.name ?? 'printer'}...',
                                style: GoogleFonts.inter(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  try {
                    await printerService.connect(d);
                    await printerService.printReceipt(transaction, items);
                    await printerService.disconnect();

                    // Tutup progress
                    if (scaffoldCtx.mounted) {
                      Navigator.of(scaffoldCtx, rootNavigator: true).pop();
                    }
                    if (scaffoldCtx.mounted) {
                      ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Nota berhasil dicetak ke ${d.name}!'),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    // Tutup progress
                    if (scaffoldCtx.mounted) {
                      Navigator.of(scaffoldCtx, rootNavigator: true).pop();
                    }
                    if (scaffoldCtx.mounted) {
                      ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
                        SnackBar(
                          content: Text('Gagal cetak: $e'),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayMethodBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     selected;
  final VoidCallback onTap;

  const _PayMethodBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:  const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:        selected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(
                color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Column(children: [
            Icon(icon,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                  color:      selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize:   12,
                )),
          ]),
        ),
      ),
    );
  }
}