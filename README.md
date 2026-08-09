# RepairLoop AI

RepairLoop is a product-lifecycle and repair-operations platform for customers, manufacturers, technicians, and administrators. It combines digital product passports, preliminary fault diagnosis, repair case tracking, and permanent service records.

## Current product flow

1. A customer creates an account with Firebase Authentication.
2. The customer registers a product and creates its digital passport.
3. A symptom assessment records a preliminary diagnosis in Firestore.
4. The customer creates a repair request.
5. An authorised technician advances the repair through the service stages.
6. The customer sees the same changes in the product lifecycle record.

When Firebase environment variables are absent, the interface opens an explicitly labelled device-local demo workspace. Demo mode is for hackathon presentation only.

## Stack

- Next.js 16 and React 19
- Firebase Authentication
- Cloud Firestore
- Firebase Storage rules for product evidence and damage images
- Lucide React icons
- ChatGPT Sites-compatible static worker adapter

## Firebase setup

1. Create a Firebase project and add a Web app.
2. Enable **Authentication -> Email/Password**.
3. Create a Cloud Firestore database.
4. Copy `.env.example` to `.env.local` and add the Firebase Web SDK values.
5. Deploy `firestore.rules`, `firestore.indexes.json`, and `storage.rules` with the Firebase CLI.
6. Create staff accounts normally, then set their `users/{uid}.role` value to `manufacturer`, `technician`, or `administrator` from a trusted admin process. New public accounts always start as `customer`.

Never add a service-account private key to this frontend repository.

## Run locally

```bash
npm install
npm run dev
```

Use **Open demo workspace** if Firebase is not configured.

## Production build

```bash
npm run build
```
