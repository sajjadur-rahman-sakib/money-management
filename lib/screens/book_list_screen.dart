import 'package:flutter/material.dart';
import 'package:money_management/models/book.dart';
import 'package:money_management/screens/transaction_screen.dart';
import 'package:money_management/services/api_service_book.dart';

class BookListScreen extends StatefulWidget {
  final String token;
  const BookListScreen({super.key, required this.token});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  late ApiService apiService;
  List<Book> books = [];

  final TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    apiService = ApiService(token: widget.token);
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    print('Fetching books from API...'); // Debug print
    try {
      final result = await apiService.fetchBooks();
      print('Fetched ${result.length} books from API'); // Debug print
      setState(() {
        books = result;
      });
      print(
        'Updated local books list with ${books.length} books',
      ); // Debug print
    } catch (e) {
      print('Error fetching books: $e'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch books: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRenameBook(Book book) {
    textEditingController.text = book.name;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Book'),
        content: TextField(
          controller: textEditingController,
          decoration: InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              print(
                'Rename button pressed for book: ${book.id} - ${book.name}',
              );
              try {
                await apiService.renameBook(
                  book.id,
                  textEditingController.text,
                );
                print('Rename successful, closing dialog and refreshing');
                Navigator.pop(context);
                fetchBooks();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Book renamed successfully')),
                );
              } catch (e) {
                print('Rename failed: $e');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to rename book: $e')),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteBook(Book book) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              print(
                'Delete button pressed for book: ${book.id} - ${book.name}',
              );
              print('Current books count before delete: ${books.length}');

              try {
                await apiService.deleteBook(book.id);
                print('API delete call completed successfully');
                Navigator.pop(context);

                // Refresh the book list and verify deletion
                await fetchBooks();
                print('Books refreshed, new count: ${books.length}');

                // Check if book still exists in the list
                final stillExists = books.any((b) => b.id == book.id);
                if (stillExists) {
                  print(
                    'WARNING: Book ${book.id} still exists in the list after deletion!',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Warning: Book may not have been deleted from server',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  print('Book ${book.id} successfully removed from list');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Book deleted successfully')),
                  );
                }
              } catch (e) {
                print('Delete failed: $e');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete book: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog() async {
    textEditingController.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Create Book'),
        content: TextField(
          controller: textEditingController,
          decoration: const InputDecoration(hintText: 'Book name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await apiService.createBook(textEditingController.text);
                Navigator.pop(context);
                fetchBooks();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Book created successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to create book: $e')),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Books')),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return ListTile(
            title: Text(book.name),
            subtitle: Text('Balance: ${book.balance.toStringAsFixed(2)}'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TransactionScreen(token: widget.token, book: book),
              ),
            ).then((_) => fetchBooks()),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                print(
                  'Popup menu selected: $value for book: ${book.id} - ${book.name}',
                );
                if (value == 'rename') {
                  print('Calling _showRenameBook');
                  _showRenameBook(book);
                }
                if (value == 'delete') {
                  print('Calling _confirmDeleteBook');
                  _confirmDeleteBook(book);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
