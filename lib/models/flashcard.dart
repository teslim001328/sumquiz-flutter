class Flashcard {
  final String question;
  final String answer;

  Flashcard({
    required this.question,
    required this.answer,
  });

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      question: map['question'] ?? '',
      answer: map['answer'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}
