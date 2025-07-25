class Book {
  final int id;
  final String name;
  final double balance;

  Book({required this.id, required this.name, required this.balance});

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      name: json['name'],
      balance: json['balance'].toDouble(),
    );
  }
}
