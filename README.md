# RepairLoop AI

RepairLoop AI is a Flutter mobile application for persistent electronic-product passports, preliminary multimodal fault assessment, and traceable repair history.

The project deliberately uses Flutter and Firebase end to end. The AI provider is called only from Firebase Cloud Functions; no private AI credential is stored in Dart, app assets, or source control.

## Technology stack

- Flutter, Dart and Material 3
- Riverpod for application state and dependency injection
- GoRouter for mobile and tablet navigation
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions (TypeScript, Node.js 22)
- Firebase App Check
- Replaceable multimodal AI provider adapter

## Implemented workflows

- Customer/manufacturer email and password registration
- Protected technician and administrator roles
- Manufacturer product registration
- Secure sequential passport generation
- Original component registration
- QR passport generation and camera scanning
- Product, warranty, component and lifecycle views
- Symptom text and camera/gallery image submission
- Multimodal preliminary diagnosis
- Hazard escalation for electrical and battery risks
- Customer repair requests
- Technician assignment and controlled repair states
- Technician notes and component replacement
- Administrator user-role management

## Architecture

```text
Flutter application
  ├── Firebase Authentication
  ├── Cloud Firestore repositories
  ├── Firebase Storage image uploads
  └── Callable Cloud Functions
        ├── authorization and validation
        ├── product/passport transactions
        ├── repair workflow transactions
        └── multimodal AI provider interface
              └── OpenAI adapter (replaceable)
```

The AI contract is defined in `functions/src/ai/types.ts`. To add another provider, implement `MultimodalDiagnosisProvider` and register it in `provider-factory.ts`. Flutter does not change.

## Firebase collections

| Collection | Purpose |
| --- | --- |
| `users` | Auth-linked profile and role |
| `products` | Product identity, ownership, status and passport ID |
| `products/{id}/components` | Original and replacement component history |
| `diagnoses` | Structured preliminary AI assessments |
| `repairs` | Customer-to-technician repair cases |
| `lifecycleEvents` | Append-only product activity |
| `counters` | Server-only passport sequence |

## Local prerequisites

- Flutter stable with Dart 3.6 or newer
- Node.js 22
- Firebase CLI
- FlutterFire CLI
- Firebase project `repairloop-ai` on the no-cost Spark plan

## Current Firebase plan

RepairLoop AI currently stays on Firebase's no-cost Spark plan. Email/Password
Authentication and Cloud Firestore are enabled in the real project. No billing
account is attached.

The repository keeps the Firebase Storage rules and Cloud Functions source so
the complete architecture can be developed and tested with the Firebase
emulators. Storage uploads, deployed Cloud Functions and live multimodal AI are
not enabled in the hosted backend because those features require a billing-enabled
Firebase project. The Flutter app must not call an AI provider directly or
contain a private AI key as a workaround.

## 1. Generate platform projects

This repository contains the application source. If Android/iOS platform folders are not present, run:

```bash
flutter create . --org com.nithishsarwin --platforms=android,ios,web
```

After generation, make sure both the Android application ID and Apple bundle ID
are exactly `com.nithishsarwin.repairloopai`. The Firebase Console already has
Android, Apple and Web apps registered under those identifiers.

## 2. Firebase connection

```bash
dart pub global activate flutterfire_cli
firebase login
cp .firebaserc.example .firebaserc
```

The application is already bound to Firebase project `repairloop-ai` through
its public client options in
`lib/core/config/runtime_firebase_options.dart`. Run FlutterFire configuration
after creating native platform folders if you also want the conventional native
configuration files:

```bash
flutterfire configure --project=repairloop-ai
```

The following Firebase services are enabled on Spark:

1. Authentication → Email/Password
2. Firestore Database

Storage and Cloud Functions are intentionally not deployed on the current free
plan. App Check configuration can remain in the app for later activation.

For App Check, register Play Integrity for Android and App Attest/DeviceCheck for Apple. Register reCAPTCHA v3 if Flutter web is used.

## 3. Install dependencies and verify Flutter

```bash
flutter pub get
flutter analyze
flutter test
```

Android and iOS can use the native files created by `flutterfire configure`.
The app also supports Firebase identifiers supplied with `--dart-define` for
automated builds or a separate Firebase environment; these override the checked
in public client defaults.

For web, supply the Firebase values and reCAPTCHA site key:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=... \
  --dart-define=FIREBASE_AUTH_DOMAIN=... \
  --dart-define=FIREBASE_WEB_APP_ID=... \
  --dart-define=RECAPTCHA_V3_SITE_KEY=...
```

Firebase client configuration identifies a Firebase project; it is not the private multimodal AI credential. The AI key must remain in Secret Manager.

## 4. Develop the secure AI backend locally

Install and compile Cloud Functions:

```bash
cd functions
npm install
npm run build
cd ..
```

For a future billing-enabled deployment, store the private AI key in Firebase
Secret Manager:

```bash
firebase functions:secrets:set AI_API_KEY
```

The default provider settings are:

```text
AI_PROVIDER=openai
AI_MODEL=gpt-4.1-mini
AI_BASE_URL=https://api.openai.com/v1
```

These are non-secret parameters. Change the provider adapter or configured model without placing credentials in Flutter.

## 5. Deploy the Spark-compatible Firebase resources

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Do not deploy Storage or Cloud Functions while the project remains on Spark.
App Check enforcement is already implemented in the callable-function source
for a future deployment. Register development debug tokens before emulator
testing.

## 6. Use Firebase emulators

```bash
firebase emulators:start --only auth,firestore,storage,functions
```

The Flutter repository providers are kept behind interfaces so emulator wiring
and fake repositories can be added without changing feature screens. Use the
emulators for Storage, Cloud Functions and multimodal-AI workflow development
while keeping the real Firebase project on Spark.

## Security decisions

- Users cannot self-register as technician or administrator.
- Client code cannot write products, diagnoses, repairs, lifecycle events or counters directly.
- Cloud Functions validate authentication, roles, ownership and state transitions.
- Diagnosis images are restricted by owner path, MIME type and size.
- The Cloud Function fetches product context and repair history server-side.
- Only concise user-facing reasoning is stored; private chain-of-thought is neither requested nor returned.
- Hazard keywords trigger a deterministic safety override in addition to the AI model prompt.
- `AI_API_KEY` is a bound Firebase Secret and never sent to Flutter.

## Current validation

GitHub Actions runs Flutter analysis, widget tests, the strict TypeScript Cloud
Functions build and the backend dependency audit for pull requests.
