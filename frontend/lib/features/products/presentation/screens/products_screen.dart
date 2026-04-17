import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/product_provider.dart';
import '../../data/models/product_model.dart';
import '../../../../core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  final _fmt = NumberFormat.currency(
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Produk',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color:      AppColors.textPrimary,
              fontSize:   20,
            )),
        actions: [
          IconButton(
            icon:     const Icon(Icons.add_rounded, color: AppColors.primary),
            tooltip:  'Tambah Produk',
            onPressed: () => _showProductForm(context),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (_, p, __) => Column(
          children: [
            // Search
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
                onChanged: (v) => p.fetchProducts(search: v),
              ),
            ),

            // List
            Expanded(
              child: p.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding:          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:        p.products.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final prod = p.products[i];
                        return _ProductListTile(
                          product: prod,
                          fmt:     _fmt,
                          onEdit:  () => _showProductForm(context, product: prod),
                          onDelete: () async {
                            final ok = await p.deleteProduct(prod.id);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Produk dihapus.'),
                                    backgroundColor: AppColors.success),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductForm(BuildContext ctx, {ProductModel? product}) {
    showModalBottomSheet(
      context:       ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
              value: ctx.read<ProductProvider>()),
        ],
        child: _ProductForm(product: product),
      ),
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final ProductModel product;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductListTile({
    required this.product,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:     const EdgeInsets.all(12),
      decoration:  BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color:     Colors.black.withOpacity(0.04),
              blurRadius: 6)
        ],
      ),
      child: Row(children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width:  56,
            height: 56,
            child: product.imageUrl != null
                ? (product.imageUrl!.startsWith('http')
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                    : Image.file(File(product.imageUrl!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder()))
                : _placeholder(),
          ),
        ),
        const SizedBox(width: 12),

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(product.category?.name ?? '-',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Row(children: [
                Text(fmt.format(product.price),
                    style: GoogleFonts.inter(
                        color:      AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize:   14)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:        product.isLowStock
                        ? AppColors.warning.withOpacity(0.15)
                        : AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Stok: ${product.stock}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color:    product.isLowStock
                            ? AppColors.warning
                            : AppColors.success,
                        fontWeight: FontWeight.w500,
                      )),
                ),
              ]),
            ],
          ),
        ),

        // Actions
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') _confirmDelete(context);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit',   child: Text('Edit')),
            const PopupMenuItem(
                value:  'delete',
                child:  Text('Hapus', style: TextStyle(color: AppColors.error))),
          ],
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
        color:  AppColors.background,
        child:  const Icon(Icons.fastfood_rounded,
            color: AppColors.textHint, size: 24),
      );

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title:   const Text('Hapus Produk?'),
        content: Text('Produk "${product.name}" akan dihapus permanen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:     const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final ProductModel? product;
  const _ProductForm({this.product});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey     = GlobalKey<FormState>();
  late final _nameCtrl  = TextEditingController(text: widget.product?.name);
  late final _priceCtrl = TextEditingController(
      text: widget.product?.price.toStringAsFixed(0));
  late final _stockCtrl = TextEditingController(
      text: widget.product?.stock.toString());
  late final _descCtrl  = TextEditingController(text: widget.product?.description);
  int? _categoryId;
  XFile? _imageFile;
  bool  _isLoading      = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<ProductProvider>().categories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product == null ? 'Tambah Produk' : 'Edit Produk',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 20),

              // Name
              _FieldWrapper(
                label: 'Nama Produk',
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: _dec('Nama produk'),
                  validator: (v) =>
                      v!.isEmpty ? 'Wajib diisi' : null,
                ),
              ),

              // Category
              _FieldWrapper(
                label: 'Kategori',
                child: DropdownButtonFormField<int>(
                  initialValue: _categoryId,
                  decoration: _dec('Pilih kategori'),
                  items: cats
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? 'Pilih kategori' : null,
                ),
              ),

              // Price & Stock
              Row(children: [
                Expanded(
                  child: _FieldWrapper(
                    label: 'Harga (Rp)',
                    child: TextFormField(
                      controller:  _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration:  _dec('0'),
                      validator: (v) =>
                          v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FieldWrapper(
                    label: 'Stok',
                    child: TextFormField(
                      controller:  _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration:  _dec('0'),
                      validator: (v) =>
                          v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ),
              ]),

              // Description
              _FieldWrapper(
                label: 'Deskripsi (opsional)',
                child: TextFormField(
                  controller: _descCtrl,
                  maxLines:   2,
                  decoration: _dec('Deskripsi produk'),
                ),
              ),

              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height:   80,
                  width:    double.infinity,
                  margin:   const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border:       Border.all(
                        color: AppColors.border, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                    color:        AppColors.background,
                  ),
                  child: Center(
                    child: _imageFile != null
                        ? Text('Gambar dipilih: ${_imageFile!.name}',
                            style: GoogleFonts.inter(fontSize: 13))
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_upload_outlined,
                                  color: AppColors.textHint),
                              const SizedBox(height: 4),
                              Text('Pilih Gambar',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textHint,
                                      fontSize: 13)),
                            ],
                          ),
                  ),
                ),
              ),

              // Submit
              SizedBox(
                width:  double.infinity,
                height: 52,
                child:  ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child:  CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          widget.product == null
                              ? 'Simpan Produk'
                              : 'Update Produk',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file   = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _imageFile = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String? finalImagePath = widget.product?.imageUrl;
    if (_imageFile != null) {
      final docDir = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '.png';
      final savedImage = await File(_imageFile!.path).copy('${docDir.path}/$fileName');
      finalImagePath = savedImage.path;
    }

    final data = {
      'name':        _nameCtrl.text.trim(),
      'category_id': _categoryId,
      'price':       _priceCtrl.text.trim(),
      'stock':       _stockCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'image_url':   finalImagePath,
    };

    try {
      final provider = context.read<ProductProvider>();
      if (widget.product == null) {
        await provider.createProduct(data);
      } else {
        await provider.updateProduct(widget.product!.id, data);
      }
      if (mounted) {
        Navigator.pop(context);
        // context.read<ProductProvider>().loadAll(); // Already called in provider
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:         Text('Gagal menyimpan produk.'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText:      hint,
        filled:        true,
        fillColor:     AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   const BorderSide(color: AppColors.border),
        ),
      );
}

class _FieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldWrapper({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                fontSize:   13,
                fontWeight: FontWeight.w500,
                color:      AppColors.textSecondary,
              )),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
