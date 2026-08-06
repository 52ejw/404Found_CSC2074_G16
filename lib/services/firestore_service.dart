import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/claim_request.dart';
import '../models/conversation.dart';
import '../models/item_post.dart';
import '../models/match_result.dart';
import '../models/message.dart';
import '../models/notification_item.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<AppUser> get users => _db
      .collection('users')
      .withConverter<AppUser>(
        fromFirestore: (doc, _) =>
            AppUser.fromMap(doc.id, doc.data() ?? const {}),
        toFirestore: (user, _) => user.toMap(),
      );

  CollectionReference<ItemPost> get posts => _db
      .collection('posts')
      .withConverter<ItemPost>(
        fromFirestore: (doc, _) =>
            ItemPost.fromMap(doc.id, doc.data() ?? const {}),
        toFirestore: (post, _) => post.toMap(),
      );

  CollectionReference<MatchResult> get matches => _db
      .collection('matches')
      .withConverter<MatchResult>(
        fromFirestore: (doc, _) =>
            MatchResult.fromMap(doc.id, doc.data() ?? const {}),
        toFirestore: (match, _) => match.toMap(),
      );

  CollectionReference<ClaimRequest> get claims => _db
      .collection('claims')
      .withConverter<ClaimRequest>(
        fromFirestore: (doc, _) =>
            ClaimRequest.fromMap(doc.id, doc.data() ?? const {}),
        toFirestore: (claim, _) => claim.toMap(),
      );

  CollectionReference<Conversation> get conversations => _db
      .collection('conversations')
      .withConverter<Conversation>(
        fromFirestore: (doc, _) =>
            Conversation.fromMap(doc.id, doc.data() ?? const {}),
        toFirestore: (conversation, _) => conversation.toMap(),
      );

  CollectionReference<Message> messagesFor(String conversationId) {
    return conversations
        .doc(conversationId)
        .collection('messages')
        .withConverter<Message>(
          fromFirestore: (doc, _) =>
              Message.fromMap(doc.id, doc.data() ?? const {}),
          toFirestore: (message, _) => message.toMap(),
        );
  }

  CollectionReference<NotificationItem> get notifications => _db
      .collection('notifications')
      .withConverter<NotificationItem>(
        fromFirestore: (doc, _) =>
            NotificationItem.fromMap(doc.id, doc.data() ?? const {}),
        toFirestore: (notification, _) => notification.toMap(),
      );
}
