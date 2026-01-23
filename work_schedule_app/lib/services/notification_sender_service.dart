import 'dart:developer';

import 'package:cloud_functions/cloud_functions.dart';

/// Service for sending push notifications to employees via Cloud Functions.
/// 
/// This service provides methods to send notifications but does NOT
/// automatically trigger any notifications. You must explicitly call
/// these methods when you want to send notifications.
/// 
/// Available notification types:
/// - Single employee notification
/// - Multiple employees notification  
/// - Topic-based broadcast notification
class NotificationSenderService {
  static final NotificationSenderService _instance = NotificationSenderService._internal();
  static NotificationSenderService get instance => _instance;

  NotificationSenderService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Send a notification to a single employee.
  /// 
  /// [employeeUid] - The Firebase UID of the employee
  /// [title] - The notification title
  /// [body] - The notification body text (optional)
  /// [data] - Additional data payload (optional)
  Future<NotificationResult> sendToEmployee({
    required String employeeUid,
    required String title,
    String? body,
    Map<String, String>? data,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotificationToEmployee');
      final result = await callable.call<Map<String, dynamic>>({
        'employeeUid': employeeUid,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      final success = result.data['success'] as bool? ?? false;
      log('Notification to $employeeUid: ${success ? 'sent' : 'failed'}', 
          name: 'NotificationSenderService');

      return NotificationResult(
        success: success,
        messageId: result.data['messageId'] as String?,
        reason: result.data['reason'] as String?,
      );
    } catch (e) {
      log('Error sending notification to employee: $e', 
          name: 'NotificationSenderService');
      return NotificationResult(success: false, error: e.toString());
    }
  }

  /// Send a notification to multiple employees.
  /// 
  /// [employeeUids] - List of Firebase UIDs of the employees
  /// [title] - The notification title
  /// [body] - The notification body text (optional)
  /// [data] - Additional data payload (optional)
  Future<MultiNotificationResult> sendToMultiple({
    required List<String> employeeUids,
    required String title,
    String? body,
    Map<String, String>? data,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotificationToMultiple');
      final result = await callable.call<Map<String, dynamic>>({
        'employeeUids': employeeUids,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      final success = result.data['success'] as bool? ?? false;
      final sent = result.data['sent'] as int? ?? 0;
      final failed = result.data['failed'] as int? ?? 0;

      log('Notification to ${employeeUids.length} employees: $sent sent, $failed failed', 
          name: 'NotificationSenderService');

      return MultiNotificationResult(
        success: success,
        sent: sent,
        failed: failed,
        reason: result.data['reason'] as String?,
      );
    } catch (e) {
      log('Error sending notifications to multiple: $e', 
          name: 'NotificationSenderService');
      return MultiNotificationResult(success: false, sent: 0, failed: 0, error: e.toString());
    }
  }

  /// Send a notification to all subscribers of a topic.
  /// 
  /// [topic] - The topic name (e.g., 'announcements')
  /// [title] - The notification title
  /// [body] - The notification body text (optional)
  /// [data] - Additional data payload (optional)
  Future<NotificationResult> sendToTopic({
    required String topic,
    required String title,
    String? body,
    Map<String, String>? data,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotificationToTopic');
      final result = await callable.call<Map<String, dynamic>>({
        'topic': topic,
        'title': title,
        'body': body,
        'data': data ?? {},
      });

      final success = result.data['success'] as bool? ?? false;
      log('Topic notification to $topic: ${success ? 'sent' : 'failed'}', 
          name: 'NotificationSenderService');

      return NotificationResult(
        success: success,
        messageId: result.data['messageId'] as String?,
      );
    } catch (e) {
      log('Error sending topic notification: $e', 
          name: 'NotificationSenderService');
      return NotificationResult(success: false, error: e.toString());
    }
  }

  // ============== CONVENIENCE METHODS ==============
  // These are pre-configured notification types you can use

  /// Notify an employee that their time-off request was approved.
  /// NOTE: This does NOT automatically trigger - you must call it explicitly.
  Future<NotificationResult> notifyTimeOffApproved({
    required String employeeUid,
    required String date,
    required String timeOffType,
  }) async {
    return sendToEmployee(
      employeeUid: employeeUid,
      title: 'Time Off Approved ✓',
      body: 'Your $timeOffType request for $date has been approved.',
      data: {
        'type': 'time_off_approved',
        'date': date,
        'timeOffType': timeOffType,
      },
    );
  }

  /// Notify an employee that their time-off request was denied.
  /// NOTE: This does NOT automatically trigger - you must call it explicitly.
  Future<NotificationResult> notifyTimeOffDenied({
    required String employeeUid,
    required String date,
    required String timeOffType,
    String? reason,
  }) async {
    return sendToEmployee(
      employeeUid: employeeUid,
      title: 'Time Off Request Denied',
      body: reason != null 
          ? 'Your $timeOffType request for $date was denied: $reason'
          : 'Your $timeOffType request for $date was denied.',
      data: {
        'type': 'time_off_denied',
        'date': date,
        'timeOffType': timeOffType,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// Notify employees that a new schedule has been published.
  /// NOTE: This does NOT automatically trigger - you must call it explicitly.
  Future<MultiNotificationResult> notifySchedulePublished({
    required List<String> employeeUids,
    required String weekOf,
  }) async {
    return sendToMultiple(
      employeeUids: employeeUids,
      title: 'New Schedule Available 📅',
      body: 'The schedule for the week of $weekOf has been published.',
      data: {
        'type': 'schedule_published',
        'weekOf': weekOf,
      },
    );
  }

  /// Send an announcement to all employees.
  /// NOTE: This does NOT automatically trigger - you must call it explicitly.
  Future<NotificationResult> sendAnnouncement({
    required String title,
    required String message,
  }) async {
    return sendToTopic(
      topic: 'announcements',
      title: title,
      body: message,
      data: {
        'type': 'announcement',
      },
    );
  }
}

/// Result of sending a single notification
class NotificationResult {
  final bool success;
  final String? messageId;
  final String? reason;
  final String? error;

  NotificationResult({
    required this.success,
    this.messageId,
    this.reason,
    this.error,
  });
}

/// Result of sending notifications to multiple recipients
class MultiNotificationResult {
  final bool success;
  final int sent;
  final int failed;
  final String? reason;
  final String? error;

  MultiNotificationResult({
    required this.success,
    required this.sent,
    required this.failed,
    this.reason,
    this.error,
  });
}
