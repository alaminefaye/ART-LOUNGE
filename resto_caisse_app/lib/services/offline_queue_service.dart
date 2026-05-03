import 'package:flutter/foundation.dart';

import 'local_cache.dart';

class OfflineQueueItem {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  OfflineQueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      payload: (json['payload'] is Map<String, dynamic>)
          ? (json['payload'] as Map<String, dynamic>)
          : <String, dynamic>{},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OfflineQueueService {
  static const String _key = 'offline_queue_v1';

  Future<List<OfflineQueueItem>> getAll() async {
    final raw = await LocalCache.getJson(_key);
    if (raw is! List) return [];
    final List<OfflineQueueItem> items = [];
    for (final e in raw) {
      if (e is Map) {
        items.add(OfflineQueueItem.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    return items;
  }

  Future<void> enqueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final items = await getAll();
    final id = '${DateTime.now().millisecondsSinceEpoch}_${items.length}';
    items.add(
      OfflineQueueItem(
        id: id,
        type: type,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
    await _save(items);
    debugPrint('OfflineQueue enqueue: $type ($id)');
  }

  Future<void> removeById(String id) async {
    final items = await getAll();
    items.removeWhere((e) => e.id == id);
    await _save(items);
  }

  Future<void> _save(List<OfflineQueueItem> items) async {
    await LocalCache.setJson(_key, items.map((e) => e.toJson()).toList());
  }
}
