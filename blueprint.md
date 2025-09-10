# SumQuiz App Blueprint

## Overview

SumQuiz is a mobile application designed to help users summarize text, create quizzes, and generate flashcards. The app is built with Flutter and leverages Firebase for authentication and database services. The primary goal is to provide a seamless and intuitive user experience with a modern and professional design.

## Implemented Features

### Authentication

- **Email/Password:** Users can sign up and log in using their email and password.
- **Google Sign-In:** Users can sign in with their Google account for a faster and more convenient experience.
- **User Model:** A `UserModel` class is defined to represent user data in Firestore.
- **Auth Service:** An `AuthService` handles all authentication logic, including creating user documents in Firestore upon successful sign-up.

### Main Navigation

- **Bottom Navigation:** A `BottomNavigationBar` with four tabs: Home, Library, Progress, and Profile.
- **Page View:** A `PageController` manages the state of the bottom navigation bar, allowing users to swipe between screens.
- **Dynamic AppBar:** The `AppBar` title dynamically changes based on the selected tab.

### Placeholder Screens

- **HomeScreen:** Contains the AI-powered tools (Summary, Quiz, Flashcards).
- **LibraryScreen:** Displays the user's saved content.
- **ProgressScreen:** Shows user analytics.
- **ProfileScreen:** Displays user information and subscription status.

### Backend & Services

- **Firebase Integration:** The app is fully integrated with Firebase, including Firebase Core, Firebase Auth, and Cloud Firestore.
- **Firestore Service:** A `FirestoreService` manages all interactions with the Firestore database, including fetching user data and updating usage counts.
- **Daily Limits:** The app enforces daily usage limits for free-tier users and includes logic to reset these limits daily.

## Design

- **Material Design 3:** The app uses the latest Material Design 3 principles for a modern and visually appealing UI.
- **Typography:** `google_fonts` is used to implement a consistent and professional typography scheme with Oswald, Roboto, and Open Sans fonts.
- **Color Scheme:** A deep purple color scheme is used for both light and dark modes, with harmonious and accessible colors generated using `ColorScheme.fromSeed`.
- **Theming:** The app includes a centralized theme configuration with custom styles for app bars and elevated buttons.

## Project Structure

The project is organized into the following directories:

- `lib/models`: Contains the data models, such as `user_model.dart`.
- `lib/services`: Holds the business logic, including `auth_service.dart` and `firestore_service.dart`.
- `lib/utils`: Includes helper functions and utilities, such as `logger.dart`.
- `lib/views`: Contains the application's screens and widgets.

## Day 3 Plan: Summary Tool UI

- **New Screen:** Create a new `SummaryScreen` widget.
- **Input Methods:** Implement a multi-line `TextField` for text input and a button to upload a PDF file.
- **State Management:** The screen will manage different UI states: initial, loading, error, and success.
- **UI Components:**
    - A header with a title and subtitle.
    - A button to generate the summary, which will be disabled if there is no input.
    - A loading indicator to be displayed while the summary is being generated.
    - An error message with a retry button.
    - A card to display the generated summary with options to copy or save it.
- **File Picker:** Add the `file_picker` dependency to the project to enable PDF uploads.
- **Navigation:** The `HomeScreen` will be updated to navigate to the `SummaryScreen` when the summary tool is selected.
