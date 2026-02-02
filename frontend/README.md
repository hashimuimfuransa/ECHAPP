# ExcellenceCoachingHub Flutter Frontend

## Overview
This is the Flutter frontend for ExcellenceCoachingHub, a comprehensive e-learning platform that works on Android, iOS, Windows, macOS, and Linux.

## Features
- Clean, modern UI with Material Design 3
- Riverpod state management
- Responsive design for all platforms
- Secure authentication with JWT tokens
- Course browsing and enrollment
- Video streaming with Cloudflare Stream
- Exam and quiz system
- Mobile money payments (MTN MoMo, Airtel Money)
- Dark/light theme support

## Technology Stack
- **Flutter** - Cross-platform framework
- **Riverpod** - State management
- **Go Router** - Navigation
- **HTTP** - API communication
- **Shared Preferences** - Local storage
- **Flutter Secure Storage** - Secure token storage
- **Video Player** - Video playback
- **Chewie** - Video player UI

## Project Structure
```
lib/
├── config/
│   ├── api_config.dart
│   └── app_theme.dart
├── data/
│   ├── models/
│   │   ├── user.dart
│   │   └── course.dart
│   └── repositories/
├── presentation/
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── screens/
│   │   └── auth/
│   │       └── login_screen.dart
│   ├── widgets/
│   └── router/
├── main.dart
└── ...
```

## Getting Started

### Prerequisites
1. Install Flutter SDK (3.0.0 or higher)
2. Install Android Studio or VS Code with Flutter extensions
3. Set up device emulators or physical devices

### Installation

1. Clone the repository
2. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate code (for Freezed models):
   ```bash
   flutter pub run build_runner build
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Supported Platforms
- Android (API 21+)
- iOS (12.0+)
- Windows (7+)
- macOS (10.14+)
- Linux (Ubuntu 18.04+)

## Development Setup

### Environment Configuration
Create a `.env` file in the root directory:
```
API_BASE_URL=http://localhost:5000/api
```

### Code Generation
This project uses Freezed for data models. After making changes to model files, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture

### State Management
- **Riverpod** for application state
- **Providers** for business logic
- **StateNotifier** for complex state management

### Navigation
- **Go Router** for declarative routing
- Type-safe navigation
- Deep linking support

### Data Layer
- **Repositories** for data access
- **Models** with Freezed for immutable data
- **API Services** for HTTP communication

## Screens

### Authentication
- Login Screen
- Register Screen
- Forgot Password Screen

### Main App
- Dashboard/Home Screen
- Course Listing Screen
- Course Detail Screen
- Learning Screen
- Exam Screen
- Payment Screen
- Profile Screen

### Admin (if applicable)
- Admin Dashboard
- Course Management
- User Management
- Analytics

## Security Features

1. **Secure Token Storage**: Tokens stored in secure storage
2. **JWT Authentication**: Token-based authentication
3. **Input Validation**: Form validation and sanitization
4. **HTTPS**: Secure API communication
5. **Role-based Access**: Different UI based on user roles

## Customization

### Theme
Modify `lib/config/app_theme.dart` to customize:
- Colors
- Typography
- Component styles
- Dark/light themes

### API Configuration
Update `lib/config/api_config.dart` for:
- Base URL
- Endpoint paths
- Timeout settings

## Testing

```bash
flutter test
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

### Desktop
```bash
flutter build windows --release  # Windows
flutter build macos --release    # macOS
flutter build linux --release    # Linux
```

## Deployment

### Mobile
- **Android**: Upload APK to Google Play Store
- **iOS**: Submit to Apple App Store

### Desktop
- **Windows**: Distribute MSI installer
- **macOS**: Create DMG file
- **Linux**: Create AppImage or DEB package

## Troubleshooting

### Common Issues

1. **Build Runner Issues**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Dependency Issues**:
   ```bash
   flutter pub cache repair
   flutter pub get
   ```

3. **Platform-specific Issues**:
   - Check Flutter doctor: `flutter doctor`
   - Update platform tools

## Future Enhancements

- Offline mode support
- Push notifications
- Certificate generation
- Social sharing
- Multi-language support
- Accessibility improvements
- Performance optimizations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Support

For issues and questions, please contact the development team or create an issue in the repository.