import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:money_management/core/constants.dart';
import 'package:money_management/models/transaction.dart';

class ApiService {
  final String token;

  ApiService(this.token);

  Future<List<Transaction>> fetchTransactions(int bookID) async {
    final response = await http.get(
      Uri.parse('$baseUrl/books/$bookID/transactions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((t) => Transaction.fromJson(t)).toList();
    }
    throw Exception('Failed to load transactions');
  }

  Future<void> addTransaction(int bookID, double amount, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/books/$bookID/transacctions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"amount": amount, "note": note}),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add transaction');
    }
  }

  Future<void> updateTransaction(
    int bookID,
    int transactionID,
    double amount,
    String note,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/books/$bookID/transactions/$transactionID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"amount": amount, "note": note}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update transaction');
    }
  }

  Future<void> deleteTransaction(int bookId, int transactionID) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/books/$bookId/transactions/$transactionID'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete transaction');
    }
  }
}
