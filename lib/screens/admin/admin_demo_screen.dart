import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/state_views.dart';

class AdminDemoScreen extends StatefulWidget {
  const AdminDemoScreen({super.key});

  @override
  State<AdminDemoScreen> createState() => _AdminDemoScreenState();
}

class _AdminDemoScreenState extends State<AdminDemoScreen> {
  String? _running;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AdminProvider>().loadDemoScenarios());
  }

  Future<void> _run(String name) async {
    final admin = context.read<AdminProvider>();
    setState(() => _running = name);
    final result = await admin.runDemoScenario(name);
    if (!mounted) return;
    setState(() => _running = null);
    final expected = result?['expected_action'] ?? result?['action'];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result != null ? 'Ran "$name" — action: ${expected ?? 'see audit log'}' : (admin.error ?? 'Failed to run scenario')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Demo Scenarios')),
      body: Builder(builder: (_) {
        if (admin.busy && admin.demoScenarios.isEmpty) return const ListRowSkeleton(count: 3);
        if (admin.error != null && admin.demoScenarios.isEmpty) {
          return ErrorStateView(message: admin.error!, onRetry: () => admin.loadDemoScenarios());
        }
        if (admin.demoScenarios.isEmpty) {
          return const EmptyStateView(
            icon: Icons.play_circle_outline_rounded,
            title: 'No demo scenarios',
            subtitle: 'The ML service did not report any preset scenarios.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: admin.demoScenarios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final scenario = Map<String, dynamic>.from(admin.demoScenarios[i] as Map);
            final name = (scenario['name'] ?? '').toString();
            final description = (scenario['description'] ?? '').toString();
            final expected = (scenario['expected'] ?? '').toString();
            final isRunning = _running == name;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(description, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                  if (expected.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Expected: $expected',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isRunning ? null : () => _run(name),
                      icon: isRunning
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(isRunning ? 'Running…' : 'Run scenario'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
