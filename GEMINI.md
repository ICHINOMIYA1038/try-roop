# Project Context: tryroop_campus_live_flutter

## Overview
This is a Flutter-based mobile application for an online salon membership platform. It provides video streaming (via YouTube embedding), course management, community features, and user progress tracking. The app is designed to work with Firebase for backend services and RevenueCat for subscription management.

## Architecture

### Tech Stack
-   **Frontend:** Flutter (Dart)
-   **Backend:** Firebase (Authentication, Cloud Firestore)
-   **State Management:** Riverpod
-   **Routing:** GoRouter
-   **Video Player:** `youtube_player_flutter` (YouTube Embedded)
-   **Subscriptions:** RevenueCat (`purchases_flutter`)
-   **UI Components:** Material Design 3

### Core Features
1.  **Authentication:** Email/Password, Google Sign-In, Apple Sign-In (via Firebase Auth).
2.  **Video Streaming:** YouTube videos embedded with chapter support and premium/free access levels.
3.  **Course Management:** Structured courses with progress tracking.
4.  **Community:** Forum-like features for user interaction.
5.  **Text Lessons:** Markdown-based text content.
6.  **Gamification:** Badges and learning dashboard.

## Key Directories & Files

-   `lib/main.dart`: Application entry point. Handles Firebase/RevenueCat initialization and sets up the root provider scope.
-   `lib/router.dart`: Defines the app's navigation structure using GoRouter, including auth guards.
-   `lib/models/`: Data models (e.g., `AppUser`, `Course`, `Video`, `Chapter`).
-   `lib/providers/`: Riverpod providers for state management.
-   `lib/screens/`: UI screens organized by feature (auth, home, video, course, community, etc.).
-   `lib/services/`: Services for external APIs (Auth, Firestore, Subscription).
-   `docs/architecture.md`: Detailed system design document (in Japanese).

## Development Setup

### Prerequisites
-   Flutter SDK
-   Firebase Project
-   RevenueCat Account

### Running the App
1.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

2.  **Firebase Setup (Required for full functionality):**
    -   Install Firebase CLI and FlutterFire CLI.
    -   Run `flutterfire configure` to generate `lib/firebase_options.dart`.

3.  **Run:**
    ```bash
    flutter run
    ```
    *Note: The app has a `isDemoMode` flag in `lib/main.dart`. If Firebase fails to initialize, it falls back to a demo mode.*

### Testing
-   Run unit/widget tests:
    ```bash
    flutter test
    ```

## Coding Conventions
-   **State Management:** Use `ConsumerWidget` and `ref.watch`/`ref.read` from Riverpod.
-   **Routing:** Use `context.go()` or `context.push()` with named routes or paths defined in `router.dart`.
-   **Styling:** Follow Material 3 guidelines.
-   **Async Operations:** Handle loading and error states in UI (often using `AsyncValue` from Riverpod).
