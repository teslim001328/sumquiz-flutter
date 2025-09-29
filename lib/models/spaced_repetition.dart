class SpacedRepetitionItem {
  final String id;
  final String flashcardId;
  final String userId;
  final DateTime nextReviewDate;
  final int interval; // Days until next review
  final double easeFactor; // Ease factor for SM-2 algorithm
  final int repetitionCount; // Number of times reviewed
  final DateTime lastReviewed; // Last review date
  final DateTime createdAt;
  final DateTime updatedAt;

  SpacedRepetitionItem({
    required this.id,
    required this.flashcardId,
    required this.userId,
    required this.nextReviewDate,
    required this.interval,
    required this.easeFactor,
    required this.repetitionCount,
    required this.lastReviewed,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flashcardId': flashcardId,
      'userId': userId,
      'nextReviewDate': nextReviewDate,
      'interval': interval,
      'easeFactor': easeFactor,
      'repetitionCount': repetitionCount,
      'lastReviewed': lastReviewed,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory SpacedRepetitionItem.fromJson(Map<String, dynamic> json) {
    return SpacedRepetitionItem(
      id: json['id'],
      flashcardId: json['flashcardId'],
      userId: json['userId'],
      nextReviewDate: (json['nextReviewDate'] as Timestamp).toDate(),
      interval: json['interval'],
      easeFactor: json['easeFactor'],
      repetitionCount: json['repetitionCount'],
      lastReviewed: (json['lastReviewed'] as Timestamp).toDate(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory SpacedRepetitionItem.fromMap(Map<dynamic, dynamic> map) {
    return SpacedRepetitionItem(
      id: map['id'],
      flashcardId: map['flashcardId'],
      userId: map['userId'],
      nextReviewDate: map['nextReviewDate'],
      interval: map['interval'],
      easeFactor: map['easeFactor'],
      repetitionCount: map['repetitionCount'],
      lastReviewed: map['lastReviewed'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'flashcardId': flashcardId,
      'userId': userId,
      'nextReviewDate': nextReviewDate,
      'interval': interval,
      'easeFactor': easeFactor,
      'repetitionCount': repetitionCount,
      'lastReviewed': lastReviewed,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}