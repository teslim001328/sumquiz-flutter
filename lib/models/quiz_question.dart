class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  String? selectedAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.selectedAnswer,
  });
}
