# Expense Manager Tracker (Flutter)

A cross-platform mobile application built using Flutter to track daily expenses, analyze spending patterns, and manage budgets efficiently. This project aims to deliver a production-grade Personal Finance Management (PFM) system featuring a clean modular architecture and a premium glassmorphism UI.

## Key Features

- **Authentication & Security:** 
  - Firebase Authentication & Google Sign-in.
  - Session validation and App Lock Screen (Biometrics / PIN via `local_auth`).
  - Secure data storage using `flutter_secure_storage`.
- **Expense & Income Tracking:** Add, categorize, and track daily transactions.
- **Budget Planning:** Set and manage budgets for different categories.
- **Bill Management:** Track recurring bills and subscriptions.
- **Accounts Management:** Support for multiple accounts/wallets (e.g., Cash, Bank, Credit Card).
- **Insights & Analytics:** Interactive charts and visualizations using `fl_chart`.
- **Reports & Export:** Generate detailed reports and export them as PDF, CSV, or Excel formats.
- **Offline First & Cloud Sync:** Fast local data access using SQLite and seamless cloud synchronization with Firebase Firestore.
- **Notifications:** Local notifications for reminders and bill alerts.
- **Premium UI:** Dark-themed responsive design focusing on rich aesthetics and smooth interactions.

## Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Local Storage:** SQLite (`sqflite`), Shared Preferences
- **Cloud Services:** Firebase (Auth, Cloud Firestore)
- **Security:** `local_auth`, `flutter_secure_storage`
- **UI & Analytics:** `fl_chart`, `google_fonts`, `cupertino_icons`
- **Utilities:** `intl`, `csv`, `pdf`, `excel`, `image_picker`, `share_plus`

## Architecture overview

The application follows a modular and clean architecture pattern:
- **`core/`**: Contains core configurations, themes (`AppTheme`), and constants.
- **`features/`**: Modularized features containing their own logic and providers (e.g., `insights`, `reports`, `auth`).
- **`models/`**: Data models used throughout the application.
- **`providers/`**: Global state management providers for transactions, accounts, budgets, bills, and user sessions.
- **`screens/`**: UI screens including `ShellScreen`, `LoginScreen`, `LockScreen`, and `OnboardingScreen`.
- **`services/`**: Integration with native services like `NotificationService`.

## Screenshots

*(Add 4–5 app screenshots here to showcase the premium UI and charts)*

## Demo

*(Add APK / video link)*

## Installation

1. **Clone the repository**
   ```bash
   git clone <repo_url>
   cd expence_tracker_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Ensure you have the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) configured in the respective directories.

4. **Run the App**
   ```bash
   flutter run
   ```
