import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:money_management/core/constants.dart';
import 'package:money_management/models/book.dart';

class ApiService {
  final String token;

  ApiService({required this.token});

  Future<List<Book>> fetchBooks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/books'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((b) => Book.fromJson(b)).toList();
    }
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
      return Book.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create book');
  }

  Future<void> renameBook(int bookID, String newName) async {
    final response = await http.put(
      Uri.parse('$baseUrl/books/$bookID'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': newName}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to rename book');
    }
  }

  Future<void> deleteBook(int bookID) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/books/$bookID'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete book');
    }
  }
}
