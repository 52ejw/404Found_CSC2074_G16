import 'package:cloud_firestore/cloud_firestore.dart';

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
