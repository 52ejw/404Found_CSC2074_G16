import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/firestore_service.dart';
import 'chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  final FirestoreService _firestore;

  FirestoreChatRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  @override
  Future<Conversation> getOrCreateConversation({
    required String relatedPostId,
    required List<String> participantIds,
  }) async {
    try {
      final sortedParticipants = [...participantIds]..sort();

      final existing = await _firestore.conversations
          .where('relatedPostId', isEqualTo: relatedPostId)
          .where('participantIds', arrayContains: sortedParticipants.first)
          .get();

      for (final doc in existing.docs) {
        final conversation = doc.data();
        final existingSorted = [...conversation.participantIds]..sort();
        if (_sameParticipants(existingSorted, sortedParticipants)) {
          return conversation;
        }
      }

      final docRef = _firestore.conversations.doc();
      final conversation = Conversation(
        id: docRef.id,
        participantIds: sortedParticipants,
        relatedPostId: relatedPostId,
        lastMessageAt: DateTime.now(),
      );
      await docRef.set(conversation);
      return conversation;
    } on FirebaseException catch (e) {
      throw RepositoryException(
        'Failed to get or create conversation: ${e.message}',
      );
    }
  }

  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return _firestore.conversations
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _firestore
        .messagesFor(conversationId)
        .orderBy('sentAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    try {
      final conversationRef = _firestore.conversations.doc(conversationId);
      final conversation = (await conversationRef.get()).data();
      if (conversation == null) {
        throw const NotFoundException('Conversation not found.');
      }

      final messageRef = _firestore.messagesFor(conversationId).doc();
      final message = Message(
        id: messageRef.id,
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        sentAt: DateTime.now(),
      );

      final batch = FirebaseFirestore.instance.batch();
      batch.set(messageRef, message);
      batch.update(conversationRef, {
        'lastMessage': text,
        'lastMessageAt': Timestamp.fromDate(message.sentAt),
        for (final participantId in conversation.participantIds)
          if (participantId != senderId)
            'unreadCounts.$participantId': FieldValue.increment(1),
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw RepositoryException('Failed to send message: ${e.message}');
    }
  }

  @override
  Future<void> markMessagesRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final unread = await _firestore
          .messagesFor(conversationId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        if (doc.data().senderId != userId) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      batch.update(_firestore.conversations.doc(conversationId), {
        'unreadCounts.$userId': 0,
      });
      await batch.commit();
    } on FirebaseException catch (e) {
      throw RepositoryException(
        'Failed to mark messages as read: ${e.message}',
      );
    }
  }

  bool _sameParticipants(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
