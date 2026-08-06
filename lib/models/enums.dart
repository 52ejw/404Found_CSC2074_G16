/// Shared enums used across models, repositories and providers.
library;

enum UserRole { student, staff, admin }

enum PostType { lost, found }

/// Lifecycle of an [ItemPost], per FR13 status tracking.
enum PostStatus { open, possibleMatch, claimRequested, returned, closed }

enum ContactPreference { inAppChat, email, phone }

enum ClaimStatus { pending, accepted, rejected, returned }

enum MatchStatus { suggested, accepted, dismissed }

enum NotificationType { match, message, claim }

T enumFromName<T>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final value in values) {
    if ((value as Enum).name == name) return value;
  }
  return fallback;
}
