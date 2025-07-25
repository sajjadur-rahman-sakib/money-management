import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:money_management/core/constants.dart';
import 'package:money_management/models/book.dart';

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
}
