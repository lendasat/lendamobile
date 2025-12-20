/// Transaction type enum
enum TransactionType {
  onChain,
  lightning,
  ark,
}

/// Transaction direction enum
enum TransactionDirection {
  sent,
  received,
}

/// Transaction status enum
enum TransactionStatus {
  pending,
  confirmed,
  failed,
}

class TransactionItemData {
  final TransactionType type;
  final TransactionDirection direction;
  final TransactionStatus status;
  final String receiver;
  final String txHash;
  final String amount;
  final int timestamp;
  final int fee;

  TransactionItemData({
    required this.type,
    required this.direction,
    required this.status,
    required this.receiver,
    required this.txHash,
    required this.amount,
    required this.timestamp,
    required this.fee,
  });
}
