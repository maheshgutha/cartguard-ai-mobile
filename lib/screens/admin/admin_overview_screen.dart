import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    if (admin.busy && admin.overview.isEmpty) {
      return const ProductGridSkeleton(count: 6);
    }
    if (admin.error != null && admin.overview.isEmpty) {
      return ErrorStateView(message: admin.error!, onRetry: () => admin.loadOverview());
    }

    final o = admin.overview;
    final offline = o['ml_service_offline'] == true;

    final cards = <_Kpi>[
      _Kpi('Total Users', _n(o['total_users']), Icons.groups_rounded, AppColors.primary),
      _Kpi('Total Orders', _n(o['total_orders']), Icons.receipt_long_rounded, AppColors.secondary),
      _Kpi('Live Carts', _n(o['live_carts']), Icons.shopping_bag_rounded, AppColors.warning),
      _Kpi('Total Sessions', _n(o['total_sessions']), Icons.podcasts_rounded, AppColors.primaryDark),
      _Kpi('High Risk Sessions', _n(o['high_risk_sessions']), Icons.warning_amber_rounded, AppColors.danger),
      _Kpi('Actions Taken', _n(o['actions_taken']), Icons.bolt_rounded, AppColors.secondary),
      _Kpi('Recovery Rate', _pct(o['recovery_rate']), Icons.trending_up_rounded, AppColors.secondary),
      _Kpi('Avg Risk Score', _num(o['avg_risk_score']), Icons.speed_rounded, AppColors.warning),
      _Kpi('Total Discount (₹)', _num(o['total_discount_inr']), Icons.local_offer_rounded, AppColors.primary),
      _Kpi('Avg Latency (ms)', _n(o['avg_latency_ms']), Icons.timer_outlined, AppColors.primaryDark),
    ];

    return RefreshIndicator(
      onRefresh: () => admin.loadOverview(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (offline)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('ML service is offline — showing partial metrics.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: cards.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (_, i) => _KpiCard(kpi: cards[i]),
          ),
        ],
      ),
    );
  }

  static String _n(dynamic v) => v == null ? '—' : '$v';
  static String _num(dynamic v) => v is num ? v.toStringAsFixed(1) : '—';
  static String _pct(dynamic v) => v is num ? '${(v * (v <= 1 ? 100 : 1)).toStringAsFixed(1)}%' : '—';
}

class _Kpi {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _Kpi(this.label, this.value, this.icon, this.color);
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.kpi});
  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: kpi.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(kpi.icon, size: 18, color: kpi.color),
          ),
          const SizedBox(height: 10),
          Text(kpi.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(kpi.label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
