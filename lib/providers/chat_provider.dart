import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/conversation.dart';
import '../models/item_post.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../repositories/post_repository.dart';
import '../repositories/user_repository.dart';

/// Realtime conversation list and active chat ViewModel.
class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required ChatRepository chatRepository,
    required PostRepository postRepository,
    required UserRepository userRepository,
  }) : _chatRepository = chatRepository,
       _postRepository = postRepository,
       _userRepository = userRepository;

  final ChatRepository _chatRepository;
  final PostRepository _postRepository;
  final UserRepository _userRepository;

  StreamSubscription<List<Conversation>>? _conversationsSub;
  StreamSubscription<List<Message>>? _messagesSub;
  String? _userId;
  String? get userId => _userId;
  bool _isDisposed = false;

  List<Conversation> _conversations = const [];
  List<Conversation> get conversations => _conversations;

  List<Message> _messages = const [];
  List<Message> get messages => _messages;

  Map<String, AppUser> _usersById = const {};
  Map<String, ItemPost> _postsById = const {};

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  bool _isSending = false;
  bool get isSending => _isSending;

  String? _error;
  String? get error => _error;

  String? _messagesError;
  String? get messagesError => _messagesError;

  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscribeToConversations();
  }

  String partnerName(Conversation conversation) {
    final partnerId = conversation.participantIds.firstWhere(
      (id) => id != _userId,
      orElse: () => '',
    );
    final user = _usersById[partnerId];
    if (user != null && user.name.trim().isNotEmpty) return user.name;
    return 'Campus member';
  }

  String postTitle(Conversation conversation) {
    return _postsById[conversation.relatedPostId]?.itemName ?? 'Item post';
  }

  Future<Conversation?> startConversation(ItemPost post) async {
    final uid = _userId;
    if (uid == null) {
      _error = 'You must be signed in to start a conversation.';
      notifyListeners();
      return null;
    }
    if (uid == post.ownerId) {
      _error = 'This is your post.';
      notifyListeners();
      return null;
    }

    _error = null;
    notifyListeners();
    try {
      final conversation = await _chatRepository.getOrCreateConversation(
        relatedPostId: post.id,
        participantIds: [uid, post.ownerId],
      );
      await _loadMetadata([conversation]);
      return conversation;
    } catch (error) {
      _error = _friendly(error);
      notifyListeners();
      return null;
    }
  }

  void openConversation(Conversation conversation) {
    _messagesSub?.cancel();
    _messages = const [];
    _messagesError = null;
    _isLoadingMessages = true;
    notifyListeners();

    final uid = _userId;
    _messagesSub = _chatRepository
        .watchMessages(conversation.id)
        .listen(
          (messages) {
            _messages = messages;
            _messagesError = null;
            _isLoadingMessages = false;
            notifyListeners();
          },
          onError: (Object error) {
            _messagesError = _friendly(error);
            _isLoadingMessages = false;
            notifyListeners();
          },
        );
    if (uid != null) {
      unawaited(
        _chatRepository
            .markMessagesRead(conversationId: conversation.id, userId: uid)
            .catchError((_) {}),
      );
    }
  }

  Future<bool> sendMessage(Conversation conversation, String text) async {
    final uid = _userId;
    final trimmed = text.trim();
    if (uid == null || trimmed.isEmpty) return false;

    _isSending = true;
    _messagesError = null;
    notifyListeners();
    try {
      await _chatRepository.sendMessage(
        conversationId: conversation.id,
        senderId: uid,
        text: trimmed,
      );
      return true;
    } catch (error) {
      _messagesError = _friendly(error);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  bool isMine(Message message) => message.senderId == _userId;

  void retry() => _subscribeToConversations();

  void retryMessages(Conversation conversation) =>
      openConversation(conversation);

  void closeConversation() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _messages = const [];
    _messagesError = null;
  }

  void _subscribeToConversations() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    _conversations = const [];
    _messages = const [];
    _usersById = const {};
    _postsById = const {};
    _error = null;
    final uid = _userId;
    _isLoading = uid != null;
    notifyListeners();
    if (uid == null) return;

    _conversationsSub = _chatRepository
        .watchConversations(uid)
        .listen(
          (conversations) {
            _conversations = conversations;
            _isLoading = false;
            _error = null;
            notifyListeners();
            unawaited(_loadMetadata(conversations));
          },
          onError: (Object error) {
            _error = _friendly(error);
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _loadMetadata(List<Conversation> conversations) async {
    final userIds = conversations
        .expand((conversation) => conversation.participantIds)
        .where((id) => id != _userId)
        .toSet();
    final postIds = conversations
        .map((conversation) => conversation.relatedPostId)
        .toSet();
    final users = <String, AppUser>{..._usersById};
    final posts = <String, ItemPost>{..._postsById};

    await Future.wait([
      ...userIds.map((id) async {
        try {
          final user = await _userRepository.getUserById(id);
          if (user != null) users[id] = user;
        } catch (_) {
          // The conversation remains usable with a generic partner label.
        }
      }),
      ...postIds.map((id) async {
        try {
          final post = await _postRepository.getPostById(id);
          if (post != null) posts[id] = post;
        } catch (_) {
          // The conversation remains usable if its post was removed.
        }
      }),
    ]);
    if (_isDisposed) return;
    _usersById = users;
    _postsById = posts;
    notifyListeners();
  }

  String _friendly(Object error) {
    final value = error.toString();
    return value.startsWith('Exception: ')
        ? value.substring('Exception: '.length)
        : value;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    super.dispose();
  }
}
