import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderRole;
  final String recipientId;
  final String? recipientName;
  final String? recipientRole;
  final String text;
  final String? subject;
  final bool isRead;
  final String? parentMessageId; // For reply messages
  final DateTime createdAt;
  final DateTime? timestamp; // For conversation messages

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderRole,
    required this.recipientId,
    this.recipientName,
    this.recipientRole,
    required this.text,
    this.subject,
    required this.isRead,
    this.parentMessageId,
    required this.createdAt,
    this.timestamp,
  });

  // Factory constructor for messages from messages collection
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Message document data is null');
    }

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'],
      recipientId: data['recipientId'] ?? '',
      recipientName: data['recipientName'],
      recipientRole: data['recipientRole'],
      text: data['message'] ?? data['text'] ?? '',
      subject: data['subject'],
      isRead: data['read'] ?? false,
      parentMessageId: data['parentMessageId'],
      createdAt: _parseTimestamp(data['createdAt']),
      timestamp: null,
    );
  }

  // Factory constructor for messages from conversation subcollection
  factory MessageModel.fromConversationMessage(
    DocumentSnapshot doc,
    String conversationId,
  ) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Message document data is null');
    }

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown', // May need to fetch from user doc
      senderRole: data['senderRole'],
      recipientId: '', // Will be determined from conversation participants
      recipientName: null,
      recipientRole: null,
      text: data['text'] ?? '',
      subject: null,
      isRead: data['read'] ?? false,
      parentMessageId: data['parentMessageId'],
      createdAt: _parseTimestamp(data['timestamp'] ?? data['createdAt']),
      timestamp: _parseTimestamp(data['timestamp']),
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      if (senderRole != null) 'senderRole': senderRole,
      'recipientId': recipientId,
      if (recipientName != null) 'recipientName': recipientName,
      if (recipientRole != null) 'recipientRole': recipientRole,
      'message': text,
      if (subject != null) 'subject': subject,
      'read': isRead,
      if (parentMessageId != null) 'parentMessageId': parentMessageId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? recipientId,
    String? recipientName,
    String? recipientRole,
    String? text,
    String? subject,
    bool? isRead,
    String? parentMessageId,
    DateTime? createdAt,
    DateTime? timestamp,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      recipientRole: recipientRole ?? this.recipientRole,
      text: text ?? this.text,
      subject: subject ?? this.subject,
      isRead: isRead ?? this.isRead,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      createdAt: createdAt ?? this.createdAt,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

