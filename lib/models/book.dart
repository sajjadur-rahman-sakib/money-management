class Book {
  final int id;
  final String name;
  final double balance;

  Book({required this.id, required this.name, required this.balance});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      balance: _parseDouble(json['balance']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
