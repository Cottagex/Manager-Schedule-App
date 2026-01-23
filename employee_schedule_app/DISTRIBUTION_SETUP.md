# Employee Schedule App - Firebase App Distribution Setup Guide

## Step 1: Update Firebase with New Package Name

Since we changed the package name to `com.schedulehq.employee`, you need to:

1. Go to [Firebase Console](https://console.firebase.google.com/project/schedulehq-cf87f/settings/general)
2. Click **"Add app"** → Select **Android**
3. Enter package name: `com.schedulehq.employee`
4. App nickname: `My Schedule (Employee)`
5. Click **"Register app"**
6. Download the new `google-services.json`
7. Replace `employee_schedule_app/android/app/google-services.json` with the new file

## Step 2: Enable App Distribution

1. In Firebase Console, go to **Release & Monitor** → **App Distribution**
2. Click **"Get started"**
3. Accept the terms

## Step 3: Create a Tester Group

1. In App Distribution, click **"Testers & Groups"** tab
2. Click **"Add group"**
3. Name it "Employees" (or your preference)
4. Add tester email addresses (these are the employees who will test the app)

## Step 4: Build the APK

Run this command in the employee_schedule_app directory:

```powershell
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Step 5: Upload to App Distribution

### Option A: Firebase Console (Manual)
1. Go to App Distribution in Firebase Console
2. Click **"Release"** or drag & drop the APK
3. Add release notes
4. Select your "Employees" tester group
5. Click **"Distribute"**

### Option B: Firebase CLI (Automated)
```powershell
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Upload the APK
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk `
  --app YOUR_ANDROID_APP_ID `
  --groups "Employees" `
  --release-notes "Initial release - v1.0.0"
```

Replace `YOUR_ANDROID_APP_ID` with the App ID from Firebase Console (format: `1:123456789:android:abc123`)

## Step 6: Testers Receive the App

1. Testers receive an email invitation from Firebase
2. They click the link and follow instructions to:
   - Enable "Install from unknown sources" (if needed)
   - Download the Firebase App Tester app (optional but recommended)
   - Install your app

## Updating the App

For future releases:
1. Update version in `pubspec.yaml` (e.g., `1.0.1+2`)
2. Run `flutter build apk --release`
3. Upload new APK to App Distribution
4. Testers get notified of the update

## Signing for Production (Optional)

For production releases, create a proper signing key:

```powershell
# Generate a keystore (do this once, keep the keystore safe!)
keytool -genkey -v -keystore my-schedule-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-schedule

# Then configure signing in android/app/build.gradle.kts
```

See: https://docs.flutter.dev/deployment/android#signing-the-app
