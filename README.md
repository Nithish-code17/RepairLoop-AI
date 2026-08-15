# RepairLoop AI

RepairLoop AI is a Flutter mobile application for persistent electronic-product passports, preliminary multimodal fault assessment, and traceable repair history.

The project deliberately uses Flutter and Firebase end to end. On the Spark
plan, preliminary diagnosis uses Firebase AI Logic's protected proxy with the
Gemini Developer API. No private Gemini credential is stored in Dart, app
assets, or source control, and the provider stays replaceable behind a Dart
interface.

## Technology stack

- Flutter, Dart and Material 3
- Riverpod for application state and dependency injection
- GoRouter for mobile and tablet navigation
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Functions (TypeScript, Node.js 22)
- Firebase AI Logic with Gemini Developer API
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
  ├── Firebase AI Logic provider interface
  │     └── Gemini Developer API adapter (replaceable)
  ├── Firebase Storage image uploads (future Blaze path)
  └── Callable Cloud Functions (future Blaze path)
        ├── authorization and validation
        ├── product/passport transactions
        ├── repair workflow transactions
        └── optional server-side multimodal AI provider
```

The live Spark AI contract is
`lib/features/diagnosis/data/multimodal_diagnosis_provider.dart`. To change the
provider, implement `MultimodalDiagnosisProvider` and update its Riverpod
binding. The Cloud Functions source retains a separate server adapter for a
future billing-enabled deployment.

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

The repository keeps Firebase Storage rules and Cloud Functions source so the
complete transactional architecture can be developed with the Firebase
emulators. Storage uploads and deployed Cloud Functions are not enabled because
they require a billing-enabled Firebase project.

Live preliminary diagnosis instead uses Firebase AI Logic with the Gemini
Developer API. The selected image is sent inline through Firebase's protected
proxy and is not uploaded to Storage. The result stays advisory and is not
written to lifecycle history until the server workflow is deployed.

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

The following Firebase services are used on Spark:

1. Authentication → Email/Password
2. Firestore Database
3. Firebase AI Logic → Gemini Developer API

Storage and Cloud Functions are intentionally not deployed on the current free
plan. App Check protects Firebase AI Logic in production and uses registered
debug tokens during local development.

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

The AI model defaults to the stable Spark-compatible `gemini-3.6-flash`. It can
be changed without modifying the provider implementation:

```bash
flutter run --dart-define=FIREBASE_AI_MODEL=gemini-3.6-flash
```

Firebase client configuration identifies a Firebase project; it is not a
private Gemini credential. Firebase AI Logic authorizes model requests through
its managed proxy and App Check.

## 4. Enable the Spark AI service

In Firebase Console, open **AI Services → AI Logic**, select **Gemini Developer
API**, enable the required APIs, and enforce App Check. Do not select the Agent
Platform Gemini API because it requires billing.

For local Android/iOS development, run a debug build and register the App Check
debug token shown in the device logs. Never commit a debug token.

## 5. Develop the optional server backend locally

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

## 6. Deploy the Spark-compatible Firebase resources

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

Do not deploy Storage or Cloud Functions while the project remains on Spark.
App Check enforcement is already implemented in the callable-function source
for a future deployment. Register development debug tokens before emulator
testing.

## 7. Build and deploy Flutter Web on Firebase Hosting

Register the Firebase Web app with reCAPTCHA v3 in App Check before making the
site public. Build with the public reCAPTCHA site key; keep its secret key only
in Firebase App Check and never commit it.

```bash
flutter build web --release \
  --dart-define=RECAPTCHA_V3_SITE_KEY=YOUR_PUBLIC_SITE_KEY

firebase deploy --only hosting --project repairloop-ai
```

The Hosting configuration serves `build/web`, routes Flutter paths back to
`index.html`, prevents the application shell from being cached, and applies
long-lived caching only to hashed static assets. The default deployment URLs
are `https://repairloop-ai.web.app` and
`https://repairloop-ai.firebaseapp.com`.

## 8. Use Firebase emulators

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
- Future Storage-backed diagnosis images are restricted by owner path, MIME
  type and size.
- The Cloud Function fetches product context and repair history server-side.
- Spark diagnosis sends only the selected image, written symptoms and limited
  product context through Firebase AI Logic.
- A deterministic client safety policy escalates reports of smoke, sparks,
  swelling, severe heat, high voltage and related hazards.
- Only concise user-facing reasoning is requested or returned; private
  chain-of-thought is never requested.
- Hazard keywords trigger a deterministic safety override in addition to the AI model prompt.
- `AI_API_KEY` is a bound Firebase Secret and never sent to Flutter.
