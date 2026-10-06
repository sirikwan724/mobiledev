import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_mode_controller.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} เวลา ${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isDark = context.watch<ThemeModeController>().isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ภาพรวม'),
        actions: [
          IconButton(
            tooltip: isDark ? 'เปลี่ยนเป็นโหมดสว่าง' : 'เปลี่ยนเป็นโหมดมืด',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: context.read<ThemeModeController>().toggle,
          ),
        ],
      ),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, DashboardViewModel vm) {
    if (vm.isLoading) return const Center(child: CircularProgressIndicator());
    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vm.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: vm.load,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    final next = vm.nextBooking;
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('สรุปการใช้งานของคุณ', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 3 : 1;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.2 : 1.5,
                children: [
                  _SummaryCard(
                    icon: Icons.meeting_room_outlined,
                    label: 'ห้องที่เปิดให้จอง',
                    value: '${vm.rooms.length}',
                  ),
                  _SummaryCard(
                    icon: Icons.event_available_outlined,
                    label: 'การจองที่กำลังจะมาถึง',
                    value: '${vm.upcomingCount}',
                  ),
                  _SummaryCard(
                    icon: Icons.event_busy_outlined,
                    label: 'รายการที่ยกเลิก',
                    value: '${vm.cancelledCount}',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('การจองครั้งถัดไป', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: next == null
                  ? const Text('ยังไม่มีการจองที่กำลังจะมาถึง')
                  : ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.event_note)),
                      title: Text(next.roomName),
                      subtitle: Text(
                        '${_formatDate(next.startTime)}\nถึง ${_formatDate(next.endTime)}',
                      ),
                      isThreeLine: true,
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/rooms'),
                icon: const Icon(Icons.search),
                label: const Text('เลือกห้อง'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/my-bookings'),
                icon: const Icon(Icons.list_alt),
                label: const Text('ดูการจองทั้งหมด'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(child: Text(label)),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      );
}
