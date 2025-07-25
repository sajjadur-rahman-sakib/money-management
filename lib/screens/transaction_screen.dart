import 'package:flutter/material.dart';
import 'package:money_management/services/api_service.dart';
import '../models/book.dart';
import '../models/transaction.dart';

class TransactionScreen extends StatefulWidget {
  final String token;
  final Book book;

  const TransactionScreen({super.key, required this.token, required this.book});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  late ApiService apiService;
  List<Transaction> transactions = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    apiService = ApiService(token: widget.token);
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('Fetching transactions for book ID: ${widget.book.id}');
      final result = await apiService.fetchTransactions(widget.book.id);
      print('Fetched ${result.length} transactions');
      setState(() {
        transactions = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
      });
      // Only show error message if the widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading transactions: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(hintText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              final note = noteController.text;
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (note.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a note'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                print('About to add transaction...');
                await apiService.addTransaction(widget.book.id, amount, note);
                print('Transaction added, closing dialog...');
                Navigator.pop(context);
                print('Dialog closed, fetching transactions...');
                await fetchTransactions();

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error adding transaction: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error adding transaction: ${e.toString().replaceAll('Exception: ', '')}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Transaction transaction) {
    print(
      'Opening edit dialog for transaction: id=${transaction.id}, amount=${transaction.amount}, note=${transaction.note}',
    );

    // Validate transaction ID before proceeding
    if (transaction.id <= 0) {
      print('ERROR: Invalid transaction ID: ${transaction.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Invalid transaction ID. Cannot edit this transaction.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amountController = TextEditingController(
      text: transaction.amount.toString(),
    );
    final noteController = TextEditingController(text: transaction.note);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(hintText: 'Note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              final note = noteController.text;
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (note.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a note'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                print('=== EDIT TRANSACTION DEBUGGING ===');
                print('About to update transaction with:');
                print('  Book ID: ${widget.book.id}');
                print('  Transaction ID: ${transaction.id}');
                print('  Amount: $amount');
                print('  Note: $note');
                print(
                  '  Original transaction data: id=${transaction.id}, amount=${transaction.amount}, note="${transaction.note}"',
                );

                // Additional validation
                if (transaction.id <= 0) {
                  throw Exception('Invalid transaction ID: ${transaction.id}');
                }
                if (widget.book.id <= 0) {
                  throw Exception('Invalid book ID: ${widget.book.id}');
                }

                // Before updating, let's verify the transaction still exists by refetching
                print(
                  'Refetching transactions to verify transaction still exists...',
                );
                final currentTransactions = await apiService.fetchTransactions(
                  widget.book.id,
                );
                print('Current transactions after refetch:');
                for (var t in currentTransactions) {
                  print(
                    '  - ID: ${t.id}, Amount: ${t.amount}, Note: "${t.note}"',
                  );
                }

                final existingTransaction = currentTransactions.firstWhere(
                  (t) => t.id == transaction.id,
                  orElse: () => throw Exception(
                    'Transaction with ID ${transaction.id} no longer exists',
                  ),
                );
                print(
                  'Transaction verified to exist: id=${existingTransaction.id}',
                );
                print('=== END DEBUGGING ===');

                await apiService.updateTransaction(
                  widget.book.id,
                  transaction.id,
                  amount,
                  note,
                );
                Navigator.pop(context);
                await fetchTransactions();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error updating transaction: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error updating transaction: ${e.toString().replaceAll('Exception: ', '')}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(Transaction tx) {
    print('Attempting to delete transaction: id=${tx.id}, note=${tx.note}');

    // Validate transaction ID before proceeding
    if (tx.id <= 0) {
      print('ERROR: Invalid transaction ID for deletion: ${tx.id}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Invalid transaction ID. Cannot delete this transaction.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete transaction "${tx.note}"?'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                print(
                  'Calling deleteTransaction with bookId=${widget.book.id}, transactionId=${tx.id}',
                );

                // Before deleting, let's verify the transaction still exists by refetching
                print(
                  'Refetching transactions to verify transaction still exists...',
                );
                final currentTransactions = await apiService.fetchTransactions(
                  widget.book.id,
                );
                final existingTransaction = currentTransactions.firstWhere(
                  (t) => t.id == tx.id,
                  orElse: () => throw Exception('Transaction no longer exists'),
                );
                print(
                  'Transaction verified to exist: id=${existingTransaction.id}',
                );

                await apiService.deleteTransaction(widget.book.id, tx.id);
                Navigator.pop(context);
                await fetchTransactions();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error deleting transaction: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error deleting transaction: ${e.toString().replaceAll('Exception: ', '')}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.name)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
          ? const Center(
              child: Text(
                'No transactions yet.\nTap + to add your first transaction.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];

                // Debug: Print transaction info
                print(
                  'Displaying transaction $index: id=${transaction.id}, amount=${transaction.amount}, note=${transaction.note}',
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction.amount >= 0
                          ? Colors.green
                          : Colors.red,
                      child: Icon(
                        transaction.amount >= 0 ? Icons.add : Icons.remove,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      transaction.note,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year} at ${transaction.createdAt.hour.toString().padLeft(2, '0')}:${transaction.createdAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '৳${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: transaction.amount >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _showEditDialog(transaction);
                            if (value == 'delete') {
                              _confirmDeleteTransaction(transaction);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
