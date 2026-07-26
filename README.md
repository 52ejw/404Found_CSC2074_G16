# 404Found (CampusFind)

A Flutter + Firebase mobile app for reporting, finding and matching lost and
found items on campus. Built for CSC2074 Mobile Application Development,
Group 16.

## Tech stack

- **Flutter / Dart** — cross-platform UI
- **Provider** — state management (ViewModel layer)
- **Firebase Authentication** — sign up / login / logout
- **Cloud Firestore** — persistent data (users, posts, matches, claims, conversations, notifications)
- **Firebase Storage** — post and profile images

Architecture is MVVM + Repository Pattern:

```
Screens/Widgets  →  Providers (ViewModel)  →  Repositories  →  Services  →  Firebase
```

## Project structure

```
lib/
├── app/            App root widget, theme, app-wide constants
├── core/           Errors, validators, search-keyword utilities, shared widgets
├── models/         Shared data models (AppUser, ItemPost, MatchResult, ClaimRequest,
│                   Conversation, Message, NotificationItem) + shared enums
├── repositories/   Repository contracts (interfaces) + Firebase-backed implementations
├── services/       Thin wrappers around Firebase SDKs (Auth, Firestore, Storage)
├── providers/      ViewModel layer (Provider/ChangeNotifier) — owned by Frontend
├── features/       Screens per feature area — owned by Frontend
firestore.rules      Firestore security rules
storage.rules         Firebase Storage security rules
firestore.indexes.json  Composite indexes required by the feed queries
```

### Repository contracts

Every collection has an abstract interface in `lib/repositories/` that the
rest of the team codes against, independent of the Firebase implementation:

| Interface | Implementation | Owner |
|---|---|---|
| `AuthRepository` | `FirebaseAuthRepository` | Backend 1 |
| `UserRepository` | `FirestoreUserRepository` | Backend 1 |
| `PostRepository` | `FirestorePostRepository` | Backend 1 |
| `MatchRepository` | _to be implemented_ | Backend 2 |
| `ClaimRepository` | _to be implemented_ | Backend 2 |
| `ChatRepository` | _to be implemented_ | Backend 2 |
| `NotificationRepository` | _to be implemented_ | Backend 2 |

Image upload is a plain service (`StorageService`), used directly by
`PostProvider` rather than through a repository, since it's a single
Firebase Storage operation rather than a data collection.

Frontend providers should depend on the **interfaces**, not the concrete
`Firestore*`/`Firebase*` classes, so screens/providers can be unit-tested
against a fake or `mocktail`-mocked repository without touching Firebase.

## Getting started

### Prerequisites

- Flutter SDK (see `environment.sdk` in `pubspec.yaml` for the minimum Dart version)
- A Firebase project for the team (see [Firebase setup](docs/firebase-setup.md) — **required before the app will run**, since `lib/firebase_options.dart` is currently a placeholder that throws until `flutterfire configure` is run)

### Run it

```bash
flutter pub get
flutter run
```

### Test it

```bash
flutter analyze
flutter test
```

## Firebase setup

No Firebase project has been created yet. See
[docs/firebase-setup.md](docs/firebase-setup.md) for the step-by-step guide
to creating the project, running `flutterfire configure`, and deploying
`firestore.rules` / `storage.rules` / `firestore.indexes.json`.

## Data model

See `lib/models/` for field definitions and blueprint section 6 for the full
Firestore schema (collections, documents, subcollections).

## Security rules

`firestore.rules` and `storage.rules` enforce (NFR06/NFR07):

- Only authenticated users may create posts, send messages or submit claims.
- Only the post owner may edit or delete their post.
- Only conversation participants may read/write that conversation's messages.
- Only the claimant or finder on a claim may read or resolve it.
- Users may read/update only their own notifications and profile document.

Deploy them with the Firebase CLI:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```
