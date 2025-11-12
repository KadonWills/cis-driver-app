import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../core/constants/app_constants.dart';
import 'audit_log_service.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLog = AuditLogService();

  /// Get messages stream for a conversation (both sent and received)
  /// Combines messages from conversation subcollection and standalone messages collection
  Stream<List<MessageModel>> getMessagesStream({
    required String currentUserId,
    required String otherUserId,
    String? conversationId,
  }) {
    debugPrint('💬 [MESSAGING SERVICE] Getting messages stream');
    debugPrint('   currentUserId: $currentUserId');
    debugPrint('   otherUserId: $otherUserId');
    debugPrint('   conversationId: $conversationId');

    if (conversationId != null && !conversationId.startsWith('msg_')) {
      // Has a conversation - get messages from conversation subcollection
      return _getConversationMessagesStream(conversationId, currentUserId);
    } else {
      // No conversation - get messages from messages collection
      return _getStandaloneMessagesStream(currentUserId, otherUserId);
    }
  }

  /// Get messages from conversation subcollection
  Stream<List<MessageModel>> _getConversationMessagesStream(
    String conversationId,
    String currentUserId,
  ) {
    return _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          debugPrint(
            '💬 [MESSAGING SERVICE] Conversation messages: ${snapshot.docs.length}',
          );

          return snapshot.docs
              .map((doc) {
                try {
                  return MessageModel.fromConversationMessage(
                    doc,
                    conversationId,
                  );
                } catch (e) {
                  debugPrint(
                    '💬 [MESSAGING SERVICE] Error parsing message ${doc.id}: $e',
                  );
                  return null;
                }
              })
              .whereType<MessageModel>()
              .toList();
        });
  }

  /// Get messages from standalone messages collection (both sent and received)
  Stream<List<MessageModel>> _getStandaloneMessagesStream(
    String currentUserId,
    String otherUserId,
  ) {
    // Combine two queries: messages where current user is sender, and where current user is recipient
    final sentStream = _firestore
        .collection(AppConstants.messagesCollection)
        .where('senderId', isEqualTo: currentUserId)
        .where('recipientId', isEqualTo: otherUserId)
        .orderBy('createdAt', descending: false)
        .snapshots();

    final receivedStream = _firestore
        .collection(AppConstants.messagesCollection)
        .where('senderId', isEqualTo: otherUserId)
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: false)
        .snapshots();

    // Combine both streams using StreamController
    final controller = StreamController<List<MessageModel>>.broadcast();
    StreamSubscription? sentSub;
    StreamSubscription? receivedSub;

    final sentMessages = <String, MessageModel>{};
    final receivedMessages = <String, MessageModel>{};

    void emitCombined() {
      final allMessages = <MessageModel>[
        ...sentMessages.values,
        ...receivedMessages.values,
      ];

      // Sort by createdAt
      allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      debugPrint(
        '💬 [MESSAGING SERVICE] Combined messages: ${allMessages.length}',
      );
      if (!controller.isClosed) {
        controller.add(allMessages);
      }
    }

    sentSub = sentStream.listen(
      (snapshot) {
        debugPrint(
          '💬 [MESSAGING SERVICE] Sent messages: ${snapshot.docs.length}',
        );
        sentMessages.clear();
        for (final doc in snapshot.docs) {
          try {
            final message = MessageModel.fromFirestore(doc);
            sentMessages[message.id] = message;
          } catch (e) {
            debugPrint(
              '💬 [MESSAGING SERVICE] Error parsing sent message ${doc.id}: $e',
            );
          }
        }
        emitCombined();
      },
      onError: (error) {
        debugPrint(
          '💬 [MESSAGING SERVICE] Error in sent messages stream: $error',
        );
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    receivedSub = receivedStream.listen(
      (snapshot) {
        debugPrint(
          '💬 [MESSAGING SERVICE] Received messages: ${snapshot.docs.length}',
        );
        receivedMessages.clear();
        for (final doc in snapshot.docs) {
          try {
            final message = MessageModel.fromFirestore(doc);
            receivedMessages[message.id] = message;
          } catch (e) {
            debugPrint(
              '💬 [MESSAGING SERVICE] Error parsing received message ${doc.id}: $e',
            );
          }
        }
        emitCombined();
      },
      onError: (error) {
        debugPrint(
          '💬 [MESSAGING SERVICE] Error in received messages stream: $error',
        );
        if (!controller.isClosed) {
          controller.addError(error);
        }
      },
    );

    controller.onCancel = () {
      sentSub?.cancel();
      receivedSub?.cancel();
    };

    return controller.stream;
  }

  /// Send a message to a conversation
  Future<void> sendConversationMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? parentMessageId,
  }) async {
    debugPrint('💬 [MESSAGING SERVICE] Sending conversation message');
    debugPrint('   conversationId: $conversationId');
    debugPrint('   senderId: $senderId');
    debugPrint('   parentMessageId: $parentMessageId');

    // Get sender display name
    final senderName = await getUserDisplayName(senderId);

    final batch = _firestore.batch();

    // Add message to conversation subcollection
    final messageRef = _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      if (parentMessageId != null) 'parentMessageId': parentMessageId,
    });

    // Update conversation
    final conversationRef = _firestore
        .collection(AppConstants.conversationsCollection)
        .doc(conversationId);

    batch.update(conversationRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    debugPrint('💬 [MESSAGING SERVICE] Conversation message sent successfully');

    // Log audit event
    await _auditLog.logMessageUpdate(
      action: 'message_sent',
      message: 'Sent message in conversation',
      conversationId: conversationId,
      messageId: messageRef.id,
      metadata: {'senderId': senderId, 'hasReply': parentMessageId != null},
    );
  }

  /// Send a standalone message
  Future<void> sendStandaloneMessage({
    required String senderId,
    required String recipientId,
    required String text,
    required String senderName,
    required String senderRole,
    String? parentMessageId,
  }) async {
    debugPrint('💬 [MESSAGING SERVICE] Sending standalone message');
    debugPrint('   senderId: $senderId');
    debugPrint('   recipientId: $recipientId');
    debugPrint('   parentMessageId: $parentMessageId');

    final messageRef = await _firestore
        .collection(AppConstants.messagesCollection)
        .add({
          'senderId': senderId,
          'senderName': senderName,
          'senderRole': senderRole,
          'recipientId': recipientId,
          'message': text,
          'subject': text,
          'read': false,
          if (parentMessageId != null) 'parentMessageId': parentMessageId,
          'createdAt': FieldValue.serverTimestamp(),
        });

    debugPrint('💬 [MESSAGING SERVICE] Standalone message sent successfully');

    // Log audit event
    await _auditLog.logMessageUpdate(
      action: 'standalone_message_sent',
      message: 'Sent standalone message',
      messageId: messageRef.id,
      metadata: {
        'senderId': senderId,
        'recipientId': recipientId,
        'hasReply': parentMessageId != null,
      },
    );
  }

  /// Get user display name (displayName or firstName)
  Future<String> getUserDisplayName(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      final userData = userDoc.data();
      if (userData == null) return 'Unknown User';

      final displayName = userData['displayName'];
      final firstName = userData['firstName'] ?? '';

      if (displayName != null && displayName.toString().trim().isNotEmpty) {
        return displayName.toString();
      }

      return firstName.isNotEmpty ? firstName : 'Unknown User';
    } catch (e) {
      debugPrint('💬 [MESSAGING SERVICE] Error fetching user display name: $e');
      return 'Unknown User';
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead({
    required String messageId,
    required String conversationId,
    bool isConversationMessage = true,
  }) async {
    try {
      if (isConversationMessage) {
        await _firestore
            .collection(AppConstants.conversationsCollection)
            .doc(conversationId)
            .collection('messages')
            .doc(messageId)
            .update({'read': true});
      } else {
        await _firestore
            .collection(AppConstants.messagesCollection)
            .doc(messageId)
            .update({'read': true});
      }
      debugPrint('💬 [MESSAGING SERVICE] Message marked as read: $messageId');

      // Log audit event
      await _auditLog.logMessageUpdate(
        action: 'message_read',
        message: 'Marked message as read',
        conversationId: isConversationMessage ? conversationId : null,
        messageId: messageId,
      );
    } catch (e) {
      debugPrint('💬 [MESSAGING SERVICE] Error marking message as read: $e');
    }
  }

  /// Find or create a conversation between two users
  /// Returns the conversation ID
  Future<String> findOrCreateConversation({
    required String userId1,
    required String userId2,
  }) async {
    debugPrint('💬 [MESSAGING SERVICE] Finding or creating conversation');
    debugPrint('   userId1: $userId1');
    debugPrint('   userId2: $userId2');

    // Sort user IDs to ensure consistent conversation lookup
    final participants = [userId1, userId2]..sort();

    try {
      // Check if conversation already exists
      // Query conversations where participants array contains userId1
      // Then filter for those that also contain userId2
      final querySnapshot = await _firestore
          .collection(AppConstants.conversationsCollection)
          .where('participants', arrayContains: userId1)
          .get();

      // Filter for conversations that contain both participants
      final existingConversation = querySnapshot.docs.firstWhere((doc) {
        final data = doc.data();
        final docParticipants = List<String>.from(data['participants'] ?? []);
        return docParticipants.length == 2 &&
            docParticipants.contains(userId1) &&
            docParticipants.contains(userId2);
      }, orElse: () => throw StateError('No conversation found'));

      final conversationId = existingConversation.id;
      debugPrint(
        '💬 [MESSAGING SERVICE] Found existing conversation: $conversationId',
      );
      return conversationId;
    } catch (e) {
      // No existing conversation found, create a new one
      debugPrint(
        '💬 [MESSAGING SERVICE] No existing conversation found, creating new one',
      );

      final conversationRef = _firestore
          .collection(AppConstants.conversationsCollection)
          .doc();

      await conversationRef.set({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': {userId1: 0, userId2: 0},
      });

      final conversationId = conversationRef.id;
      debugPrint(
        '💬 [MESSAGING SERVICE] Created new conversation: $conversationId',
      );

      // Log audit event
      await _auditLog.logMessageUpdate(
        action: 'conversation_created',
        message: 'Created new conversation',
        conversationId: conversationId,
        metadata: {'participants': participants},
      );

      return conversationId;
    }
  }

  /// Get parent message for reply
  Future<MessageModel?> getParentMessage({
    required String parentMessageId,
    String? conversationId,
  }) async {
    try {
      if (conversationId != null && !conversationId.startsWith('msg_')) {
        // Get from conversation subcollection
        final doc = await _firestore
            .collection(AppConstants.conversationsCollection)
            .doc(conversationId)
            .collection('messages')
            .doc(parentMessageId)
            .get();

        if (doc.exists) {
          return MessageModel.fromConversationMessage(doc, conversationId);
        }
      } else {
        // Get from messages collection
        final doc = await _firestore
            .collection(AppConstants.messagesCollection)
            .doc(parentMessageId)
            .get();

        if (doc.exists) {
          return MessageModel.fromFirestore(doc);
        }
      }
      return null;
    } catch (e) {
      debugPrint('💬 [MESSAGING SERVICE] Error getting parent message: $e');
      return null;
    }
  }
}
