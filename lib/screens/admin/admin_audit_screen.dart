import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';

class AdminAuditScreen extends StatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadAuditLog());
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Audit Log')),
      body: Builder(builder: (_) {
        if (admin.busy && admin.auditLogs.isEmpty) return const ListRowSkeleton(count: 6);
        if (admin.error != null && admin.auditLogs.isEmpty) {
          return ErrorStateView(message: admin.error!, onRetry: () => admin.loadAuditLog());
        }
        if (admin.auditLogs.isEmpty) {
          return const EmptyStateView(
            icon: Icons.fact_check_outlined,
            title: 'No audit entries',
            subtitle: 'Decisions made by the risk-scoring engine will be logged here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => admin.loadAuditLog(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: admin.auditLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final log = Map<String, dynamic>.from(admin.auditLogs[i] as Map);
              final action = (log['action'] ?? log['decision'] ?? 'ACTION').toString();
              final sessionId = (log['session_id'] ?? log['sessionId'] ?? '').toString();
              final risk = log['risk_score'];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(action, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          if (sessionId.isNotEmpty)
                            Text(sessionId, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    if (risk is num)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text('risk ${risk.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.warning)),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
