# 404Found (CampusFind)

A Flutter + Firebase mobile app that gives Sunway University students and
staff a centralised place to report lost and found items, get rule-based
match suggestions, chat privately, and resolve claims through to a returned
item. Built for CSC2074 Mobile Application Development, Group 16.

## Features

- **Authentication** — splash screen, login, register (Firebase Auth, email/password)
- **Home feed** — All / Lost / Found tabs, search, category filters, list and grid post views
- **Create / edit post** — Lost or Found item form with image upload, category, location and contact preference
- **Post details** — full item info, owner-only edit/delete
- **Smart matching** — explainable score breakdown (category, keyword, location, date), accept/dismiss a suggestion
- **Private chat** — one conversation per post between the two interested users, unread counts
- **Claims** — submit a claim with proof, finder accepts/rejects, resolves to Returned and updates both users' recovery count
- **Profile & settings** — own posts, resolved items, edit profile, settings screen
- **First-run walkthrough** — coach-mark overlay introducing the main navigation
- **Device Preview** — dev-only phone-frame wrapper (`device_preview` package) for checking layouts on desktop/web without a physical device; disabled automatically in release builds

## Tech stack

- **Flutter / Dart** — cross-platform UI
- **Provider** — state management (ViewModel layer)
- **Firebase Authentication** — sign up / login / logout
- **Cloud Firestore** — persistent data (users, posts, matches, claims, conversations, notifications)
- **Firebase Storage** — post and profile images
- **image_picker** — selecting photos for posts/profile
- **device_preview** — dev-time responsive layout testing

Architecture is MVVM + Repository Pattern:

```
Screens/Widgets  →  Providers (ViewModel)  →  Repositories  →  Services  →  Firebase
```

## Screens

| Screen | Notes |
|---|---|
| Splash | Checks auth state |
| Login / Register | Firebase Authentication |
| Main App Shell | Top tabs (All/Lost/Found) + bottom nav: Home, Matches, Create Post (centre +), Messages, Me |
| Search | Keyword search over the feed |
| Post Details / Post Form | View, create and edit a Lost/Found post |
| Matches | Suggested matches with score breakdown |
| Conversations / Chat | Chat list and a single conversation |
| Claim form | Bottom sheet to submit/resolve a claim |
| Profile / Edit Profile | Own posts, resolved items, profile editing |
| Settings | Reached via the drawer |

The hamburger drawer also gives quick access to My posts, My matches,
Resolved items and Settings. "Saved items" and "Drafts" are present in the
drawer as placeholders (not implemented). There is no dedicated
Notifications screen yet — see **Known limitations** below.

## Project structure

```
lib/
├── app/                    App root widget (Provider wiring + auth gate), theme, constants
├── core/
│   ├── errors/             Shared exception types
│   ├── utils/              Validators, search-keyword tokenizer, Firestore converters
│   └── widgets/            Shared widgets: post cards, buttons, text fields, state views, coach marks
├── models/                 AppUser, ItemPost, MatchResult, ClaimRequest, Conversation,
│                           Message, NotificationItem + shared enums
├── repositories/           Repository contracts (interfaces) + Firebase-backed implementations
├── services/               FirebaseAuthService, FirestoreService, StorageService, MatchingService
├── providers/              AuthProvider, FeedProvider, PostProvider, MatchesProvider,
│                           ClaimsProvider, ChatProvider, ProfileProvider
└── features/
    ├── authentication/     Splash, login, register
    ├── app_shell/          Main shell, drawer, landing screen
    ├── feed/                Feed + search
    ├── posts/               Post form + details
    ├── matches/             Match suggestions
    ├── chat/                Conversations list + chat screen
    ├── claims/              Claim form
    └── profile/             Profile, edit profile, settings

firestore.rules              Firestore security rules
storage.rules                 Firebase Storage security rules
firestore.indexes.json        Composite indexes for feed/match/claim/chat/notification queries
```

### Repository contracts

Every collection has an abstract interface in `lib/repositories/`, each with
a Firebase-backed implementation:

| Interface | Implementation |
|---|---|
| `AuthRepository` | `FirebaseAuthRepository` |
| `UserRepository` | `FirestoreUserRepository` |
| `PostRepository` | `FirestorePostRepository` |
| `MatchRepository` | `FirestoreMatchRepository` |
| `ClaimRepository` | `FirestoreClaimRepository` |
| `ChatRepository` | `FirestoreChatRepository` |
| `NotificationRepository` | `FirestoreNotificationRepository` |

Providers depend on the **interfaces**, not the concrete `Firestore*`
classes, so they can be unit-tested against a fake or `mocktail`-mocked
repository without touching Firebase (see `test/`).

Image upload (`StorageService`) and matching (`MatchingService`) are plain
services rather than repositories, since one wraps a single Storage
operation and the other is a stateless scoring algorithm over posts.

## Smart matching

Rule-based weighted similarity, run by `MatchingService`:

| Factor | Weight | Scoring |
|---|---|---|
| Category | 35% | Exact match |
| Keyword | 30% | Shared tokens ÷ smaller token set size |
| Location | 20% | Exact match |
| Date proximity | 15% | ≤2 days apart = full score, ≤5 days = partial, beyond = 0 |

Suggestion threshold: **total score ≥ 60%**. Matches at or above the
threshold are saved to `matches` and both post owners are notified.

## Data model / Firestore collections

- `users/{userId}`
- `posts/{postId}`
- `matches/{matchId}`
- `claims/{claimId}`
- `conversations/{conversationId}`
  - `conversations/{conversationId}/messages/{messageId}` (subcollection)
- `notifications/{notificationId}`

See `lib/models/` for field definitions.

## Security rules

`firestore.rules` and `storage.rules` enforce:

- Only authenticated users may create posts, send messages or submit claims.
- Only the post owner may edit or delete their post.
- Only conversation participants may read/write that conversation's messages.
- Only the claimant or finder on a claim may read or resolve it.
- Users may read/update only their own notifications and profile document.

Deploy them with the Firebase CLI:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage:rules
```

## Getting started

### Prerequisites

- Flutter SDK (see `environment.sdk` in `pubspec.yaml`)
- Access to the team's Firebase project (`found-81d42`) — `lib/firebase_options.dart` is already generated via `flutterfire configure`; ask a teammate to add you as a collaborator on the Firebase console if you need to deploy rules or view data

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
