# SumQuiz Blueprint

## Overview

SumQuiz is a mobile application that allows users to create, study, and share quizzes and flashcards. The app is built with Flutter and uses Firebase for backend services.

## Implemented Features

### Core Features

*   **User Authentication**: Users can sign up and sign in using email and password or Google Sign-In.
*   **Quiz Creation**: Users can create quizzes with multiple-choice questions.
*   **Flashcard Creation**: Users can create flashcard sets.
*   **Content Library**: Users can browse and manage their created content.
*   **AI-Powered Tools**: The app integrates with AI services to provide features like quiz generation from text.
*   **Spaced Repetition**: The app includes a spaced repetition system to help users study more effectively.
*   **Progress Tracking**: Users can track their progress and performance on quizzes.
*   **Referral System**: Users can refer friends to earn rewards.
*   **Subscription Model**: The app offers a "Pro" subscription that unlocks additional features.

### Technical Details

*   **State Management**: The app uses `provider` for state management.
*   **Routing**: The app uses `go_router` for navigation.
*   **Local Storage**: The app uses `hive` for local data persistence.
*   **Backend**: The app uses Firebase for authentication, Firestore, and Cloud Functions.
*   **In-App Purchases**: The app uses the `in_app_purchase` package to manage subscriptions.

### Profile Screen Revamp

*   **Redesigned UI**: The profile screen has been completely redesigned with a clean, modern, and intuitive list-based layout.
*   **Centralized Header**: A new header displays the user's avatar, name, and email in a clear and organized manner.
*   **Integrated Pro Status**: The `ProStatusWidget` is now used to display the user's subscription status. Tapping this widget takes the user to the subscription page, consolidating the call-to-action.
*   **Navigation Menu**: A new menu provides quick access to:
    *   Account Settings
    *   Refer a Friend
    *   App Settings
*   **Improved Sign-Out**: A more prominent and user-friendly sign-out button is located at the bottom of the screen.

### Referral Screen Revamp

*   **Engaging Header**: A new, visually appealing header with an icon and a clear title has been added.
*   **Interactive Referral Code**: A dedicated section for the referral code allows users to easily copy and share it.
*   **Clearer Instructions**: The "How it Works" section has been redesigned with more distinct and easy-to-read steps, each with its own icon.
*   **Modern Styling**: The screen now has a more polished and modern look and feel with improved spacing, typography, and iconography.

### Subscription Screen Revamp

*   **Compelling Header**: A new header with a gradient background, a prominent icon, and a strong headline has been added to capture user attention.
*   **Redesigned Plan Cards**: The plan cards have been redesigned to be more visually appealing and easier to compare, with a clear highlight for the "Best Value" option.
*   **Improved Feature List**: The feature list is now more scannable and engaging, using icons to highlight each benefit.
*   **Enhanced Call-to-Action**: The "Upgrade to Pro" button is larger, more prominent, and more visually appealing.
*   **Restore Purchases Link**: A "Restore Purchases" link has been added, which is a standard and necessary feature for any app with in-app purchases.

## Current Task: Fix Reactive "Pro" Status UI

This task is complete. The bug is fixed, and several key screens have been redesigned for a better user experience.
