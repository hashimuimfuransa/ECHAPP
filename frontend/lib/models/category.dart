import 'dart:convert';

class Category {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<String> subcategories;
  final bool isPopular;
  final bool isFeatured;
  final int level;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.subcategories,
    this.isPopular = false,
    this.isFeatured = false,
    this.level = 1,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String? ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      subcategories: json['subcategories'] is List
          ? List<String>.from(json['subcategories'])
          : [],
      isPopular: json['isPopular'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      level: json['level'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'subcategories': subcategories,
      'isPopular': isPopular,
      'isFeatured': isFeatured,
      'level': level,
    };
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, level: $level)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
