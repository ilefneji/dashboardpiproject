// lib/features/journal/domain/entities/journal_history.dart
// Rename journal_entry.dart → journal_history.dart


class JournalHistory {
  final String id;
  final String journalId; // ✅ was missing — UUID reference
  final int userId; // ✅ Int not String — matches Prisma schema
  final String action;
  final Map<String, dynamic> changes; // ✅ Json type → Map
  final DateTime timestamp;

  const JournalHistory({
    required this.id,
    required this.journalId,
    required this.userId,
    required this.action,
    required this.changes,
    required this.timestamp,
  });

  factory JournalHistory.fromJson(Map<String, dynamic> json) {
    return JournalHistory(
      id: json['id'] as String,
      journalId: json['journalId'] as String,
      userId: json['userId'],
      action: json['action'] as String? ?? '',
      changes: (json['changes'] as Map<String, dynamic>?) ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'journalId': journalId,
        'userId': userId,
        'action': action,
        'changes': changes,
        'timestamp': timestamp.toIso8601String(),
      };
}
