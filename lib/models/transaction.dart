class Transaction {
  final int id;
  final double amount;
  final String note;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.note,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    print('=== DEBUGGING TRANSACTION JSON ===');
    print('Full JSON: $json');
    print('All keys: ${json.keys.toList()}');

    // Print each field value
    json.forEach((key, value) {
      print('$key: $value (type: ${value.runtimeType})');
    });

    // Extract ID - try different possible field names
    int id = 0;

    // Try different possible field names for ID
    List<String> possibleIdFields = [
      'id',
      'ID',
      'Id',
      'transaction_id',
      'transactionId',
      'TransactionId',
      '_id',
      'objectId',
      'pk',
      'primary_key',
      'tid',
      'txn_id',
      'trans_id',
    ];

    for (String field in possibleIdFields) {
      if (json[field] != null) {
        final value = json[field];
        if (value is int && value > 0) {
          id = value;
          print('Found ID in field "$field": $id');
          break;
        } else if (value is String) {
          final parsedId = int.tryParse(value);
          if (parsedId != null && parsedId > 0) {
            id = parsedId;
            print('Found ID in field "$field" (string): $id');
            break;
          }
        }
      }
    }

    // If still no ID, try any field that contains 'id' (case insensitive)
    if (id == 0) {
      for (String key in json.keys) {
        if (key.toLowerCase().contains('id') && json[key] != null) {
          final value = json[key];
          if (value is int && value > 0) {
            id = value;
            print('Found ID in field containing "id": "$key" = $id');
            break;
          } else if (value is String) {
            final parsedId = int.tryParse(value);
            if (parsedId != null && parsedId > 0) {
              id = parsedId;
              print(
                'Found ID in field containing "id": "$key" = $id (from string)',
              );
              break;
            }
          }
        }
      }
    }

    // If we still don't have an ID, this is a critical error
    if (id == 0) {
      print('CRITICAL ERROR: No valid ID found in transaction JSON');
      print('Available fields: ${json.keys.toList()}');
      // Try to use any numeric field as fallback
      for (String key in json.keys) {
        final value = json[key];
        if (value is int && value > 0) {
          id = value;
          print('Using fallback ID from field "$key": $id');
          break;
        }
      }
      // If still no ID, throw an error
      if (id == 0) {
        throw Exception('No valid ID found in transaction data: $json');
      }
    }

    // Extract amount
    double amount = 0.0;
    List<String> possibleAmountFields = [
      'amount',
      'value',
      'sum',
      'total',
      'money',
    ];
    for (String field in possibleAmountFields) {
      if (json[field] != null) {
        final value = json[field];
        if (value is double) {
          amount = value;
          break;
        } else if (value is int) {
          amount = value.toDouble();
          break;
        } else if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) {
            amount = parsed;
            break;
          }
        }
      }
    }

    // Extract note
    String note = '';
    List<String> possibleNoteFields = [
      'note',
      'description',
      'memo',
      'comment',
      'text',
      'details',
    ];
    for (String field in possibleNoteFields) {
      if (json[field] != null && json[field].toString().isNotEmpty) {
        note = json[field].toString();
        break;
      }
    }

    print('=== FINAL PARSED VALUES ===');
    print('Parsed transaction: id=$id, amount=$amount, note="$note"');
    print('================================');

    return Transaction(
      id: id,
      amount: amount,
      note: note,
      createdAt:
          DateTime.tryParse(
            json['created_at']?.toString() ??
                json['createdAt']?.toString() ??
                json['date']?.toString() ??
                json['timestamp']?.toString() ??
                json['time']?.toString() ??
                DateTime.now().toIso8601String(),
          ) ??
          DateTime.now(),
    );
  }
}
