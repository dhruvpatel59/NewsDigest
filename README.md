# Pulse News AI 📰✨

**Pulse News AI** is a premium iOS application designed to transform how you consume news. By combining real-time global journalism with Google’s Gemini AI, Pulse delivers insightful, unbiased, and personalized news briefings directly to your palm.

![Project Status](https://img.shields.io/badge/Status-Production--Ready-success)
![Platform](https://img.shields.io/badge/Platform-iOS-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🌟 Key Features

*   **AI Pulse 360**: Multi-dimensional analysis of news stories covering Sentiment, Bias, and Global Impact.
*   **Audio Briefing Personas**: Personalized AI anchors that narrate news summaries in real-time.
*   **Resilient AI Engine**: Intelligent model rotator (Gemini 2.5/2.0/1.5) with automatic fallback and rate-limit handling.
*   **Secure Secrets Management**: Git-ignored credential management via `Secrets.plist` and Actor-based `StorageManager`.
*   **Modern UX**: Glassmorphic UI, rich haptics, and adaptive dark/light mode support.

---

## 🛠 Tech Stack

*   **UI**: SwiftUI
*   **AI Engine**: Google Gemini API (v1beta/v1)
*   **Networking**: Combine & Async/Await
*   **Persistence**: Actor-based File Storage & Keychain
*   **Feedback**: Haptic Engine (CoreHaptics)

---

## 🚀 Getting Started

### Prerequisites
*   Xcode 16.0+
*   iOS 17.0+
*   Google Gemini API Key ([Get one here](https://aistudio.google.com/))
*   GNews API Key ([Get one here](https://gnews.io/))

### Installation & Setup

1.  **Clone the Repo**:
    ```bash
    git clone https://github.com/YOUR_USERNAME/MyFirstApp.git
    cd MyFirstApp
    ```

2.  **Configure Secrets**:
    - Locate the `.env.example` file in the root.
    - Create a new file named `Secrets.plist` inside `MyFirstApp/Resources/`.
    - Populate it with your keys following this structure:
    ```xml
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>GEMINI_API_KEY</key>
        <string>YOUR_KEY_HERE</string>
        <key>GNEWS_API_KEY</key>
        <string>YOUR_KEY_HERE</string>
    </dict>
    </plist>
    ```

3.  **Build and Run**:
    Open `MyFirstApp.xcodeproj` and hit `Cmd + R`.

---

## 📁 Project Structure

```text
PulseNewsAI/
├── App/                # Main Entry Point & Tab Controller
├── Features/           # Feed, Explore, Profiles, Broadcaster Views
├── Services/           # AI, Network, Audio, & RSS Providers
├── Core/               # Data Models, Managers, & AppConfig
├── Utilities/          # Extensions & Helpers
└── Resources/          # Assets, Fonts, & Plists
```

---

## 🛡️ Security

This repository uses a strict security policy. Hardcoded keys are **forbidden**. All sensitive environment variables are loaded dynamically from `Secrets.plist`, which is excluded from version control via `.gitignore`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

---
*Created with ❤️ by Dhruv Patel*
