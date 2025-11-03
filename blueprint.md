
# SumQuiz Blueprint

## Overview

SumQuiz is a mobile application that helps users study and learn by creating summaries, quizzes, and flashcards from text. The app uses a freemium model, with a free tier that has limitations on the number of items that can be created, and a "Pro" tier with unlimited access.

## Features

### Core Features

*   **Summaries:** Users can create summaries from text.
*   **Quizzes:** Users can create quizzes from text, either from scratch or from a summary. Quizzes can be saved in-progress and scores are saved upon completion.
*   **Flashcards:** Users can create flashcards from text.
*   **Spaced Repetition:** The app uses a spaced repetition algorithm to help users review flashcards at the optimal time.
*   **Progress Tracking:** The app tracks the user's progress, including the number of items created, the number of items due for review, and upcoming reviews.

### Pro Features

*   **Unlimited Content:** Pro users can create an unlimited number of summaries, quizzes, and flashcards.
*   **Advanced Progress Tracking:** Pro users have access to advanced progress tracking features, such as accuracy trends, performance by topic, and longer-term progress charts.

## Current Implementation

### Library Screen & Data Flow

The library screen has been completely fixed. It now correctly sources its quiz data from the `QuizViewModel`, which in turn reads from the local database. This ensures that any quiz saved via the `quiz_screen.dart`—whether in-progress or completed—appears instantly and reliably in the library's "Quizzes" and "All" tabs.

### Quiz Generation

The quiz generation logic has been corrected. The `AIService` now features a dedicated `generateQuizFromText` method. The `quiz_screen.dart` has been updated to call this method, ensuring that quizzes generated from the quiz creation form use the provided raw text, not a summary. Additionally, generating a quiz from a summary now correctly passes the summary's content to the quiz screen, which then automatically generates the quiz.

### Quiz Screen & Data Flow

The quiz saving and data flow has been completely fixed and is now reliable. 

*   **In-Progress Saving:** A save icon in the app bar allows users to save a quiz while it's in progress.
*   **Reliable Final Score Saving:** The final score is correctly appended to the quiz's history upon completion.
*   **Immediate UI Updates:** The core issue has been resolved by adding a call to `quizViewModel.refresh()` immediately after any save operation (`_saveInProgress` and `_saveFinalScoreAndExit`). This forces the `QuizViewModel` to reload its data from the local database and notify all listening widgets—specifically the library and profile screens—to rebuild. This ensures that new quizzes and updated scores appear instantly across the app, providing a seamless and predictable user experience.

### Profile Screen

The `profile_screen.dart` has been updated to correctly display the user's quiz statistics. The screen is now a `StatefulWidget` that listens for changes in the `QuizViewModel`. This ensures that the number of quizzes taken, the average score, and the best score are all updated in real-time as the user completes quizzes.

### Review Screen

The `review_screen.dart` has been completely rewritten to correctly fetch and display due flashcards. The logic now fetches all flashcard sets from Firestore, and then uses the `SpacedRepetitionService` to identify and display only the cards that are actually due for review. The `SpacedRepetitionService` has also been updated to include a `getDueFlashcardIds` method, which returns a list of IDs of the flashcards that are due. This fixes the bug where the review screen was not functioning correctly.

### Flashcard Creation and Scheduling

The flashcard creation process has been corrected. When a user creates a new flashcard set in the `flashcards_screen.dart`, each flashcard is now assigned a unique ID. After the set is saved to Firestore, each flashcard is then scheduled for review using the `SpacedRepetitionService`. This ensures that new flashcards are immediately available for review in the "Review" screen.

### Spaced Repetition

The `SpacedRepetitionService` has been completely rewritten to correctly use the `SpacedRepetitionItem` model. All constructor, property, and method errors have been fixed. The service now correctly schedules new flashcards for review and updates them based on user performance.

### Progress Tracking

The progress screen now correctly displays the number of items due for review and the upcoming reviews. The `review_screen.dart` and `spaced_repetition_screen.dart` have been updated to correctly pass the `userId` to the `getDueFlashcards` function.

### Flashcard Model

The `Flashcard` model now includes an `id` field. The `edit_content_screen.dart` file has been updated to assign a unique ID to each new flashcard.

### Data Flow

The data flow has been corrected to ensure that the "Progress" and "Review" screens are always up-to-date. The `progress_screen.dart` now correctly loads the stats, and the `review_screen.dart` now correctly loads the due flashcards.
