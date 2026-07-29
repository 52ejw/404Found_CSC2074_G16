import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/conversation.dart';
import '../models/item_post.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../repositories/post_repository.dart';

/// Conversation-list state, including related post titles for useful rows.
class ConversationsProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final PostRepository _postRepository;

  ConversationsProvider({
    required ChatRepository chatRepository,
    required PostRepository postRepository,
  }) : _chatRepository = chatRepository,
       _postRepository = postRepository;

  StreamSubscription<List<Conversation>>? _sub;
  String? _userId;

  List<Conversation> _conversations = const [];
  List<Conversation> get conversations => _conversations;

  final Map<String, ItemPost?> _relatedPosts = {};
  ItemPost? relatedPost(String postId) => _relatedPosts[postId];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void load(String userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _sub = _chatRepository
        .watchConversations(userId)
        .listen(
          (conversations) async {
            _conversations = conversations;
            _isLoading = false;
            _error = null;
            notifyListeners();
            await _loadRelatedPosts(conversations);
          },
          onError: (Object error) {
            _error = _friendly(error);
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _loadRelatedPosts(List<Conversation> conversations) async {
    final missing = conversations
        .map((conversation) => conversation.relatedPostId)
        .where((id) => !_relatedPosts.containsKey(id))
        .toSet();
    for (final postId in missing) {
      try {
        _relatedPosts[postId] = await _postRepository.getPostById(postId);
      } catch (_) {
        _relatedPosts[postId] = null;
      }
    }
    notifyListeners();
  }

  void retry() {
    final userId = _userId;
    _userId = null;
    if (userId != null) load(userId);
  }

  String _friendly(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Route-scoped realtime message state.
class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final String conversationId;
  final String currentUserId;

  ChatProvider({
    required ChatRepository chatRepository,
    required this.conversationId,
    required this.currentUserId,
  }) : _chatRepository = chatRepository {
    _subscribe();
    _chatRepository.markMessagesRead(
      conversationId: conversationId,
      userId: currentUserId,
    );
  }

  StreamSubscription<List<Message>>? _sub;

  List<Message> _messages = const [];
  List<Message> get messages => _messages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _error;
  String? get error => _error;

  Future<bool> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return false;
    _isSending = true;
    _error = null;
    notifyListeners();
    try {
      await _chatRepository.sendMessage(
        conversationId: conversationId,
        senderId: currentUserId,
        text: trimmed,
      );
      return true;
    } catch (e) {
      _error = _friendly(e);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void retry() => _subscribe();

  void _subscribe() {
    _sub?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();
    _sub = _chatRepository
        .watchMessages(conversationId)
        .listen(
          (messages) {
            _messages = messages;
            _isLoading = false;
            _error = null;
            notifyListeners();
            _chatRepository.markMessagesRead(
              conversationId: conversationId,
              userId: currentUserId,
            );
          },
          onError: (Object error) {
            _error = _friendly(error);
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  String _friendly(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
