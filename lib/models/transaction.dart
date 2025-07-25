class Transaction {
  final int id;
  final double amount;
  final String note;

  Transaction({required this.id, required this.amount, required this.note});

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'].toDouble(),
      note: json['note'],
    );
  }
}
