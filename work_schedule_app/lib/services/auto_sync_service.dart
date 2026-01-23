import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/settings_dao.dart';
import '../models/employee.dart';
import '../models/time_off_entry.dart';
import 'firestore_sync_service.dart';
import 'settings_sync_service.dart';
import 'auth_service.dart';

/// Service that handles automatic syncing of data to the cloud.
/// 
/// When enabled, this service will:
/// - Sync employee changes automatically
/// - Sync shift changes automatically
/// - Sync time-off changes automatically
/// - Queue changes when offline and sync when back online
class AutoSyncService {
  static final AutoSyncService _instance = AutoSyncService._internal();
  static AutoSyncService get instance => _instance;

  AutoSyncService._internal();

  final FirestoreSyncService _firestoreSyncService = FirestoreSyncService.instance;
  final SettingsSyncService _settingsSyncService = SettingsSyncService.instance;
  final SettingsDao _settingsDao = SettingsDao();
  final Connectivity _connectivity = Connectivity();

  bool _isAutoSyncEnabled = false;
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Queue for offline changes
  final List<_SyncTask> _pendingTasks = [];
  bool _isSyncing = false;

  /// Initialize the auto-sync service
  Future<void> initialize() async {
    // Load the auto-sync setting
    final settings = await _settingsDao.getSettings();
    _isAutoSyncEnabled = settings.autoSyncEnabled;

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);
      
      // If we just came online and have pending tasks, process them
      if (wasOffline && _isOnline && _pendingTasks.isNotEmpty) {
        log('Back online - processing ${_pendingTasks.length} pending sync tasks', 
            name: 'AutoSyncService');
        _processPendingTasks();
      }
    });

    log('AutoSyncService initialized. Auto-sync: $_isAutoSyncEnabled, Online: $_isOnline', 
        name: 'AutoSyncService');
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Check if auto-sync is currently enabled
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;

  /// Check if we're currently online
  bool get isOnline => _isOnline;

  /// Get the number of pending sync tasks
  int get pendingTaskCount => _pendingTasks.length;

  /// Update the auto-sync enabled setting
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _isAutoSyncEnabled = enabled;
    await _settingsDao.updateField('autoSyncEnabled', enabled ? 1 : 0);
    log('Auto-sync ${enabled ? 'enabled' : 'disabled'}', name: 'AutoSyncService');

    // If enabling and we're online, do an initial full sync
    if (enabled && _isOnline && AuthService.instance.currentUserUid != null) {
      await _fullSync();
    }
  }

  /// Called when an employee is created or updated
  Future<void> onEmployeeChanged(Employee employee) async {
    if (!_isAutoSyncEnabled) return;
    if (AuthService.instance.currentUserUid == null) return;

    final task = _SyncTask(
      type: _SyncTaskType.employee,
      data: employee,
      timestamp: DateTime.now(),
    );

    if (_isOnline) {
      await _executeTask(task);
    } else {
      _queueTask(task);
    }
  }

  /// Called when an employee is deleted
  Future<void> onEmployeeDeleted(int employeeId) async {
    if (!_isAutoSyncEnabled) return;
    if (AuthService.instance.currentUserUid == null) return;

    final task = _SyncTask(
      type: _SyncTaskType.employeeDelete,
      data: employeeId,
      timestamp: DateTime.now(),
    );

    if (_isOnline) {
      await _executeTask(task);
    } else {
      _queueTask(task);
    }
  }

  /// Called when a time-off entry is created or updated
  Future<void> onTimeOffChanged(TimeOffEntry entry, Employee employee) async {
    if (!_isAutoSyncEnabled) return;
    if (AuthService.instance.currentUserUid == null) return;

    final task = _SyncTask(
      type: _SyncTaskType.timeOff,
      data: {'entry': entry, 'employee': employee},
      timestamp: DateTime.now(),
    );

    if (_isOnline) {
      await _executeTask(task);
    } else {
      _queueTask(task);
    }
  }

  /// Called when time-off data changes (batch sync without employee info)
  Future<void> onTimeOffDataChanged() async {
    if (!_isAutoSyncEnabled) return;
    if (AuthService.instance.currentUserUid == null) return;

    // For batch time-off changes, we do a full sync
    final task = _SyncTask(
      type: _SyncTaskType.shifts,  // Use shifts type to trigger full data sync
      data: null,
      timestamp: DateTime.now(),
    );

    if (_isOnline) {
      await _executeTask(task);
    } else {
      _queueTask(task);
    }
  }

  /// Called when a time-off entry is deleted
  Future<void> onTimeOffDeleted(int employeeId, int entryId) async {
    if (!_isAutoSyncEnabled) return;
    if (AuthService.instance.currentUserUid == null) return;

    final task = _SyncTask(
      type: _SyncTaskType.timeOffDelete,
      data: {'employeeId': employeeId, 'entryId': entryId},
      timestamp: DateTime.now(),
    );

    if (_isOnline) {
      await _executeTask(task);
    } else {
      _queueTask(task);
    }
  }

  /// Called when shifts are changed (batch sync)
  Future<void> onShiftsChanged() async {
    if (!_isAutoSyncEnabled) return;
    if (AuthService.instance.currentUserUid == null) return;

    final task = _SyncTask(
      type: _SyncTaskType.shifts,
      data: null,
      timestamp: DateTime.now(),
    );

    if (_isOnline) {
      await _executeTask(task);
    } else {
      _queueTask(task);
    }
  }

  /// Called when settings are changed
  Future<void> onSettingsChanged() async {
    if (!_isAutoSyncEnabled) return;
    if (AuthService.instance.currentUserUid == null) return;

    final task = _SyncTask(
      type: _SyncTaskType.settings,
      data: null,
      timestamp: DateTime.now(),
    );

    if (_isOnline) {
      await _executeTask(task);
    } else {
      _queueTask(task);
    }
  }

  /// Queue a task for later execution
  void _queueTask(_SyncTask task) {
    // Remove duplicate tasks of the same type for the same data
    _pendingTasks.removeWhere((t) => 
      t.type == task.type && 
      _isSameData(t.data, task.data)
    );
    _pendingTasks.add(task);
    log('Queued ${task.type.name} task (${_pendingTasks.length} pending)', 
        name: 'AutoSyncService');
  }

  bool _isSameData(dynamic a, dynamic b) {
    if (a is Employee && b is Employee) {
      return a.id == b.id;
    }
    if (a is int && b is int) {
      return a == b;
    }
    if (a is Map && b is Map) {
      return a['employeeId'] == b['employeeId'] && a['entryId'] == b['entryId'];
    }
    return false;
  }

  /// Execute a single sync task
  Future<void> _executeTask(_SyncTask task) async {
    try {
      switch (task.type) {
        case _SyncTaskType.employee:
          await _firestoreSyncService.syncEmployee(task.data as Employee);
          break;
        case _SyncTaskType.employeeDelete:
          await _firestoreSyncService.deleteEmployee(task.data as int);
          break;
        case _SyncTaskType.timeOff:
          final data = task.data as Map<String, dynamic>;
          await _firestoreSyncService.syncTimeOffEntry(
            data['entry'] as TimeOffEntry,
            data['employee'] as Employee,
          );
          break;
        case _SyncTaskType.timeOffDelete:
          final data = task.data as Map<String, dynamic>;
          await _firestoreSyncService.deleteTimeOffEntry(
            data['employeeId'] as int,
            data['entryId'] as int,
          );
          break;
        case _SyncTaskType.shifts:
          await _firestoreSyncService.uploadAllDataToCloud();
          break;
        case _SyncTaskType.settings:
          await _settingsSyncService.uploadAllSettings();
          break;
      }
      log('Executed ${task.type.name} sync task', name: 'AutoSyncService');
    } catch (e) {
      log('Error executing ${task.type.name} task: $e', name: 'AutoSyncService');
      // Re-queue the task if it failed
      _queueTask(task);
    }
  }

  /// Process all pending tasks
  Future<void> _processPendingTasks() async {
    if (_isSyncing || _pendingTasks.isEmpty) return;

    _isSyncing = true;
    log('Processing ${_pendingTasks.length} pending tasks', name: 'AutoSyncService');

    // Take a copy of the tasks and clear the queue
    final tasks = List<_SyncTask>.from(_pendingTasks);
    _pendingTasks.clear();

    for (final task in tasks) {
      if (!_isOnline) {
        // We went offline again, re-queue remaining tasks
        _pendingTasks.addAll(tasks.sublist(tasks.indexOf(task)));
        break;
      }
      await _executeTask(task);
    }

    _isSyncing = false;
    log('Finished processing pending tasks (${_pendingTasks.length} remaining)', 
        name: 'AutoSyncService');
  }

  /// Do a full sync of all data
  Future<void> _fullSync() async {
    try {
      log('Starting full sync...', name: 'AutoSyncService');
      await _firestoreSyncService.uploadAllDataToCloud();
      await _settingsSyncService.uploadAllSettings();
      log('Full sync complete', name: 'AutoSyncService');
    } catch (e) {
      log('Error during full sync: $e', name: 'AutoSyncService');
    }
  }

  /// Manually trigger a full sync
  Future<void> syncNow() async {
    if (!_isOnline) {
      log('Cannot sync - offline', name: 'AutoSyncService');
      return;
    }
    if (AuthService.instance.currentUserUid == null) {
      log('Cannot sync - not logged in', name: 'AutoSyncService');
      return;
    }
    await _fullSync();
  }
}

enum _SyncTaskType {
  employee,
  employeeDelete,
  timeOff,
  timeOffDelete,
  shifts,
  settings,
}

class _SyncTask {
  final _SyncTaskType type;
  final dynamic data;
  final DateTime timestamp;

  _SyncTask({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}
