# Deployment Guide - MyCloudBook to Firebase

## Prerequisites

1. **Firebase CLI installed**
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase project created**
   - Go to https://console.firebase.google.com
   - Create a new project (or use existing)
   - Enable Firebase Hosting

3. **Supabase configured**
   - Supabase URL and anon key set in `lib/core/config/app_config.dart`

## Deployment Steps

### 1. Build Flutter Web App

```bash
# Ensure you're in the project root
cd C:\Users\PARDHU\Desktop\projects\MyCloudBook

# Get dependencies
flutter pub get

# Build for web
flutter build web --release
```

### 2. Initialize Firebase (First Time Only)

```bash
# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init hosting

# When prompted:
# - Select existing project or create new
# - Public directory: build/web
# - Configure as single-page app: Yes
# - Set up automatic builds: No (we'll do manual)
# - Overwrite index.html: No
```

### 3. Configure Firebase Hosting

Your `firebase.json` should look like:

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "firebase-messaging-sw.js",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "no-cache"
          }
        ]
      }
    ]
  }
}
```

### 4. Deploy to Firebase

```bash
# Deploy
firebase deploy --only hosting
```

### 5. Configure Supabase OAuth Redirects

After deployment, you'll get a URL like: `https://your-project.web.app`

1. Go to Supabase Dashboard → Authentication → URL Configuration
2. Add to **Site URL**: `https://your-project.web.app`
3. Add to **Redirect URLs**: 
   - `https://your-project.web.app/`
   - `https://your-project.firebaseapp.com/`

## Continuous Deployment (Optional)

### GitHub Actions

Create `.github/workflows/deploy_web.yml`:

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - run: flutter pub get
      - run: flutter build web --release
      
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

### Manual Deployment Script

Create `deploy.sh`:

```bash
#!/bin/bash
echo "Building Flutter web app..."
flutter build web --release

echo "Deploying to Firebase..."
firebase deploy --only hosting

echo "Deployment complete!"
```

## Environment Configuration

Before deploying, ensure:

1. **Supabase Config** (`lib/core/config/app_config.dart`):
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

2. **Firebase Config** (already in `lib/main.dart`):
   - Web Firebase config is already set
   - For mobile, add `firebase_options.dart` files

## Post-Deployment Checklist

- [ ] App loads at Firebase URL
- [ ] Authentication works (Google OAuth + Email/Password)
- [ ] Note creation works
- [ ] Image uploads work
- [ ] PDF export works
- [ ] Search works
- [ ] Offline sync works
- [ ] Notifications configured (FCM)

## Troubleshooting

### Build Errors
- Clear build: `flutter clean && flutter pub get`
- Check web support: `flutter doctor`

### Deployment Errors
- Check Firebase login: `firebase login:list`
- Verify project ID: `firebase projects:list`

### Runtime Errors
- Check browser console for errors
- Verify Supabase URL/key are correct
- Check Firebase console for hosting logs

## Production Optimizations

1. **Enable Firebase Analytics** (optional)
2. **Set up custom domain** in Firebase Hosting
3. **Configure CDN** for faster global access
4. **Enable compression** in Firebase Hosting settings
5. **Set up monitoring** with Firebase Performance

