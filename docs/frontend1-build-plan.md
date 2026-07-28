# Frontend 1 — Build Plan (CampusFind)

Owner: Tess (Frontend Developer 1)
Scope from blueprint §8: authentication UI, home feed, search/filter/sort, post cards, bottom navigation, plus the absorbed architecture work — routes/navigation, theme + design system, and shared reusable widgets. Supporting role: UI consistency + wireframes.

Golden rule (blueprint §8): **no Firebase calls inside screens.** Screens read `Provider` state; Providers call repositories. You build Views; Frontend 2 builds the Providers.

---

## Design tokens (lock these in `lib/app/theme.dart` first)

Everyone inherits these, so ship them before any screen.

| Token | Value | Use |
|---|---|---|
| Primary blue | `#2563EB` | Buttons, links, active nav tab, filter button, focus |
| Accent yellow | `#FACC15` | Logo tile, promo banner, highlights |
| Lost badge | bg `#FEF0C7` / text `#92680A` | Lost post type chip |
| Found badge | bg `#DBEAFE` / text `#1E4F9C` | Found post type chip |
| Card radius | `12px` | Cards, image thumbs |
| Control radius | `20–24px` | Buttons, chips, search bar |
| Placeholder gray | `#DADADA` | Image placeholders / skeletons |

Also define `AppSpacing` constants (4/8/12/16/24) and a text scale in the theme so screens never hardcode sizes.

---

## Provider contract to agree with Frontend 2 (do this before coding screens)

You code your screens against these public surfaces; FE2 implements them. Agree the names in a 15-minute sync so you can work in parallel.

`AuthProvider`: `authState` (signedIn/out/loading), `error`, `login(email, pw)`, `register(...)`, `logout()`, `sendPasswordReset(email)`.

`FeedProvider`: `posts` (List<ItemPost>), `isLoading`, `error`, `typeFilter` (all/lost/found), `category`, `query`, `setType()`, `setCategory()`, `search(text)`, `retry()`.

---

## Issues (in build order)

### FE1-1 — Design system + theme  `theme` `foundation`
Build the real `AppTheme.light`/`dark` with the tokens above: color scheme, typography, button/input/chip themes, card theme. Add `AppSpacing` constants.
- [ ] Blue/yellow color scheme applied via `ColorScheme`
- [ ] Button, input, chip, card component themes defined
- [ ] Spacing + text scale constants exist and are used
- [ ] Placeholder home still renders with new theme, no overflow

### FE1-2 — Shared reusable widgets  `widgets` `foundation`
In `lib/core/widgets/`: `PrimaryButton`, `AppTextField` (label + error + icon), `LoadingView`, `EmptyView`, `ErrorRetryView`, `PostCard(ItemPost)`, `TypeBadge(PostType)`, `FilterChipBar`.
- [ ] Each widget is stateless/config-driven and themable
- [ ] `PostCard` renders name, Lost/Found badge, category · location · time, bookmark
- [ ] Loading/empty/error views match the wireframe dashed-block style
- [ ] Widget test for `PostCard` and `TypeBadge`

### FE1-3 — App shell + bottom navigation  `navigation` `foundation`
`MainShell` `Scaffold` with 5-tab bottom nav: Feed, Post, Matches, Chats, Profile. Placeholder bodies for tabs you don't own so FE2 can slot in.
- [ ] 5 tabs with icon + label; active tab uses primary blue
- [ ] Tab state preserved on switch (IndexedStack)
- [ ] Feed tab hosts the real feed; others show a "coming soon" placeholder

### FE1-4 — Routing + auth gate  `navigation` `foundation`
Replace `_PlaceholderHome` in `app/app.dart`. Root listens to `AuthProvider.authState`: Splash → (signed out) auth flow → (signed in) `MainShell`. Add `MultiProvider` at root (coordinate with FE2 on who owns it).
- [ ] Splash routes correctly based on auth state (uses `authStateChanges`)
- [ ] Signed-out users can't reach the shell; signed-in users skip login
- [ ] Named routes / go-router set up for secondary screens

### FE1-5 — Login / Register screens (FR01)  `feature` `auth`
Forms per wireframe. Reuse `Validators` (email/password/confirm). Log in / Register toggle. Forgot-password link.
- [ ] Field validation with inline errors; submit disabled/spinner while loading
- [ ] Auth errors surfaced (wrong password, email in use) without crashing
- [ ] Register collects name/email/password; on success routes to shell
- [ ] Responsive, no overflow on small screens

### FE1-6 — Home feed (FR05)  `feature` `feed`
Greeting header + notification bell, promo banner, "Recent posts" list bound to `FeedProvider.posts`, each row a `PostCard`. Pull-to-refresh.
- [ ] Loading, empty ("No posts yet") and error+retry states wired
- [ ] Newest-first ordering; tapping a card opens Post Details (FE2 screen)
- [ ] Feed persists / reloads correctly after app restart (NFR05)

### FE1-7 — Search, filter and sort (FR06)  `feature` `feed`
Search bar (debounced) → `tokenizeQuery()`; Lost/Found/All chips; category chips; Newest sort. Results reuse `PostCard`.
- [ ] Exact, partial, mixed-case and no-result queries handled
- [ ] Type + category filters combine correctly, drive `watchFeed(...)`
- [ ] Empty/no-result state shown; clearing search restores full feed

---

## Definition of Done (blueprint §9.2) — every issue

- Works View → Provider → Repository (no Firebase in the screen)
- Validation, loading, empty and error states included
- No overflow on common Android sizes; readable labels + contrast (NFR03/NFR11)
- Formatted, no avoidable duplication
- Widget/manual test attached; PR has screenshots and one teammate review

## Suggested labels
`foundation` `feature` `theme` `widgets` `navigation` `auth` `feed`

## Milestones
M1 Foundation: FE1-1 → FE1-4 (unblocks FE2). M2 Core MVP: FE1-5 → FE1-7.
