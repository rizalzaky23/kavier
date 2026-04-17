class CartItem {
  final int productId;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity':   quantity,
      };
}

class TransactionModel {
  final int id;
  final String invoiceNumber;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod;
  final String status;
  final String? notes;
  final String createdAt;

  const TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id:            json['id'] as int,
        invoiceNumber: json['invoice_number'] as String,
        subtotal:      double.tryParse(json['subtotal'].toString()) ?? 0,
        tax:           double.tryParse(json['tax'].toString()) ?? 0,
        discount:      double.tryParse(json['discount'].toString()) ?? 0,
        total:         double.tryParse(json['total'].toString()) ?? 0,
        paidAmount:    double.tryParse(json['paid_amount'].toString()) ?? 0,
        changeAmount:  double.tryParse(json['change_amount'].toString()) ?? 0,
        paymentMethod: json['payment_method'] as String,
        status:        json['status'] as String,
        notes:         json['notes'] as String?,
        createdAt:     json['created_at'] as String,
      );
}
