class WpCategory {
  const WpCategory({required this.id, required this.name, required this.count});

  final int id;
  final String name;
  final int count;

  factory WpCategory.fromJson(Map<String, dynamic> json) {
    return WpCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      count: json['count'] as int? ?? 0,
    );
  }
}
