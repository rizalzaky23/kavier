import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/models/transaction_model.dart';
import '../../../../features/products/data/models/product_model.dart';
import '../../../../core/services/database_service.dart';

class KasirProvider extends ChangeNotifier {
  final List<CartItem> _cart    = [];
  bool    _isProcessing         = false;
  String? _errorMessage;
  double  _discount             = 0;
  double  _taxPercentage        = 10; // default 10%
  String  _paymentMethod        = 'cash';
  double  _paidAmount           = 0;

  List<CartItem> get cart          => List.unmodifiable(_cart);
  bool    get isProcessing         => _isProcessing;
  String? get errorMessage         => _errorMessage;
  double  get discount             => _discount;
  double  get taxPercentage        => _taxPercentage;
  String  get paymentMethod        => _paymentMethod;
  double  get paidAmount           => _paidAmount;

  // Calculations
  double get subtotal => _cart.fold(0, (s, i) => s + i.subtotal);
  double get tax      => subtotal * (_taxPercentage / 100);
  double get total    => subtotal + tax - _discount;
  double get change   => _paidAmount - total;
  bool   get cartEmpty => _cart.isEmpty;
  int    get itemCount => _cart.fold(0, (s, i) => s + i.quantity);

  void addToCart(ProductModel product) {
    final idx = _cart.indexWhere((i) => i.productId == product.id);
    if (idx >= 0) {
      if (_cart[idx].quantity < product.stock) {
        _cart[idx].quantity++;
      }
    } else {
      if (product.stock > 0) {
        _cart.add(CartItem(
          productId: product.id,
          name:      product.name,
          price:     product.price,
        ));
      }
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void updateQty(int productId, int qty) {
    final idx = _cart.indexWhere((i) => i.productId == productId);
    if (idx < 0) return;
    if (qty <= 0) {
      _cart.removeAt(idx);
    } else {
      _cart[idx].quantity = qty;
    }
    notifyListeners();
  }

  void setDiscount(double value) {
    _discount = value < 0 ? 0 : value;
    notifyListeners();
  }

  void setTax(double pct) {
    _taxPercentage = pct;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount;
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _discount   = 0;
    _paidAmount = 0;
    notifyListeners();
  }

  Future<TransactionModel?> checkout() async {
    if (_cart.isEmpty) return null;
    if (_paidAmount < total) {
      _errorMessage = 'Jumlah bayar kurang dari total.';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final dbService = DatabaseService();
      final db = await dbService.database;

      // 1. Generate Invoice Number locally
      final now = DateTime.now();
      // Format: YYYY-MM-DD untuk cocok dengan ISO created_at
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final invoiceDateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM transactions WHERE created_at LIKE ?', ['$dateStr%']);
      final count = Sqflite.firstIntValue(result) ?? 0;
      final invoiceNum = 'INV-$invoiceDateStr-${(count + 1).toString().padLeft(4, '0')}';

      // 2. Default user id
      const int userId = 1;

      int? transactionId;
      await db.transaction((txn) async {
        // Double check stock first
        for (var item in _cart) {
          final p = await txn.query('products', where: 'id = ?', whereArgs: [item.productId]);
          if (p.isEmpty || (p.first['stock'] as int) < item.quantity) {
            throw Exception('Stok_Habis');
          }
        }

        // Insert Transaction master
        transactionId = await txn.insert('transactions', {
          'user_id': userId,
          'invoice_number': invoiceNum,
          'subtotal': subtotal,
          'tax': tax,
          'discount': _discount,
          'total': total,
          'paid_amount': _paidAmount,
          'change_amount': change,
          'payment_method': _paymentMethod,
          'status': 'completed',
          'notes': null,
          'created_at': now.toIso8601String()
        });

        // Insert Details & Deduct Stock
        for (var item in _cart) {
          await txn.insert('transaction_details', {
            'transaction_id': transactionId,
            'product_id': item.productId,
            'name': item.name,
            'price': item.price,
            'quantity': item.quantity,
            'subtotal': item.subtotal,
            'created_at': now.toIso8601String()
          });

          // Deduct stock
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [item.quantity, item.productId]
          );
        }
      });

      final transaction = TransactionModel(
        id: transactionId!,
        invoiceNumber: invoiceNum,
        subtotal: subtotal,
        tax: tax,
        discount: discount,
        total: total,
        paidAmount: paidAmount,
        changeAmount: change,
        paymentMethod: paymentMethod,
        status: 'completed',
        createdAt: now.toIso8601String(),
      );

      clearCart();
      return transaction;
    } catch (e) {
      _errorMessage = e.toString().contains('Stok_Habis')
          ? 'Stok tidak mencukupi untuk salah satu produk.'
          : 'Gagal memproses transaksi lokal.';
      notifyListeners();
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
}
