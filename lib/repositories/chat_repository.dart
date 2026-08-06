import '../models/conversation.dart';
import '../models/message.dart';

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

  Future<void> markMessagesRead({
    required String conversationId,
    required String userId,
  });
}
