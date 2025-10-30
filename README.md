# MyCloudBook

MyCloudBook transforms handwritten notes into smart digital content. Students upload daily notebook pages creating timeline views, attach rough work for practice, and use Gemini AI for handwriting-to-text conversion, summarization, flashcards, and real-time collaborative editing on a secure cloud platform.

## 🚀 Features

- 📝 **Note Management**: Upload handwritten pages via camera or gallery
- 🎨 **Timeline View**: Organize notes with visual date markers
- 📄 **Rough Work Pages**: Attach scratchpad pages for practice
- 🤖 **AI Integration**: Google Gemini AI for handwriting recognition, summarization, and flashcards
- 👥 **Collaboration**: Real-time multi-user editing and chat
- 📱 **Offline Support**: Automatic sync when online
- 📊 **Quota Management**: Free tier with 100 pages/month, 5GB storage
- 🔔 **Push Notifications**: Quota alerts and collaboration updates
- 🔒 **Security**: Encrypted API keys and two-factor authentication

## 📚 Documentation

- **SRS Document**: [SRS.md](SRS.md) - Software Requirements Specification
- **Technical Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed system architecture
- **SRS Review**: [SRS_REVIEW.md](SRS_REVIEW.md) - Comprehensive review and recommendations
- **Setup Guide**: [SETUP.md](SETUP.md) - Step-by-step setup instructions

## 💰 Pricing

**Free Tier:**
- 100 pages/month with AI processing
- 5GB storage per user
- User-provided Gemini API keys (no platform costs)
- Basic features included

**Premium Tier (Coming Soon):**
- Unlimited pages per month
- 50GB+ storage
- Advanced AI features
- Priority support

## 🛠️ Tech Stack

- **Frontend**: Flutter/Dart
- **Backend**: Supabase (PostgreSQL)
- **AI**: Google Gemini API
- **Storage**: Supabase Storage
- **Notifications**: Firebase Cloud Messaging
- **State Management**: BLoC Pattern
- **Local Storage**: Hive + SQLite

## 🏃‍♂️ Getting Started

### Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Git

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/MyCloudBook.git
cd MyCloudBook
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Supabase:
   - Create a free account at [supabase.com](https://supabase.com)
   - Create a new project
   - Run the SQL schema from `SETUP.md`
   - Get your API keys

4. Set up Firebase:
   - Create a free account at [firebase.google.com](https://firebase.google.com)
   - Add Flutter app to project
   - Configure for Android/iOS/Web

5. Configure the app:
   - Update `lib/core/config/app_config.dart` with your Supabase credentials
   - Add Firebase config files to platform folders

6. Run the app:
```bash
flutter run
```

For detailed setup instructions, see [SETUP.md](SETUP.md).

## 📖 Architecture

The app follows a clean architecture pattern:

```
lib/
├── core/          # Configuration, theme, utilities
├── data/          # Models, repositories, data sources, services
├── domain/        # Business logic
└── presentation/  # UI (screens, widgets, BLoCs)
```

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web

## 🔐 Security

- Encrypted Gemini API key storage
- Row Level Security (RLS) on all database tables
- Two-factor authentication
- Secure password hashing
- GDPR compliant

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines and code of conduct before submitting PRs.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support, email support@mycloudbook.com or open an issue on GitHub.

---

**Made with ❤️ for students and professionals**
