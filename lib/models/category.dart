class Category {
  final String id;
  final String name;
  final int order;

  Category({
    required this.id,
    required this.name,
    required this.order,
  });

  factory Category.fromMap(Map<String, dynamic> map, String id) {
    return Category(
      id: id,
      name: map['name'] ?? '',
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
    };
  }
}
