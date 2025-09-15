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
- **Offline Access:** The Library screen is fully functional offline, with data automatically cached and synced with Firestore when the connection is restored.

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

## Day 13 Plan: Payments & Subscriptions

- **Google Play Billing (Android):**
    - Add the `in_app_purchase` package to handle mobile payments.
    - Configure subscription products (`sumquiz_pro_monthly`, `sumquiz_pro_yearly`) in the Google Play Console.
    - Implement a purchase flow that allows users to upgrade to a Pro plan.
- **Stripe/Firebase (Web):**
    - Integrate Stripe Checkout using the `firestore-stripe-payments` Firebase Extension for web-based payments.
    - Create corresponding subscription products in Stripe.
- **Firestore Sync:**
    - Upon successful payment, update the user's document in Firestore with their subscription status (`isPro: true`, `subscription: 'pro'`), plan, and `upgradedAt` timestamp.
    - All subscription checks will read from Firestore to ensure a consistent experience across all devices.
- **Upgrade Flow:**
    - Connect all "Upgrade" buttons to a new subscription screen that presents the available plans.
    - Handle the purchase flow for both mobile and web platforms.
- **Usage Counter Reset:**
    - When a user upgrades, their daily usage counters will be reset to 0, and the `canGenerate` method will be updated to grant unlimited access to Pro users.
- **UI/UX Polish:**
    - A success dialog will be displayed after a successful purchase.
    - A "Pro" badge will be displayed on the profile screen for Pro users.
    - "Upgrade" buttons will be hidden for Pro users.
