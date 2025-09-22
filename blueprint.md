# Project Blueprint

## Overview

This is a Flutter application that provides study tools for students. It uses Firebase for authentication and generative AI features.

## Current Status

The application is currently in a broken state due to a number of issues, primarily related to package upgrades and API changes.

### Issues

*   **`google_sign_in` package:** The `signInWithGoogle` method in `lib/services/auth_service.dart` is using an outdated API for the `google_sign_in` package.
*   **`firebase_vertexai` package:** The application was using the `firebase_vertexai` package, which has been replaced by `firebase_ai`.

## Plan

My plan to fix the application is as follows:

1.  **Update `pubspec.yaml`**: I have upgraded all the firebase packages to their latest major versions to resolve dependency conflicts.
2.  **Correct `auth_service.dart`**: I have rewritten the `signInWithGoogle` method in `lib/services/auth_service.dart` to use the correct, up-to-date API for the `google_sign_in` package.
3.  **Clean and rebuild**: I have run `flutter clean` and `flutter pub get` to apply the changes and rebuild the project.
4.  **Run the app**: I will now run the application to verify the fixes.
