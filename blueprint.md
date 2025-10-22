# SumQuiz Blueprint

## Overview

SumQuiz is a cross-platform application (mobile, web, and desktop) that uses AI to generate summaries, quizzes, and flashcards from user-provided text. It includes a spaced repetition system to help users learn and retain information.

## Features

### Core Features

*   **AI-Powered Content Generation:**
    *   Generate summaries from text.
    *   Generate quizzes from text.
    *   Generate flashcards from text.
*   **Library:**
    *   Save summaries, quizzes, and flashcards to a local library.
    *   Organize content into folders.
*   **Spaced Repetition:**
    *   Review flashcards using a spaced repetition algorithm.
*   **User Accounts:**
    *   Sign up and sign in with email and password.
    *   Sync data across devices (not yet implemented).

### Redesigned Profile Screen (Clarity & Conversion Focus)

*   **Visual Theme:**
    *   **Color Palette:** White background (#FFFFFF), Black text (#000000), Light Gray dividers (#E0E0E0).
    *   **Font:** Poppins or Inter, implemented via `google_fonts`.
    *   **Layout:** Clean vertical stack with generous padding and balanced whitespace.

*   **Layout Structure:**
    *   **Header Section:**
        *   Centered placeholder avatar (gray circle with user initials or icon).
        *   User Name (Bold black text).
        *   Email / Username (Smaller, light gray text).
        *   Optional tag chip for plan status (e.g., "Free Plan" or "Pro User").
    *   **Stats Section (Progress Overview):**
        *   Three simple cards/boxes for "Quizzes Taken," "Average Score," and "Best Score."
        *   Minimalist design with bold numbers and small labels.
    *   **Upgrade Section:**
        *   Prominent, full-width "Upgrade to Pro" button with a black background and white text.
        *   Subtext: "Unlock unlimited quizzes and summaries."
    *   **Footer:**
        *   Simple, centered "Log Out" text button.

*   **Behavior & Animations:**
    *   Subtle fade-in animations for avatar and stats.
    *   Standard Material ripple effects on buttons.

### Settings

*   **Account:**
    *   View user account information (name and email).
    *   Sign out.
*   **Preferences:**
    *   Toggle between light and dark mode.
    *   Adjust the font size (small, medium, large).
*   **Data & Storage:**
    *   Clear all local data and cache.
    *   Manage offline files (view and delete summaries, quizzes, and flashcard sets).
*   **Subscription:**
    *   View the user's current subscription plan (Free or Pro).
    *   View a pricing table with the features of each plan.

---

## Current Task: Add Web & Desktop Support

### Plan Overview

1.  **Enable Web & Desktop Support:** Add the necessary configuration files and folders for web, Windows, macOS, and Linux to the project.
2.  **Implement Responsive UI:** Refactor the main navigation to be responsive.
    *   **Narrow Screens (Mobile):** Use the existing `BottomNavigationBar`.
    *   **Wide Screens (Web/Desktop):** Switch to a `NavigationRail` for a better user experience on larger displays.
3.  **Address Platform-Specifics:** Update Firebase App Check configuration for the web version.

### Steps

1.  **Enable Platforms:**
    *   Run `flutter create --platforms=web,windows,macos,linux .` to add desktop and web support.
2.  **Refactor Main Screen:**
    *   Modify `lib/views/screens/main_screen.dart` to use a `LayoutBuilder`.
    *   The `LayoutBuilder` will conditionally render either a `BottomNavigationBar` or a `NavigationRail` based on the screen width.
3.  **Firebase Configuration:**
    *   Instruct the user to add a reCAPTCHA v3 site key to `web/index.html` to ensure Firebase App Check works on the web.

