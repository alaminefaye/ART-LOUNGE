import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../orders/order_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<NotificationItem> _items = [];
  int _unreadCount = 0;
  bool _loading = true;
  String? _error;
  bool _filterUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.getNotifications(unreadOnly: _filterUnreadOnly);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result['data'] as List<NotificationItem>;
      _unreadCount = result['unread_count'] as int? ?? 0;
      _error = result['message'] as String?;
    });
  }

  Future<void> _markAsRead(NotificationItem n) async {
    if (n.isRead) return;
    await _service.markAsRead(n.id);
    _load();
  }

  Future<void> _markAllAsRead() async {
    await _service.markAllAsRead();
    _load();
  }

  void _openOrderIfPossible(NotificationItem n) {
    final data = n.data;
    if (data != null && data['commande_id'] != null) {
      final id = data['commande_id'] is int
          ? data['commande_id'] as int
          : int.tryParse(data['commande_id'].toString());
      if (id != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: id),
          ),
        ).then((_) => _load());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: () async {
                await _markAllAsRead();
              },
              icon: const Icon(Icons.done_all, color: Colors.orange, size: 20),
              label: const Text(
                'Tout marquer lu',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          PopupMenuButton<bool>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (v) {
              setState(() => _filterUnreadOnly = v);
              _load();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: false, child: Text('Toutes')),
              const PopupMenuItem(value: true, child: Text('Non lues uniquement')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: Colors.orange,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _load,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications_none,
                                      size: 64, color: Colors.grey[600]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filterUnreadOnly
                                        ? 'Aucune notification non lue'
                                        : 'Aucune notification',
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final n = _items[index];
                          return _NotificationTile(
                            notification: n,
                            onTap: () {
                              _markAsRead(n);
                              _openOrderIfPossible(n);
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR')
        .format(notification.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? const Color(0xFF252525).withValues(alpha: 0.6)
                : const Color(0xFF252525),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: isRead ? Colors.grey : Colors.orange,
                width: 4,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                notification.type == 'commande'
                    ? Icons.receipt_long
                    : Icons.notifications,
                color: isRead ? Colors.grey : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (notification.body != null &&
                        notification.body!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.circle, color: Colors.white, size: 8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
