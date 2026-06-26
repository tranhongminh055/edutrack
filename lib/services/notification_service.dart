import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single notification in the system
class AppNotification {
  final String id;
  final String title;
  final String sender;
  final String senderRole; // 'Giảng viên', 'Phòng Đào tạo', etc.
  final String date;
  final String? content;
  final bool isFromLecturer;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.sender,
    required this.senderRole,
    required this.date,
    this.content,
    this.isFromLecturer = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'sender': sender,
      'senderRole': senderRole,
      'date': date,
      'content': content,
      'isFromLecturer': isFromLecturer,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      sender: map['sender'] ?? '',
      senderRole: map['senderRole'] ?? '',
      date: map['date'] ?? '',
      content: map['content'],
      isFromLecturer: map['isFromLecturer'] ?? false,
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}

/// Shared notification service (Singleton) backed by Firestore
class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'notifications';

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  StreamSubscription? _subscription;

  NotificationService._internal() {
    _startListening();
  }

  void _startListening() {
    _subscription = _firestore
        .collection(_collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _notifications.clear();
      for (var doc in snapshot.docs) {
        _notifications.add(AppNotification.fromMap(doc.id, doc.data()));
      }
      _controller.add(List.unmodifiable(_notifications));
    }, onError: (e) {
      print('Error listening to notifications: $e');
    });
  }

  Stream<List<AppNotification>> get stream => _controller.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  /// IDs of notifications that have been "seen" by the student
  final Set<String> _seenIds = {};

  /// Mark a notification as seen
  void markAsSeen(String id) {
    _seenIds.add(id);
  }

  /// Check if a notification is new (unseen)
  bool isNew(String id) => !_seenIds.contains(id);

  /// Count of unseen notifications
  int get unseenCount =>
      _notifications.where((n) => !_seenIds.contains(n.id)).length;

  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    // Optimistic update
    _notifications.insert(0, notification);
    _controller.add(List.unmodifiable(_notifications));

    // Save to Firestore
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  /// Remove a notification
  Future<void> removeNotification(String id) async {
    // Optimistic update
    _notifications.removeWhere((n) => n.id == id);
    _controller.add(List.unmodifiable(_notifications));

    // Delete from Firestore
    try {
      await _firestore.collection(_collectionPath).doc(id).delete();
    } catch (e) {
      print('Error removing notification: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
