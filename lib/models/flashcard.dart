class Flashcard {
  String question;
  String answer;

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

  factory Flashcard.from(Flashcard flashcard) {
    return Flashcard(
      question: flashcard.question,
      answer: flashcard.answer,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}
