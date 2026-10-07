import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await context.read<ApiClient>().getNotifications();
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: _loading
            ? const ListRowSkeleton()
            : (_items == null || _items!.isEmpty)
                ? const EmptyStateView(
                    icon: Icons.notifications_none_rounded,
                    title: 'All caught up',
                    subtitle: 'CartGuard will notify you here if it ever spots something worth flagging in your cart.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final n = _items![i];
                        final message = (n is Map ? (n['message'] ?? n['text'] ?? '') : n).toString();
                        final channel = (n is Map ? (n['channel'] ?? '') : '').toString();
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(color: const Color(0xFFF1EEF9), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(message.isEmpty ? 'CartGuard update' : message,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.8, height: 1.35)),
                                    if (channel.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('via $channel', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
