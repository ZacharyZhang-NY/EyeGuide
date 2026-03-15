<p align="center">
  <img src="https://img.shields.io/badge/iOS-Swift%20%7C%20SwiftUI-FA7343?style=flat-square&logo=swift&logoColor=white" alt="iOS">
  <img src="https://img.shields.io/badge/Android-Kotlin%20%7C%20Compose-7F52FF?style=flat-square&logo=kotlin&logoColor=white" alt="Android">
  <img src="https://img.shields.io/badge/AI-Google%20Gemini-4285F4?style=flat-square&logo=google&logoColor=white" alt="Gemini">
  <img src="https://img.shields.io/badge/Backend-Google%20Cloud%20Run-4285F4?style=flat-square&logo=googlecloud&logoColor=white" alt="Cloud Run">
  <img src="https://img.shields.io/badge/Database-Neon%20PostgreSQL-00E599?style=flat-square&logo=postgresql&logoColor=white" alt="Neon">
</p>

<h1 align="center">EyeGuide</h1>

<p align="center">
  <strong>AI-Powered Vision Assistant for the Visually Impaired</strong>
</p>

<p align="center">
  EyeGuide transforms your phone's camera into an intelligent guide — describing scenes, reading text, locating objects, and understanding social situations in real time through natural speech.
</p>

---

## Features

### Scene Description
Point your camera and hear a natural description of your surroundings. EyeGuide identifies obstacles, pathways, vehicles, and landmarks to help you navigate safely.

### Text Reading
Read signs, menus, mail, and documents aloud. Capture an image and EyeGuide reads every word in natural, conversational speech.

### Object Finder
Tell EyeGuide what you're looking for — keys, phone, door — and receive directional guidance with approximate distance.

### Social Assist
Understand social situations with confidence. EyeGuide describes people, expressions, body language, and group dynamics.

### Real-Time Voice Guide
Continuous AI-powered guidance via live camera streaming and WebSocket, with bidirectional voice interaction.

---

## Architecture

```
┌──────────────────────────────────┐
│   iOS App          Android App   │
│   Swift/SwiftUI    Kotlin/Compose│
│   MVVM + @Observable  MVVM + Hilt│
└──────────┬───────────┬───────────┘
           │  REST /   │  WebSocket
           ▼           ▼
┌──────────────────────────────────┐
│   Backend API                    │
│   Google Cloud Run + Hono.js     │
│   Neon PostgreSQL                │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│   Google Gemini 2.5 Flash        │
│   REST API + Live WebSocket      │
└──────────────────────────────────┘
```

---

## Project Structure

```
EyeGuide/
├── EyeGuideiOS/          # Native iOS app (Swift, SwiftUI)
│   ├── Models/            # Data structures
│   ├── Services/          # Camera, Speech, Gemini, API
│   ├── ViewModels/        # MVVM state management
│   └── Views/             # SwiftUI screens & components
│
├── EyeGuideAndroid/       # Native Android app (Kotlin, Compose)
│   └── app/src/main/java/
│       ├── data/           # Models, API, repositories
│       ├── di/             # Hilt dependency injection
│       ├── ui/             # Compose screens & viewmodels
│       └── util/           # Device ID, speech helpers
│
├── EyeGuideBackend/       # Serverless API (TypeScript)
│   └── src/
│       ├── routes/         # users, sessions, usage, ai
│       ├── middleware/     # auth, cors
│       └── db/             # Neon PostgreSQL client
│
└── EyeGuideLanding/       # Landing page (Vite + Tailwind)
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **iOS** | Swift, SwiftUI, AVFoundation, Speech framework |
| **Android** | Kotlin, Jetpack Compose, CameraX, Hilt |
| **Backend** | TypeScript, Hono.js, Google Cloud Run |
| **Database** | Neon (serverless PostgreSQL) |
| **AI** | Google Gemini 2.5 Flash, Gemini Live WebSocket |
| **Landing Page** | Vite, Tailwind CSS |

---

## Getting Started

### Prerequisites

- **iOS**: Xcode 15+, iOS 17+
- **Android**: Android Studio, SDK 24+ (Android 7.0)
- **Backend**: Node.js 18+, gcloud CLI

### iOS

```bash
cd EyeGuideiOS
open EyeGuide.xcodeproj
# Build and run on a physical device (camera required)
```

### Android

```bash
cd EyeGuideAndroid
# Open in Android Studio, sync Gradle, run on a physical device
```

### Backend

```bash
cd EyeGuideBackend
npm install
cp .dev.vars.example .env        # Add your API keys
npm run dev                      # Local development
gcloud run deploy eyeguide-api --source=. --region=us-central1  # Deploy to Cloud Run
```

---

## Accessibility

EyeGuide is built accessibility-first:

- Full **VoiceOver** (iOS) and **TalkBack** (Android) support
- All controls have semantic labels and descriptions
- **Haptic feedback** for state changes and confirmations
- **High contrast mode** for users with partial vision
- **Adjustable voice** speed and pitch
- **Multiple detail levels** — concise, standard, or detailed descriptions
- **Bilingual** — English and Chinese

---

## License

This project is for educational and demonstration purposes.

---

<p align="center">
  Built with care for accessibility.
</p>
