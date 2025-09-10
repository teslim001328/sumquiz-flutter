# SumQuiz App Blueprint

## Overview

SumQuiz is a mobile application designed to help users summarize text, create quizzes, and generate flashcards. The app is built with Flutter and leverages Firebase for authentication and database services. The primary goal is to provide a seamless and intuitive user experience with a modern and professional design.

## Implemented Features

### Authentication

- **Email/Password:** Users can sign up and log in using their email and password.
- **Google Sign-In:** Users can sign in with their Google account for a faster and more convenient experience.
- **User Model:** A `UserModel` class is defined to represent user data in Firestore.
- **Auth Service:** An `AuthService` handles all authentication logic, including creating user documents in Firestore upon successful sign-up.

### Dashboard

- **Real-time Data:** The dashboard displays the user's name, subscription status, and daily usage in real-time using a `StreamBuilder` connected to Firestore.
- **User Info:** A user information card displays the user's name, email, and subscription status.
- **Usage Tracking:** A usage card shows the user's daily usage for summaries, quizzes, and flashcards, along with the remaining daily limits.
- **Navigation:** The dashboard includes a navigation section with placeholders for future screens.

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
- `lib/views`: Contains the application's screens and widgets, such as `auth_screen.dart` and `dashboard_screen.dart`.

## Day 2 Plan

- **Bottom Navigation:** Implement a `BottomNavigationBar` with four tabs: Home, Library, Progress, and Profile.
- **Placeholder Screens:** Create placeholder screens for each tab:
    - `HomeScreen`: Will contain the AI-powered tools (Summary, Quiz, Flashcards).
    - `LibraryScreen`: Will display the user's saved content.
    - `ProgressScreen`: Will show user analytics.
    - `ProfileScreen`: Will display user information and subscription status.
- **Reusable Widgets:** Create reusable widgets for the AI tool buttons on the `HomeScreen`.
- **State Management:** Use a `PageController` to manage the state of the bottom navigation bar.
- **AI Placeholders:** Add placeholder functions for the AI tools to be implemented later.
- **Dynamic AppBar:** The `AppBar` title will dynamically change based on the selected tab.

