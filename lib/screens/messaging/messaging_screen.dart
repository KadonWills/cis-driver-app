import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_icons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messaging_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/message_model.dart';
import 'package:intl/intl.dart';

class MessagingScreen extends ConsumerStatefulWidget {
  final String? otherUserId;
  
  const MessagingScreen({super.key, this.otherUserId});

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasAutoOpened = false;

  @override
  void initState() {
    super.initState();
    // Auto-open chat if otherUserId is provided
    if (widget.otherUserId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openChatForUser(widget.otherUserId!);
      });
    }
  }

  void _openChatForUser(String otherUserId) async {
    if (_hasAutoOpened) return;
    _hasAutoOpened = true;
    
    debugPrint('💬 [MESSAGING] Auto-opening chat for user: $otherUserId');
    
    final userAsync = ref.read(authStateProvider);
    await userAsync.whenData((user) async {
      if (user == null || !mounted) {
        debugPrint('💬 [MESSAGING] Cannot open chat: user is null or widget not mounted');
        return;
      }
      
      debugPrint('💬 [MESSAGING] Current user: ${user.uid}, Opening chat with: $otherUserId');
      
      // Fetch user name for the chat
      final messagingService = ref.read(messagingServiceProvider);
      final userName = await messagingService.getUserDisplayName(otherUserId);
      
      debugPrint('💬 [MESSAGING] Fetched user name: $userName');
      
      // Find or create conversation
      debugPrint('💬 [MESSAGING] Finding or creating conversation');
      final conversationId = await messagingService.findOrCreateConversation(
        userId1: user.uid,
        userId2: otherUserId,
      );
      
      debugPrint('💬 [MESSAGING] Conversation ID: $conversationId');
      
      if (!mounted) return;
      
      // Navigate to chat detail screen
      debugPrint('💬 [MESSAGING] Navigating to ChatDetailScreen');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversationId: conversationId,
            otherUserId: otherUserId,
            otherUserName: userName,
            otherUserImage: null, // Will be fetched by ChatDetailScreen
            hasConversation: true, // We just created/found the conversation
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    debugPrint('💬 [MESSAGING] Building messaging screen');

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: AppIcons.arrowLeft, color: AppTheme.textPrimary, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          debugPrint('💬 [MESSAGING] User data received: ${user != null ? "User ID: ${user.uid}" : "null"}');
          
          if (user == null) {
            debugPrint('💬 [MESSAGING] No user, showing login message');
            return const Center(child: Text('Please login'));
          }

          debugPrint('💬 [MESSAGING] Setting up conversations stream for user: ${user.uid}');
          debugPrint('💬 [MESSAGING] Query: conversations where participants arrayContains ${user.uid}, orderBy lastMessageTime desc');
          debugPrint('💬 [MESSAGING] Also querying: messages where senderId or recipientId == ${user.uid}');

          return Column(
            children: [
              // Conversations List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getCombinedConversationsStream(user.uid),
                  builder: (context, snapshot) {
                    debugPrint('💬 [MESSAGING] StreamBuilder state: ${snapshot.connectionState}');
                    debugPrint('💬 [MESSAGING] Has data: ${snapshot.hasData}');
                    debugPrint('💬 [MESSAGING] Has error: ${snapshot.hasError}');
                    
                    if (snapshot.hasError) {
                      debugPrint('💬 [MESSAGING] ❌ Error: ${snapshot.error}');
                      debugPrint('💬 [MESSAGING] Error details: ${snapshot.error.toString()}');
                      if (snapshot.error is FirebaseException) {
                        final firebaseError = snapshot.error as FirebaseException;
                        debugPrint('💬 [MESSAGING] Firebase error code: ${firebaseError.code}');
                        debugPrint('💬 [MESSAGING] Firebase error message: ${firebaseError.message}');
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            Text(
                              'Check console for details',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      debugPrint('💬 [MESSAGING] ⏳ Waiting for data...');
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData) {
                      debugPrint('💬 [MESSAGING] ⚠️ No snapshot data');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: AppIcons.chat,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No conversations yet',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final conversations = snapshot.data ?? [];
                    debugPrint('💬 [MESSAGING] ✅ Received ${conversations.length} combined conversations/messages');

                    if (conversations.isEmpty) {
                      debugPrint('💬 [MESSAGING] 📭 No conversations or messages found');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: AppIcons.chat,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No conversations yet',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    debugPrint('💬 [MESSAGING] 📋 Processing ${conversations.length} conversations...');
                    for (var i = 0; i < conversations.length; i++) {
                      final conv = conversations[i];
                      debugPrint('💬 [MESSAGING]   Conversation $i: id=${conv['id']}, otherUserId=${conv['otherUserId']}, lastMessage=${conv['lastMessage']}, lastMessageTime=${conv['lastMessageTime']}, hasConversation=${conv['hasConversation']}');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        final conversationId = conv['id'] as String;
                        final otherUserId = conv['otherUserId'] as String;
                        final lastMessage = conv['lastMessage'] as String;
                        final lastMessageTime = conv['lastMessageTime'] as Timestamp?;
                        final unreadCount = conv['unreadCount'] as int;
                        final hasConversation = conv['hasConversation'] as bool;
                        
                        debugPrint('💬 [MESSAGING] Building tile $index: conversationId=$conversationId, otherUserId=$otherUserId, hasConversation=$hasConversation');

                        return _buildConversationTile(
                          context,
                          conversationId: conversationId,
                          otherUserId: otherUserId,
                          lastMessage: lastMessage,
                          lastMessageTime: lastMessageTime,
                          unreadCount: unreadCount,
                          hasConversation: hasConversation,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () {
          debugPrint('💬 [MESSAGING] ⏳ Loading user data...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          debugPrint('💬 [MESSAGING] ❌ Error loading user: $error');
          debugPrint('💬 [MESSAGING] Stack trace: $stackTrace');
          return Center(child: Text('Error loading messages: $error'));
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedConversationsStream(String currentUserId) async* {
    debugPrint('💬 [COMBINED STREAM] Starting combined stream for user: $currentUserId');
    
    // Stream for conversations
    final conversationsStream = FirebaseFirestore.instance
        .collection(AppConstants.conversationsCollection)
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('💬 [COMBINED STREAM] Conversations snapshot: ${snapshot.docs.length} docs');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );
            return {
              'id': doc.id,
              'otherUserId': otherUserId,
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': data['lastMessageTime'] as Timestamp?,
              'unreadCount': data['unreadCount']?[currentUserId] ?? 0,
              'hasConversation': true,
              'participants': participants,
            };
          }).where((conv) => conv['otherUserId'] != '').toList();
        });

    // Stream for standalone messages (recipient)
    final receivedMessagesStream = FirebaseFirestore.instance
        .collection(AppConstants.messagesCollection)
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('💬 [COMBINED STREAM] Messages snapshot (recipient): ${snapshot.docs.length} docs');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': 'msg_${doc.id}',
              'otherUserId': data['senderId'] ?? '',
              'lastMessage': data['message'] ?? data['subject'] ?? '',
              'lastMessageTime': data['createdAt'] as Timestamp?,
              'unreadCount': (data['read'] == false) ? 1 : 0,
              'hasConversation': false,
              'messageId': doc.id,
            };
          }).toList();
        });

    // Stream for standalone messages (sender)
    final sentMessagesStream = FirebaseFirestore.instance
        .collection(AppConstants.messagesCollection)
        .where('senderId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          debugPrint('💬 [COMBINED STREAM] Messages snapshot (sender): ${snapshot.docs.length} docs');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': 'msg_${doc.id}',
              'otherUserId': data['recipientId'] ?? '',
              'lastMessage': data['message'] ?? data['subject'] ?? '',
              'lastMessageTime': data['createdAt'] as Timestamp?,
              'unreadCount': 0, // Sent messages don't count as unread
              'hasConversation': false,
              'messageId': doc.id,
            };
          }).toList();
        });

    // Combine streams using StreamZip-like approach
    StreamSubscription? conversationsSub;
    StreamSubscription? receivedSub;
    StreamSubscription? sentSub;
    
    final controller = StreamController<List<Map<String, dynamic>>>();
    final Map<String, Map<String, dynamic>> conversationMap = {};
    List<Map<String, dynamic>>? latestConversations;
    List<Map<String, dynamic>>? latestReceived;
    List<Map<String, dynamic>>? latestSent;
    
    void emitCombined() {
      if (latestConversations == null || latestReceived == null || latestSent == null) {
        return; // Wait for all streams to emit at least once
      }
      
      conversationMap.clear();
      
      // Add conversations first (they take priority)
      for (final conv in latestConversations!) {
        final key = conv['otherUserId'] as String;
        if (key.isNotEmpty) {
          conversationMap[key] = Map<String, dynamic>.from(conv);
        }
      }
      
      // Add standalone messages (only if no conversation exists)
      final allMessages = [...latestReceived!, ...latestSent!];
      for (final msg in allMessages) {
        final key = msg['otherUserId'] as String;
        if (key.isEmpty) continue;
        
        if (!conversationMap.containsKey(key)) {
          conversationMap[key] = Map<String, dynamic>.from(msg);
        } else {
          // Update if message is newer
          final existing = conversationMap[key]!;
          final existingTime = existing['lastMessageTime'] as Timestamp?;
          final msgTime = msg['lastMessageTime'] as Timestamp?;
          if (msgTime != null && (existingTime == null || msgTime.compareTo(existingTime) > 0)) {
            existing['lastMessage'] = msg['lastMessage'];
            existing['lastMessageTime'] = msgTime;
            existing['unreadCount'] = (existing['unreadCount'] as int) + (msg['unreadCount'] as int);
          }
        }
      }
      
      final combined = conversationMap.values.toList();
      // Sort by lastMessageTime descending
      combined.sort((a, b) {
        final aTime = a['lastMessageTime'] as Timestamp?;
        final bTime = b['lastMessageTime'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      debugPrint('💬 [COMBINED STREAM] Combined result: ${combined.length} unique conversations');
      controller.add(combined);
    }
    
    conversationsSub = conversationsStream.listen(
      (conversations) {
        latestConversations = conversations;
        emitCombined();
      },
      onError: (error) {
        debugPrint('💬 [COMBINED STREAM] ❌ Error in conversations stream: $error');
        controller.addError(error);
      },
    );
    
    receivedSub = receivedMessagesStream.listen(
      (messages) {
        latestReceived = messages;
        emitCombined();
      },
      onError: (error) {
        debugPrint('💬 [COMBINED STREAM] ❌ Error in received messages stream: $error');
        controller.addError(error);
      },
    );
    
    sentSub = sentMessagesStream.listen(
      (messages) {
        latestSent = messages;
        emitCombined();
      },
      onError: (error) {
        debugPrint('💬 [COMBINED STREAM] ❌ Error in sent messages stream: $error');
        controller.addError(error);
      },
    );
    
    controller.onCancel = () {
      conversationsSub?.cancel();
      receivedSub?.cancel();
      sentSub?.cancel();
    };
    
    yield* controller.stream;
  }

  Widget _buildConversationTile(
    BuildContext context, {
    required String conversationId,
    required String otherUserId,
    required String lastMessage,
    required Timestamp? lastMessageTime,
    required int unreadCount,
    bool hasConversation = true,
  }) {
    debugPrint('💬 [CONVERSATION TILE] Building tile for conversationId=$conversationId, otherUserId=$otherUserId');
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(otherUserId)
          .get(),
      builder: (context, snapshot) {
        debugPrint('💬 [CONVERSATION TILE] FutureBuilder state for $otherUserId: ${snapshot.connectionState}');
        debugPrint('💬 [CONVERSATION TILE] Has data: ${snapshot.hasData}, Has error: ${snapshot.hasError}');
        
        if (snapshot.hasError) {
          debugPrint('💬 [CONVERSATION TILE] ❌ Error fetching user $otherUserId: ${snapshot.error}');
          // Show conversation tile with fallback data instead of hiding it
          return _buildConversationTileContent(
            context,
            conversationId: conversationId,
            otherUserId: otherUserId,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            unreadCount: unreadCount,
            userName: 'Unknown User',
            userImage: null,
            hasConversation: hasConversation,
          );
        }
        
        if (!snapshot.hasData) {
          debugPrint('💬 [CONVERSATION TILE] ⏳ Waiting for user data: $otherUserId');
          return const SizedBox.shrink();
        }

        final doc = snapshot.data!;
        debugPrint('💬 [CONVERSATION TILE] ✅ User document exists: ${doc.exists}');
        
        if (!doc.exists) {
          debugPrint('💬 [CONVERSATION TILE] ⚠️ User document does not exist: $otherUserId');
          // Show conversation tile with fallback data
          return _buildConversationTileContent(
            context,
            conversationId: conversationId,
            otherUserId: otherUserId,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            unreadCount: unreadCount,
            userName: 'Unknown User',
            userImage: null,
            hasConversation: hasConversation,
          );
        }

        final userData = doc.data() as Map<String, dynamic>?;
        debugPrint('💬 [CONVERSATION TILE] User data: $userData');
        
        // Use displayName if available, otherwise fall back to firstName
        final displayName = userData?['displayName'];
        final firstName = userData?['firstName'] ?? '';
        final userName = (displayName != null && displayName.toString().trim().isNotEmpty) 
            ? displayName.toString() 
            : (firstName.isNotEmpty ? firstName : 'Unknown User');
        final userImage = userData?['profileImage'];
        
        debugPrint('💬 [CONVERSATION TILE] Resolved: userName=$userName, userImage=${userImage != null ? "has image" : "no image"}');
        
        return _buildConversationTileContent(
          context,
          conversationId: conversationId,
          otherUserId: otherUserId,
          lastMessage: lastMessage,
          lastMessageTime: lastMessageTime,
          unreadCount: unreadCount,
          userName: userName,
          userImage: userImage,
          hasConversation: hasConversation,
        );
      },
    );
  }

  Widget _buildConversationTileContent(
    BuildContext context, {
    required String conversationId,
    required String otherUserId,
    required String lastMessage,
    required Timestamp? lastMessageTime,
    required int unreadCount,
    required String userName,
    String? userImage,
    required bool hasConversation,
  }) {

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              conversationId: conversationId,
              otherUserId: otherUserId,
              otherUserName: userName,
              otherUserImage: userImage,
              hasConversation: hasConversation,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: userImage != null ? NetworkImage(userImage) : null,
              backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
              child: userImage == null
                  ? HugeIcon(
                      icon: AppIcons.user,
                      size: 28,
                      color: AppTheme.accentColor,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMessageTime != null)
                        Text(
                          DateFormat('h:mm a').format(lastMessageTime.toDate()),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final bool hasConversation;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
    this.hasConversation = true,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _replyingToMessageId;
  MessageModel? _replyingToMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setReplyingTo(MessageModel? message) {
    setState(() {
      _replyingToMessage = message;
      _replyingToMessageId = message?.id;
    });
  }

  void _clearReply() {
    setState(() {
      _replyingToMessage = null;
      _replyingToMessageId = null;
    });
  }


  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userAsync = ref.read(authStateProvider);
    final messagingService = ref.read(messagingServiceProvider);
    
    userAsync.whenData((user) async {
      if (user == null) return;

      final messageText = _messageController.text.trim();
      _messageController.clear();
      
      final parentMessageId = _replyingToMessageId;
      _clearReply();

      debugPrint('💬 [CHAT DETAIL] Sending message: hasConversation=${widget.hasConversation}, conversationId=${widget.conversationId}, parentMessageId=$parentMessageId');

      try {
        String conversationId = widget.conversationId;
        bool hasConversation = widget.hasConversation;
        
        // If no conversation exists, create one before sending
        if (!hasConversation || conversationId.isEmpty) {
          debugPrint('💬 [CHAT DETAIL] No conversation exists, creating one...');
          conversationId = await messagingService.findOrCreateConversation(
            userId1: user.uid,
            userId2: widget.otherUserId,
          );
          hasConversation = true;
          debugPrint('💬 [CHAT DETAIL] Created conversation: $conversationId');
        }
        
        // Always send to conversation subcollection to group messages
        await messagingService.sendConversationMessage(
          conversationId: conversationId,
          senderId: user.uid,
          text: messageText,
          parentMessageId: parentMessageId,
        );

        // Scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } catch (e) {
        debugPrint('💬 [CHAT DETAIL] Error sending message: $e');
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message: $e')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: HugeIcon(icon: AppIcons.arrowLeft, color: AppTheme.textPrimary, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.otherUserImage != null
                  ? NetworkImage(widget.otherUserImage!)
                  : null,
              backgroundColor: AppTheme.accentColor.withOpacity(0.1),
              child: widget.otherUserImage == null
                  ? HugeIcon(
                      icon: AppIcons.user,
                      size: 18,
                      color: AppTheme.accentColor,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please login'));
          }
          final messagingService = ref.watch(messagingServiceProvider);
          
          return Column(
            children: [
              // Reply preview
              if (_replyingToMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBackground,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.borderColor.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Replying to ${_replyingToMessage!.senderId == user.uid ? 'yourself' : _replyingToMessage!.senderName}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _replyingToMessage!.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: _clearReply,
                      ),
                    ],
                  ),
                ),
              // Messages List
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: messagingService.getMessagesStream(
                    currentUserId: user.uid,
                    otherUserId: widget.otherUserId,
                    conversationId: (widget.hasConversation && widget.conversationId.isNotEmpty) 
                        ? widget.conversationId 
                        : null,
                  ),
                  builder: (context, snapshot) {
                    debugPrint('💬 [CHAT DETAIL] Messages stream state: ${snapshot.connectionState}');
                    debugPrint('💬 [CHAT DETAIL] Has data: ${snapshot.hasData}, Has error: ${snapshot.hasError}');
                    
                    if (snapshot.hasError) {
                      debugPrint('💬 [CHAT DETAIL] ❌ Error: ${snapshot.error}');
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      debugPrint('💬 [CHAT DETAIL] ⏳ Waiting for messages...');
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];
                    debugPrint('💬 [CHAT DETAIL] ✅ Received ${messages.length} messages');

                    if (messages.isEmpty) {
                      debugPrint('💬 [CHAT DETAIL] 📭 No messages found');
                      return Center(
                        child: Text(
                          'No messages yet',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }

                    // Create a map of parent messages for quick lookup
                    final parentMessages = <String, MessageModel>{};
                    for (final msg in messages) {
                      if (msg.parentMessageId != null) {
                        final parent = messages.firstWhere(
                          (m) => m.id == msg.parentMessageId,
                          orElse: () => MessageModel(
                            id: '',
                            senderId: '',
                            senderName: 'Unknown',
                            recipientId: '',
                            text: 'Message not found',
                            isRead: false,
                            createdAt: DateTime.now(),
                          ),
                        );
                        parentMessages[msg.id] = parent;
                      }
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(
                          _scrollController.position.maxScrollExtent,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == user.uid;
                        final parentMessage = parentMessages[message.id];

                        return _buildMessageBubble(
                          message: message,
                          isMe: isMe,
                          parentMessage: parentMessage,
                          onReply: () => _setReplyingTo(message),
                        );
                      },
                    );
                  },
                ),
              ),
              // Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBackground,
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.borderColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBackground,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.borderColor.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: HugeIcon(
                            icon: AppIcons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading chat')),
      ),
    );
  }

  Widget _buildMessageBubble({
    required MessageModel message,
    required bool isMe,
    MessageModel? parentMessage,
    required VoidCallback onReply,
  }) {
    return _DraggableMessageBubble(
      message: message,
      isMe: isMe,
      parentMessage: parentMessage,
      onReply: onReply,
    );
  }
}

class _DraggableMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final MessageModel? parentMessage;
  final VoidCallback onReply;

  const _DraggableMessageBubble({
    required this.message,
    required this.isMe,
    this.parentMessage,
    required this.onReply,
  });

  @override
  State<_DraggableMessageBubble> createState() => _DraggableMessageBubbleState();
}

class _DraggableMessageBubbleState extends State<_DraggableMessageBubble> {
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxDrag = screenWidth * 0.5; // Halfway across screen
    final dragProgress = (_dragOffset / maxDrag).clamp(0.0, 1.0);

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: widget.onReply,
        onHorizontalDragStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onHorizontalDragUpdate: (details) {
          if (widget.isMe) {
            // For sent messages, drag left to reply
            setState(() {
              _dragOffset = (_dragOffset - details.delta.dx).clamp(0.0, maxDrag);
            });
          } else {
            // For received messages, drag right to reply
            setState(() {
              _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxDrag);
            });
          }
        },
        onHorizontalDragEnd: (_) {
          if (_dragOffset >= maxDrag * 0.5) {
            // Dragged at least halfway - trigger reply
            widget.onReply();
          }
          // Reset drag
          setState(() {
            _dragOffset = 0.0;
            _isDragging = false;
          });
        },
        onHorizontalDragCancel: () {
          setState(() {
            _dragOffset = 0.0;
            _isDragging = false;
          });
        },
        child: Stack(
          children: [
            // Reply indicator (shows when dragging)
            if (_isDragging && _dragOffset > 0)
              Positioned(
                left: widget.isMe ? null : -40,
                right: widget.isMe ? -40 : null,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: dragProgress,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.reply,
                      color: AppTheme.accentColor,
                      size: 24 * dragProgress,
                    ),
                  ),
                ),
              ),
            // Message bubble
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                widget.isMe ? -_dragOffset : _dragOffset,
                0,
                0,
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: Column(
                  crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Parent message preview (if this is a reply)
                    if (widget.parentMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.isMe 
                              ? Colors.white.withValues(alpha: 0.2)
                              : AppTheme.primaryBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isMe 
                                ? Colors.white.withValues(alpha: 0.3)
                                : AppTheme.borderColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: widget.isMe ? Colors.white : AppTheme.accentColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.parentMessage!.senderName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isMe 
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : AppTheme.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.parentMessage!.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: widget.isMe 
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : AppTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    // Main message bubble
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: widget.isMe ? AppTheme.accentColor : AppTheme.secondaryBackground,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(widget.isMe ? 20 : 4),
                          bottomRight: Radius.circular(widget.isMe ? 4 : 20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.message.text,
                            style: TextStyle(
                              color: widget.isMe ? Colors.white : AppTheme.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('h:mm a').format(widget.message.createdAt),
                            style: TextStyle(
                              color: widget.isMe
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

