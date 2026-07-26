import '../models/conversation.dart';
import '../models/message.dart';

/// Contract for the `conversations` collection and its `messages`
/// subcollection (FR10 private chat).
///
/// Interface owned by Backend Developer 1 as part of the shared repository
/// contracts; the concrete implementation is owned by Backend Developer 2.
abstract class ChatRepository {
  Future<Conversation> getOrCreateConversation({
    required String relatedPostId,
    required List<String> participantIds,
  });

  Stream<List<Conversation>> watchConversations(String userId);

  Stream<List<Message>> watchMessages(String conversationId);

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });

  Future<void> markMessagesRead({required String conversationId, required String userId});
}
