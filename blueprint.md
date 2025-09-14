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

### AI-Powered Tools

- **Summary Tool:** Integrated with a Google AI endpoint to generate summaries from text and PDFs. Includes usage limits and a "Save to Library" feature.
- **Quiz Tool:** Integrated with a Google AI endpoint to generate multiple-choice quizzes from text. Includes usage limits and a "Save to Library" feature.
- **Flashcards Tool:** Integrated with a Google AI endpoint to generate flashcards from text. Includes usage limits and a "Save to Library" feature.

### Library Screen

- **Tabbed Navigation:** The Library screen features a `TabBar` with three tabs: "Summaries", "Quizzes", and "Flashcards".
- **Real-time Data:** Each tab displays a real-time list of the user's saved content from Firestore.
- **Creation Flow:** A "Create New" button allows users to create new content, with usage limits enforced for free users.

### Progress Screen

- **Real-time Analytics:** The Progress screen displays real-time analytics data from Firestore, including total content created and weekly activity.
- **Pro Subscription Lock:** Access to the Progress screen is restricted to Pro users, with a modal prompting free users to upgrade.

### Backend & Services

- **Firebase Integration:** The app is fully integrated with Firebase, including Firebase Core, Firebase Auth, and Cloud Firestore.
- **Firestore Service:** A `FirestoreService` manages all interactions with the Firestore database, including fetching user data, updating usage counts, and saving generated content.
- **Daily Limits:** The app enforces daily usage limits for free-tier users and includes logic to reset these limits daily.

## Design

- **Material Design 3:** The app uses the latest Material Design 3 principles for a modern and visually appealing UI.
- **Typography:** `google_fonts` is used to implement a consistent and professional typography scheme.
- **Color Scheme:** A deep purple color scheme is used for both light and dark modes.
- **Theming:** The app includes a centralized theme configuration with custom styles for app bars and elevated buttons.

## Project Structure

The project is organized into logical directories for models, services, views, and utilities to ensure a clean and maintainable codebase.

## Day 12 Plan: Offline Library Access

- **Enable Firestore Offline Persistence:**
    - Leverage Firestore's built-in offline caching to allow users to access their library content without an internet connection.
    - This approach avoids the need for a separate local database and manual synchronization.
- **Network Status Monitoring:**
    - Add the `connectivity_plus` package to monitor the device's network status.
    - Display a banner in the Library screen to inform the user when they are offline.
- **Offline Functionality:**
    - Ensure that users can view their saved summaries, quizzes, and flashcards while offline.
    - New content created offline will be automatically saved to the local cache and synced with Firestore when the connection is restored.
- **UI/UX Enhancements:**
    - The UI will remain responsive, with loading indicators for data fetching and a non-intrusive offline banner.
