import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts a Firestore [Timestamp] (or an already-decoded [DateTime]) into a
/// [DateTime], falling back to [fallback] (defaults to now) when the field is
/// missing — e.g. for `createdAt` fields set via [FieldValue.serverTimestamp]
/// that have not yet round-tripped from the server.
DateTime dateTimeFromFirestore(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return fallback ?? DateTime.now();
}

DateTime? nullableDateTimeFromFirestore(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
