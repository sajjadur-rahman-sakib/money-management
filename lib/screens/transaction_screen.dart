import 'package:flutter/material.dart';
import 'package:money_management/services/api_service_transaction.dart';
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

  @override
  void initState() {
    super.initState();
    apiService = ApiService(widget.token);
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    final result = await apiService.fetchTransactions(widget.book.id);
    setState(() {
      transactions = result;
    });
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
              if (amount == null) return;
              await apiService.addTransaction(widget.book.id, amount, note);
              Navigator.pop(context);
              fetchTransactions();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Transaction transaction) {
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
              if (amount == null) return;
              await apiService.updateTransaction(
                transaction.id,
                widget.book.id,
                amount,
                note,
              );
              Navigator.pop(context);
              fetchTransactions();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(Transaction tx) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete transaction "${tx.note}"?'),
        actions: [
          TextButton(
            onPressed: () async {
              await apiService.deleteTransaction(tx.id, widget.book.id);
              Navigator.pop(context);
              fetchTransactions();
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
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return ListTile(
            title: Text(tx.note),
            subtitle: Text('৳${tx.amount.toStringAsFixed(2)}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showEditDialog(tx);
                if (value == 'delete') _confirmDeleteTransaction(tx);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
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
