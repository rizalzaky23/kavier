import 'category_model.dart';

class ProductModel {
  final int id;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int lowStockThreshold;
  final String? image;
  final String? imageUrl;
  final bool isActive;
  final bool isLowStock;
  final CategoryModel? category;

  const ProductModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.lowStockThreshold = 5,
    this.image,
    this.imageUrl,
    this.isActive = true,
    this.isLowStock = false,
    this.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id:                 json['id'] as int,
        categoryId:         json['category_id'] as int,
        name:               json['name'] as String,
        description:        json['description'] as String?,
        price:              double.tryParse(json['price'].toString()) ?? 0,
        stock:              json['stock'] as int? ?? 0,
        lowStockThreshold:  json['low_stock_threshold'] as int? ?? 5,
        image:              json['image'] as String?,
        imageUrl:           json['image_url'] as String?,
        isActive:           (json['is_active'] as bool?) ?? true,
        isLowStock:         (json['is_low_stock'] as bool?) ?? false,
        category: json['category'] != null
            ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
            : null,
      );
}
