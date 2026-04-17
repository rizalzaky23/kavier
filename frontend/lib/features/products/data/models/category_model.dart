class CategoryModel {
  final int id;
  final String name;
  final String? icon;
  final bool isActive;
  final int? productsCount;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.isActive = true,
    this.productsCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id:            json['id'] as int,
        name:          json['name'] as String,
        icon:          json['icon'] as String?,
        isActive:      (json['is_active'] as bool?) ?? true,
        productsCount: json['products_count'] as int?,
      );
}
