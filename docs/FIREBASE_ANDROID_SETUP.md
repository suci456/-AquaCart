# 🔥 Firebase Android Setup & Role Authorization Guide
**Application**: AquaCart (Califnco Technical Assignment)  
**Package Name**: `com.califnco.aquacart`  
**Minimum Android SDK**: `21` (Android 5.0 Lollipop)  
**Target Android SDK**: `34` (Android 14)

---

## 1. Firebase Project Setup

1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project**, name it (e.g. `aquacart-califnco`), and click **Continue**.
3. (Optional) Enable Google Analytics and click **Create project**.

---

## 2. Register Android Application

1. In the Project Overview page, click the **Android** icon to add an Android app.
2. Enter the exact Android package name:
   ```
   com.califnco.aquacart
   ```
3. Enter App nickname: `AquaCart Android`.
4. (Recommended) Generate and add your debug SHA-1 signing certificate fingerprint:
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
5. Click **Register app**.

---

## 3. Place `google-services.json`

1. Download `google-services.json` from the Firebase Console.
2. Move/copy the downloaded file to:
   ```
   d:/AquaCart/android/app/google-services.json
   ```
   *(A valid template already exists at this path)*.

---

## 4. Gradle Configuration Verification

The project is already pre-configured with Google Services plugins:

### Project-level Gradle (`android/build.gradle`):
```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

### App-level Gradle (`android/app/build.gradle`):
```groovy
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

android {
    namespace "com.califnco.aquacart"
    defaultConfig {
        applicationId "com.califnco.aquacart"
        minSdkVersion 21
        targetSdkVersion 34
        multiDexEnabled true
    }
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.1.2')
    implementation 'com.google.firebase:firebase-analytics'
}
```

---

## 5. Enable Firebase Authentication (Email/Password)

1. In Firebase Console left sidebar, navigate to **Build** -> **Authentication**.
2. Click **Get started**.
3. Under the **Sign-in method** tab, click **Email/Password**.
4. Enable **Email/Password** toggle and click **Save**.

---

## 6. Enable Cloud Firestore & Deploy Rules

1. In Firebase Console, go to **Build** -> **Firestore Database**.
2. Click **Create database**, select a regional location (e.g. `asia-south1` for India), and select **Production mode**.
3. In the Firestore **Rules** tab, paste the contents of [`firebase/firestore.rules`](file:///d:/AquaCart/firebase/firestore.rules) and click **Publish**.

---

## 7. 🛡️ Critical Security: Admin Role Authorization

> [!CAUTION]
> **Strict Security Invariant**: Self-assigned Admin registration is strictly blocked by both the client code and Cloud Firestore rules:
> ```javascript
> // firestore.rules
> match /users/{userId} {
>   allow create: if isAuthenticated() && request.auth.uid == userId &&
>                 request.resource.data.role in ['customer', 'dealer'] &&
>                 request.resource.data.role != 'admin';
> }
> ```

### How to Authorize an Admin:
Because users cannot register as Admin, the first Admin account must be explicitly provisioned:
1. Register a standard user account in the app or Firebase Authentication console (e.g., `admin@aquacart.in`).
2. Copy the user's `UID` from the Authentication tab.
3. In **Firestore Database**, find the document at `/users/{UID}`.
4. Update the `role` field value from `customer` to `admin`.
5. Once set to `admin`, the user will automatically be routed to the **Admin Dashboard Console** upon login.

---

## 8. Running and Testing Authentication

```bash
# Get Flutter dependencies
flutter pub get

# Run on connected Android device or emulator
flutter run
```

When Firebase credentials are not yet configured or running in offline mode, `AquaCart` automatically utilizes its built-in `MockDataService` with pre-authenticated personas:
- **Customer**: `customer@aquacart.in` / `password123`
- **Dealer (B2B)**: `dealer@aquatechsolutions.com` / `dealerPass123`
- **Admin**: `admin@aquacart.in` / `adminPass123`
