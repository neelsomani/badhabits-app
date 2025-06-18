# Bad Habits App

A SwiftUI app for tracking and analyzing bad habits using the Post Fiat network.

## Google Drive Integration Setup

This app uses **bidirectional sync** with Google Drive. Data is pulled when you open the app and saved when you close it. Conflicts are resolved by keeping whichever list has more entries.

### 1. Swift Package Manager Dependencies

Add these packages to your Xcode project:

1. **Open Xcode** → Your Project → Package Dependencies
2. **Click the + button** to add packages
3. **Add these two packages:**

#### Package 1: Google API Client
- **URL:** `https://github.com/google/google-api-objectivec-client-for-rest.git`
- **Version:** `3.0.0` or later
- **Products to add:**
  - `GoogleAPIClientForRESTCore`
  - `GoogleAPIClientForREST_Drive` (for Google Drive API)

#### Package 2: Google Sign-In
- **URL:** `https://github.com/google/GoogleSignIn-iOS.git`
- **Version:** `7.0.0` or later
- **Products to add:**
  - `GoogleSignIn` (for authentication)
  - `GoogleSignInSwift` (for SwiftUI integration)

### 2. Google Cloud Console Setup

1. **Go to [Google Cloud Console](https://console.cloud.google.com/)**
2. **Create a new project** or select an existing one
3. **Enable the Google Drive API:**
   - Go to "APIs & Services" → "Library"
   - Search for "Google Drive API"
   - Click on it and press "Enable"

### 3. Create OAuth 2.0 Credentials

1. **Go to "APIs & Services" → "Credentials"**
2. **Click "Create Credentials" → "OAuth 2.0 Client IDs"**
3. **Choose "iOS"** as the application type
4. **Enter your app's bundle identifier** (e.g., `com.yourname.Bad-Habits`)
5. **Download the `GoogleService-Info.plist` file**

### 4. Add Configuration Files

1. **Add `GoogleService-Info.plist` to your Xcode project:**
   - Drag the downloaded file into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to your main app target

2. **Update your `Info.plist`** to include URL schemes:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
       <dict>
           <key>CFBundleURLName</key>
           <string>GoogleSignIn</string>
           <key>CFBundleURLSchemes</key>
           <array>
               <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
           </array>
       </dict>
   </array>
   ```
   **Replace `YOUR_CLIENT_ID`** with the actual client ID from your `GoogleService-Info.plist`

### 5. Productionize Google Drive

You'll need to open your app to the public in the Verification Center: https://console.cloud.google.com/auth/overview

## How Sync Works

### Automatic Sync
- **App Opens:** Data is pulled from Google Drive
- **App Closes:** Data is saved to Google Drive
- **Conflicts:** Longer list automatically wins
- **Malformed Data:** User chooses to overwrite or disconnect

### Conflict Resolution
- **Automatic:** If local and remote data have different entry counts, the longer list wins
- **Manual:** If Google Drive data is corrupted, user gets options:
  - Overwrite Google Drive with local data
  - Disconnect Google Drive and keep local data

## Privacy & Security

- **Local First:** All data is stored locally on your device
- **Secure Sync:** Data is encrypted during transmission to Post Fiat
- **User Control:** You can disconnect Google Drive at any time

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Google account for sync functionality
