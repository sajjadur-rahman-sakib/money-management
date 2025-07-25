import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:money_management/core/constants.dart';
import 'package:money_management/models/book.dart';
import 'package:money_management/models/transaction.dart';

class ApiService {
  final String token;

  ApiService({required this.token});

  Future<List<Book>> fetchBooks() async {
    print('Fetching books...'); // Debug print
    final response = await http.get(
      Uri.parse('$baseUrl/books'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('fetchBooks response status: ${response.statusCode}'); // Debug print
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('fetchBooks response data: $data'); // Debug print
      return data.map((b) => Book.fromJson(b)).toList();
    }
    print('fetchBooks failed with status: ${response.statusCode}');
    print('fetchBooks error response: ${response.body}');
    throw Exception('Failed to load books');
  }

  Future<Book> createBook(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/books'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      print('createBook response: $jsonData'); // Debug print
      return Book.fromJson(jsonData);
    }
    print('createBook failed with status: ${response.statusCode}');
    print('createBook error response: ${response.body}');
    throw Exception('Failed to create book');
  }

  Future<void> renameBook(int bookID, String newName) async {
    print('Renaming book $bookID to "$newName"'); // Debug print
    final response = await http.put(
      Uri.parse('$baseUrl/books/$bookID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': newName}),
    );
    print('Rename response status: ${response.statusCode}'); // Debug print
    print('Rename response body: ${response.body}'); // Debug print
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to rename book: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> deleteBook(int bookID) async {
    print('Deleting book $bookID'); // Debug print
    print('DELETE URL: $baseUrl/books/$bookID'); // Debug print
    final response = await http.delete(
      Uri.parse('$baseUrl/books/$bookID'),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Delete response status: ${response.statusCode}'); // Debug print
    print('Delete response body: ${response.body}'); // Debug print

    // Check if the deletion was successful
    if (response.statusCode == 200 || response.statusCode == 204) {
      print('Delete operation completed successfully');
      return;
    }

    // Handle specific error cases
    if (response.statusCode == 404) {
      throw Exception('Book not found (ID: $bookID)');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - invalid token');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - no permission to delete this book');
    } else {
      throw Exception(
        'Failed to delete book: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<Transaction>> fetchTransactions(int bookID) async {
    print('Making API call to: $baseUrl/books/$bookID/transactions');
    final response = await http.get(
      Uri.parse('$baseUrl/books/$bookID/transactions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Fetch transactions response status: ${response.statusCode}');
    print('Fetch transactions response body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      print('Parsed data: $data');

      List<Transaction> transactions = [];
      for (var item in data) {
        try {
          print('Processing transaction item: $item');
          transactions.add(Transaction.fromJson(item));
        } catch (e) {
          print('Error parsing transaction item: $item, Error: $e');
        }
      }

      print('Successfully parsed ${transactions.length} transactions');
      return transactions;
    }
    throw Exception('Failed to load transactions');
  }

  Future<void> addTransaction(int bookID, double amount, String note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/books/$bookID/transactions'),
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
    print('=== UPDATE TRANSACTION API CALL ===');
    print(
      'Updating transaction: bookID=$bookID, transactionID=$transactionID, amount=$amount, note=$note',
    );

    final url = '$baseUrl/books/$bookID/transactions/$transactionID';
    print('PUT URL: $url');
    print(
      'Request headers: Content-Type: application/json, Authorization: Bearer ${token.substring(0, 10)}...',
    );
    print('Request body: ${jsonEncode({"amount": amount, "note": note})}');

    // First, let's try to fetch the specific transaction to see if it exists
    print('--- Testing if we can fetch this specific transaction first ---');
    try {
      final fetchResponse = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      print('GET $url response status: ${fetchResponse.statusCode}');
      print('GET $url response body: ${fetchResponse.body}');
    } catch (e) {
      print('Error testing GET for transaction: $e');
    }
    print('--- End of GET test ---');

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"amount": amount, "note": note}),
    );
    print('Update transaction response status: ${response.statusCode}');
    print('Update transaction response body: ${response.body}');
    print('Update transaction response headers: ${response.headers}');
    print('=== END UPDATE TRANSACTION API CALL ===');

    // Handle different success status codes
    if (response.statusCode == 200 || response.statusCode == 204) {
      print('Transaction updated successfully');
      return;
    }

    // Handle specific error cases
    if (response.statusCode == 404) {
      throw Exception('Transaction not found (ID: $transactionID)');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - invalid token');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - no permission to update this transaction');
    } else if (response.statusCode == 400) {
      throw Exception('Bad request - invalid data provided');
    } else {
      throw Exception(
        'Failed to update transaction: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> deleteTransaction(int bookId, int transactionID) async {
    print('Deleting transaction $transactionID from book $bookId');

    final url = '$baseUrl/books/$bookId/transactions/$transactionID';
    print('DELETE URL: $url');
    print(
      'Request headers: Authorization: Bearer ${token.substring(0, 10)}...',
    );

    final response = await http.delete(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Delete transaction response status: ${response.statusCode}');
    print('Delete transaction response body: ${response.body}');
    print('Delete transaction response headers: ${response.headers}');

    // Handle different success status codes
    if (response.statusCode == 200 || response.statusCode == 204) {
      print('Transaction deleted successfully');
      return;
    }

    // Handle specific error cases
    if (response.statusCode == 404) {
      throw Exception('Transaction not found (ID: $transactionID)');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - invalid token');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden - no permission to delete this transaction');
    } else {
      throw Exception(
        'Failed to delete transaction: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
