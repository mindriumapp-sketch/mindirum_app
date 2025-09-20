import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/data/mongo_service.dart';

/// 앱 라이프사이클을 감시하여 시작/백그라운드/종료 시각을 기록합니다.
class AppLifecycleLogger with WidgetsBindingObserver {
  AppLifecycleLogger() {
    WidgetsBinding.instance.addObserver(this);
    final initialState = WidgetsBinding.instance.lifecycleState;
    if (initialState == null || initialState == AppLifecycleState.resumed) {
      _startSession(DateTime.now());
    }
  }

  bool _isInForeground = false;
  DateTime? _sessionStart;
  DateTime? _currentBackgroundStart;
  Duration _backgroundAccumulated = Duration.zero;
  bool _hasPersistedSession = false;
  Future<void>? _sessionPersisting;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final now = DateTime.now();
    switch (state) {
      case AppLifecycleState.resumed:
        _handleForeground(now);
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _handleBackground(now);
        break;
      case AppLifecycleState.detached:
        _handleTerminate(now);
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startSession(DateTime timestamp) {
    _sessionStart = timestamp;
    _currentBackgroundStart = null;
    _backgroundAccumulated = Duration.zero;
    _isInForeground = true;
    _hasPersistedSession = false;
    _sessionPersisting = null;
    unawaited(_ensureSessionEntry());
    _logStart(timestamp);
  }

  void _handleForeground(DateTime timestamp) {
    if (_sessionStart == null) {
      _startSession(timestamp);
      return;
    }
    if (!_isInForeground) {
      if (_currentBackgroundStart != null) {
        _backgroundAccumulated += timestamp.difference(
          _currentBackgroundStart!,
        );
        _persistBackgroundEvent('exit', timestamp);
        _currentBackgroundStart = null;
      }
      _logForegroundResume(timestamp);
    }
    _isInForeground = true;
  }

  void _handleBackground(DateTime timestamp) {
    if (!_isInForeground) return;
    if (_sessionStart == null) return;
    _isInForeground = false;
    if (_currentBackgroundStart == null) {
      _currentBackgroundStart = timestamp;
      _persistBackgroundEvent('enter', timestamp);
    }
    _logBackground(timestamp);
  }

  void _handleTerminate(DateTime timestamp) {
    if (_sessionStart == null) return;
    if (_currentBackgroundStart != null) {
      _backgroundAccumulated += timestamp.difference(_currentBackgroundStart!);
      _persistBackgroundEvent('exit', timestamp);
      _currentBackgroundStart = null;
    }
    _logTerminate(timestamp);
    unawaited(_finalizeSession(timestamp));
    _resetSessionState();
  }

  Future<void> _finalizeSession(DateTime endTime) async {
    final start = _sessionStart;
    if (start == null) return;
    final totalDuration = endTime.difference(start);
    final effective = totalDuration - _backgroundAccumulated;
    if (effective.isNegative) return;
    final durationMinutes = effective.inSeconds / 60.0;
    await _ensureSessionEntry();
    await _withUserId((userId) async {
      try {
        await MongoService.instance.completeScreenTimeEntry(
          userId: userId,
          startTime: start,
          endTime: endTime,
          durationMinutes: durationMinutes,
        );
      } catch (e, st) {
        debugPrint('screenTime complete failed: $e\n$st');
      }
    });
  }

  void _resetSessionState() {
    _sessionStart = null;
    _currentBackgroundStart = null;
    _backgroundAccumulated = Duration.zero;
    _isInForeground = false;
    _hasPersistedSession = false;
    _sessionPersisting = null;
  }

  void _logStart(DateTime timestamp) {
    debugPrint('앱 시작: $timestamp');
  }

  void _logForegroundResume(DateTime timestamp) {
    debugPrint('앱 전면 복귀: $timestamp');
  }

  void _logBackground(DateTime timestamp) {
    debugPrint('앱 백그라운드 전환: $timestamp');
  }

  void _logTerminate(DateTime timestamp) {
    debugPrint('앱 종료: $timestamp');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_sessionStart != null) {
      _handleTerminate(DateTime.now());
    }
  }

  void _persistBackgroundEvent(String type, DateTime timestamp) {
    final start = _sessionStart;
    if (start == null) return;
    unawaited(() async {
      await _ensureSessionEntry();
      await _withUserId((userId) async {
        try {
          await MongoService.instance.addScreenTimeBackgroundEvent(
            userId: userId,
            startTime: start,
            type: type,
            timestamp: timestamp,
          );
        } catch (e, st) {
          debugPrint('screenTime background $type failed: $e\n$st');
        }
      });
    }());
  }

  Future<void> _ensureSessionEntry() {
    if (_hasPersistedSession) return Future.value();
    final start = _sessionStart;
    if (start == null) return Future.value();
    final inFlight = _sessionPersisting;
    if (inFlight != null) return inFlight;

    final future = _withUserId((userId) async {
      try {
        await MongoService.instance.createScreenTimeEntry(
          userId: userId,
          startTime: start,
        );
        _hasPersistedSession = true;
      } catch (e, st) {
        debugPrint('screenTime start failed: $e\n$st');
      }
    }).whenComplete(() {
      _sessionPersisting = null;
    });

    _sessionPersisting = future;
    return future;
  }

  Future<void> _withUserId(Future<void> Function(String userId) action) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('uid');
    if (userId == null || userId.isEmpty) return;
    await action(userId);
  }
}

/// Scoped widget that installs [AppLifecycleLogger] for its subtree.
class LifecycleLoggerScope extends StatefulWidget {
  final Widget child;
  const LifecycleLoggerScope({super.key, required this.child});
  @override
  State<LifecycleLoggerScope> createState() => _LifecycleLoggerScopeState();
}

class _LifecycleLoggerScopeState extends State<LifecycleLoggerScope> {
  late final AppLifecycleLogger _logger;
  @override
  void initState() {
    super.initState();
    _logger = AppLifecycleLogger();
  }

  @override
  void dispose() {
    _logger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
