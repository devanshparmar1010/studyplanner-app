import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

/// Offline-first sync service.
/// Queues operations in a Hive box and flushes when connectivity is restored.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  Box<String>? _pendingBox;
  bool _isSyncing = false;

  Future<void> init(GlobalKey<ScaffoldMessengerState> key) async {
    _messengerKey = key;
    _pendingBox = Hive.box<String>('pendingSync');

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online && !_isSyncing && (_pendingBox?.isNotEmpty ?? false)) {
        _flush();
      }
    });
  }

  /// Enqueue an operation for later sync.
  void enqueue(String type, String model, String itemId) {
    _pendingBox?.put(
      const Uuid().v4(),
      jsonEncode({
        'type': type,
        'model': model,
        'itemId': itemId,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  int get pendingCount => _pendingBox?.length ?? 0;

  Future<void> _flush() async {
    if (_isSyncing || (_pendingBox?.isEmpty ?? true)) return;
    _isSyncing = true;
    _showSnackBar('Syncing ${_pendingBox!.length} pending operations…', Colors.blue);

    try {
      final ops = _pendingBox!.values.toList();
      for (final op in ops) {
        final data = jsonDecode(op) as Map;
        // Stub: simulate API call — replace with real HTTP call in production
        await Future.delayed(const Duration(milliseconds: 80));
        debugPrint(
            '[SyncService] Flushed: ${data['type']} ${data['model']} ${data['itemId']}');
      }
      await _pendingBox!.clear();
      _showSnackBar('✅ Sync complete', Colors.green);
    } catch (e) {
      _showSnackBar('⚠️ Sync failed. Will retry on reconnect.', Colors.red);
    } finally {
      _isSyncing = false;
    }
  }

  void _showSnackBar(String message, Color color) {
    _messengerKey?.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
