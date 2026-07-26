# Firebase setup

The codebase is already wired up to call `firebase_core`, `firebase_auth`,
`cloud_firestore` and `firebase_storage` — what's missing is a real Firebase
project to point it at. Do this once per team (not once per member).

## 1. Create the Firebase project

1. Go to the [Firebase console](https://console.firebase.google.com/) and create a new project (e.g. `404found-campusfind`).
2. Google Analytics is optional — skip it unless someone wants it for the report.

## 2. Enable the products this app uses

In the new project:

- **Authentication** → Sign-in method → enable **Email/Password**.
- **Firestore Database** → Create database → start in **production mode** (the repo's `firestore.rules` will be deployed over this — see step 5).
- **Storage** → Get started → production mode (same reasoning).

## 3. Install the FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Make sure you're also logged into the Firebase CLI (`npm install -g firebase-tools` then `firebase login`) — FlutterFire CLI uses it under the hood.

## 4. Generate `lib/firebase_options.dart`

From the repo root:

```bash
flutterfire configure --project=<your-firebase-project-id>
```

Select the platforms you need (Android and iOS were scaffolded). This
**overwrites** the placeholder `lib/firebase_options.dart` with real config —
that's expected, don't hand-edit the generated file afterward. It also drops
`google-services.json` into `android/app/` (and a Google Service Info plist
for iOS).

> `lib/firebase_options.dart`, `android/app/google-services.json` and the iOS
> equivalent contain project identifiers, not secrets that grant elevated
> access on their own — but check with the team on whether to commit them
> or add them to `.gitignore` and share them out-of-band, and follow
> whatever the group decides.

## 5. Deploy security rules and indexes

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```

This pushes `firestore.rules`, `firestore.indexes.json` and `storage.rules`
from the repo root. Re-run this any time those files change — Firestore/Storage
rules are not deployed automatically on `flutter run`.

Composite indexes can take a few minutes to build after the first deploy;
until they're ready, queries that need them (e.g. filtered + sorted feed
queries) will fail with a Firestore error containing a direct link to create
the missing index — that link is the fastest fallback if `firestore.indexes.json`
gets out of sync.

## 6. Run the app

```bash
flutter pub get
flutter run
```

## Troubleshooting

- **"Firebase has not been configured for ... yet"** — `flutterfire configure` hasn't been run, or `lib/firebase_options.dart` is still the placeholder from this scaffold.
- **Firestore permission-denied errors** — check `firestore.rules` was deployed (step 5), and that the operation matches an owner/participant check (see README > Security rules).
- **Missing index errors** — click the link in the error to create it directly in the console, then add the same field combination to `firestore.indexes.json` so the next `firebase deploy` keeps it.
