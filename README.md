# 🎓 IELTS Prep App

A full-featured Flutter mobile app for IELTS exam preparation, inspired by ieltsonlinetests.com.

---

## 📱 Features

### ✅ Free Mock Tests (All 4 Skills)
- **Listening** – Simulated audio player with fill-in-the-blank and MCQ questions
- **Reading** – Full passage + questions with toggle view, T/F/NG, matching, MCQ
- **Writing** – Task 1 & Task 2 editor with word counter and 60-minute countdown timer
- **Speaking** – Part 1/2/3 recorder interface with optional transcript input

### 🤖 AI Examiner Feedback
- Powered by **Google Gemini AI** (free tier)
- Evaluates writing and speaking responses
- Returns: Overall Band Score, Grammar, Vocabulary, Coherence, Pronunciation scores
- Lists Strengths and Areas to Improve with examples
- Provides an improved sample opening

### 🎓 Live Lessons
- Upcoming, Live Now, and Recorded lessons
- Filter by skill (Listening, Reading, Writing, Speaking)
- Lesson detail with video placeholder (connect to YouTube/Vimeo/Agora)
- Red "LIVE NOW" banner for active lessons

### 📊 Progress Tracking
- Overall Band Score across all skills
- Band score progression charts (using fl_chart)
- Weekly study activity chart
- Per-skill score history and trend
- Focus areas / weaknesses highlighted
- Test history tab showing all past results

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.x (`flutter --version`)
- Android Studio or VS Code with Flutter extension
- Android SDK (for Android) or Xcode (for iOS)

### Installation

```bash
# 1. Open project in terminal
cd ielts_prep_app

# 2. Install dependencies
flutter pub get

# 3. Run on Android emulator or device
flutter run

# 4. Build APK
flutter build apk --release
```

### Configure AI Feedback (Optional)

1. Get a free Google Gemini API key from https://makersuite.google.com/app/apikey
2. Open `lib/services/ai_examiner_service.dart`
3. Replace `'YOUR_GEMINI_API_KEY'` with your actual key:

```dart
static const String _apiKey = 'YOUR_ACTUAL_KEY_HERE';
```

> **Without an API key**, the app uses realistic demo feedback automatically.

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry, routing, theme
├── models/
│   └── models.dart              # All data models
├── providers/
│   ├── auth_provider.dart       # Auth state
│   ├── test_provider.dart       # Tests + results state
│   └── progress_provider.dart  # Progress state
├── services/
│   ├── mock_data_service.dart   # Sample tests, lessons, progress
│   └── ai_examiner_service.dart # Gemini AI integration
└── screens/
    ├── splash_screen.dart
    ├── onboarding_screen.dart
    ├── home_screen.dart          # Main nav + dashboard
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── tests/
    │   ├── test_library_screen.dart
    │   ├── test_detail_screen.dart
    │   ├── listening_test_screen.dart
    │   ├── reading_test_screen.dart
    │   ├── writing_test_screen.dart
    │   ├── speaking_test_screen.dart
    │   └── results_screen.dart
    ├── ai_feedback/
    │   └── ai_examiner_screen.dart
    ├── live_lessons/
    │   ├── live_lessons_screen.dart
    │   └── lesson_detail_screen.dart
    ├── progress/
    │   └── progress_screen.dart
    └── profile/
        └── profile_screen.dart
```

---

## 🔧 Extending the App

### Connect Real Audio for Listening Tests
Replace the simulated audio timer in `listening_test_screen.dart` with:
```dart
// Using audioplayers package (already in pubspec)
final player = AudioPlayer();
await player.play(AssetSource('audio/listening_s1.mp3'));
```

### Connect Real Live Streams
In `lesson_detail_screen.dart`, replace the video placeholder with:
```dart
// Using chewie + video_player (already in pubspec)
VideoPlayerController.network(lesson.streamUrl!)
```

### Add a Real Backend
Replace `MockDataService` calls with HTTP requests using the included `dio` package:
```dart
final response = await dio.get('https://your-api.com/tests');
```

---

## 📦 Key Dependencies
| Package | Purpose |
|---|---|
| `provider` | State management |
| `go_router` | Navigation |
| `shared_preferences` | Local persistence |
| `fl_chart` | Band score charts |
| `audioplayers` | Audio playback |
| `video_player` + `chewie` | Video lessons |
| `google_generative_ai` | AI feedback |
| `http` | API calls |

---

## 🎨 Color Scheme
- **Listening**: `#1A73E8` (Google Blue)
- **Reading**: `#34A853` (Google Green)  
- **Writing**: `#FF6B35` (Orange)
- **Speaking**: `#9C27B0` (Purple)
- **AI Examiner**: `#6200EE` (Deep Purple)

---

## 📄 License
Built for educational purposes. IELTS is a registered trademark of the British Council, IDP, and University of Cambridge.
