class CoachingCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<String> subcategories;
  final bool isPopular;
  final bool isFeatured;
  final int level; // 1 = All levels, 2 = Fluency, 3 = In-demand, 4 = Career-ready, 5 = Growth

  CoachingCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.subcategories,
    this.isPopular = false,
    this.isFeatured = false,
    this.level = 1,
  });

  factory CoachingCategory.fromJson(Map<String, dynamic> json) {
    return CoachingCategory(
      id: (json['_id'] ?? json['id']) as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      subcategories: List<String>.from(json['subcategories'] as List),
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
}
