# magtapp_ai_browser

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.




# SDE 2 Flutter Assignment - MagTapp AI Browser

## Project Overview
This project is a high-performance, cross-platform Flutter application that integrates a multi-tab web browser with AI-powered document summarization, translation, and local file management. It is designed to demonstrate scalable architecture, efficient state management, and seamless integration of third-party native features like WebViews and Speech-to-Text.

## Technical Stack
* Framework: Flutter 3.x (Stable)
* State Management: Riverpod (Functional Reactive Programming)
* Local Database: Hive (NoSQL for high-speed persistence)
* Browser Engine: flutter_inappwebview
* AI Integration: REST API for Summarization and Translation
* File Management: Path Provider, File Picker, and PDF Generation
* Platform Support: Android, iOS, and Web (PWA ready)



## Architecture Overview
The application follows Clean Architecture principles to ensure a strict separation of concerns:

1. Domain Layer: Contains pure Dart entities (BrowserTab, FileEntity) and business logic definitions.
2. Data Layer: Handles data persistence via Hive and manages external API communications through Repositories.
3. Presentation Layer: Manages UI state using Riverpod Notifiers and provides a responsive user interface with modular widgets.

## Key Features

### 1. Advanced In-App Browser
* Multi-tab Support: Concurrent management of multiple web sessions with a custom tab switcher.
* Session Persistence: Automatic saving and restoration of all open tabs and the last active index using Hive.
* Dynamic Navigation: Chrome-inspired UI transitions where the search bar moves from the center to the top upon navigation.
* Speech-to-Text: Integrated voice-to-search functionality for hands-free URL entry and search queries.



### 2. AI Summarization and Translation
* Web Content Extraction: Custom JavaScript injection for DOM parsing to extract clean text from active web pages.
* Local Document Analysis: Ability to extract text from local PDFs and generate concise summaries via a dedicated AI service.
* Multilingual Support: Real-time translation of summaries into English, Hindi, and Spanish using localized string maps.
* PDF Export: Summarized reports can be exported and saved as professionally formatted PDF documents locally.

### 3. Smart File and History Manager
* Deduplicated History: Upsert logic ensures that visited URLs update their timestamps instead of creating duplicate entries in the logs.
* Local Workspace: Centralized management of downloaded documents and generated AI reports with metadata tracking (size, date, type).
* Offline Access: Previously summarized content and cached metadata are accessible without an internet connection using local storage persistence.



## Installation and Setup

### Prerequisites
* Flutter SDK (Latest Stable)
* Android Studio / Xcode
* Android SDK 34 (Required for modern plugin compatibility)


get token
Getting Hugging Face API Token

This project uses Hugging Face Inference APIs.
You must create a Hugging Face access token to run the app.

Step 1: Create Hugging Face account
https://huggingface.co/join

Step 2: Generate access token

Go to https://huggingface.co/settings/tokens

Click on "New token"

Select permission: Read

Create token

Copy the token (it starts with hf_)

### Run Instructions
1. Clone the repository to your local machine.
2. Run "flutter pub get" in the terminal to install all dependencies.
3. Ensure an emulator or physical device is connected.
4. Run "flutter run" to launch the application.

## API and Data Flow
1. Data Ingestion: Text is extracted from the Web DOM or a Local File.
2. Processing: Cleaned text is sent to the AI Service Provider via secure asynchronous HTTP calls.
3. Persistence: Results are mapped to Domain Entities and stored in specialized Hive boxes.
4. UI Update: Riverpod Notifiers detect state changes and trigger a partial rebuild of the UI to display the AI results.



## Future Improvements
* On-Device LLM: Integrating Google AICore or Gemma for local, private summarization without API dependency.
* Advanced Caching: Implementing a proxy-level cache for faster web page re-loads in low connectivity areas.
* Biometric Security: Protecting the local workspace and history with fingerprint or face recognition.

## Developer
Mayur Bobade
Software Engineer (Flutter)