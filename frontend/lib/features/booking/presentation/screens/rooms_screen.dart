import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../domain/models/room.dart';
import '../viewmodels/rooms_viewmodel.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RoomsViewModel>();
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกห้อง'),
        actions: [
          IconButton(
            tooltip: 'ภาพรวม',
            icon: const Icon(Icons.dashboard_outlined),
            onPressed: () => context.push('/dashboard'),
          ),
          IconButton(
            tooltip: 'การจองของฉัน',
            icon: const Icon(Icons.event_note),
            onPressed: () => context.push('/my-bookings'),
          ),
          IconButton(
            tooltip: context.watch<ThemeModeController>().isDark
                ? 'เปลี่ยนเป็นโหมดสว่าง'
                : 'เปลี่ยนเป็นโหมดมืด',
            icon: Icon(context.watch<ThemeModeController>().isDark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: context.read<ThemeModeController>().toggle,
          ),
          IconButton(
            tooltip: auth.userName ?? 'ออกจากระบบ',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmSignOut(context, auth),
          ),
        ],
      ),
      body: _Body(viewModel: viewModel),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthViewModel auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: Text('ออกจากระบบบัญชี ${auth.userName ?? ''} ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('ออกจากระบบ')),
        ],
      ),
    );
    if (confirmed == true) {
      await auth.signOut();
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.viewModel});

  final RoomsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage!),
            const SizedBox(height: 8),
            TextButton(onPressed: viewModel.load, child: const Text('ลองใหม่')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'ค้นหาห้อง',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: viewModel.search,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateTimeButton(
                        label: 'เริ่ม',
                        value: viewModel.availabilityStart,
                        onPressed: () => _pickDateTime(
                          context,
                          viewModel,
                          isStart: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateTimeButton(
                        label: 'สิ้นสุด',
                        value: viewModel.availabilityEnd,
                        onPressed: () => _pickDateTime(
                          context,
                          viewModel,
                          isStart: false,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: viewModel.searchAvailable,
                        icon: const Icon(Icons.event_available),
                        label: const Text('ค้นหาห้องว่าง'),
                      ),
                    ),
                    if (viewModel.isAvailabilityFilterActive) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'ล้างตัวกรองเวลา',
                        onPressed: viewModel.clearAvailability,
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: viewModel.filteredRooms.isEmpty
                ? Center(
                    child: Text(viewModel.isAvailabilityFilterActive
                        ? 'ไม่มีห้องว่างในช่วงเวลาที่เลือก'
                        : viewModel.rooms.isEmpty
                            ? 'ยังไม่มีห้อง'
                            : 'ไม่พบห้องที่ค้นหา'),
                  )
                : ListView.separated(
                    itemCount: viewModel.filteredRooms.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final Room room = viewModel.filteredRooms[i];
                      return ListTile(
                        leading: const Icon(Icons.meeting_room),
                        title: Text(room.name),
                        subtitle: Text('${room.location} • จุ ${room.capacity} คน'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/booking', extra: room),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(
    BuildContext context,
    RoomsViewModel viewModel, {
    required bool isStart,
  }) async {
    final current = isStart
        ? viewModel.availabilityStart
        : viewModel.availabilityEnd;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    viewModel.setAvailability(
      isStart ? selected : viewModel.availabilityStart,
      isStart ? viewModel.availabilityEnd : selected,
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.schedule),
      label: Text('$label ${value.day}/${value.month} ${two(value.hour)}:${two(value.minute)}'),
    );
  }
}
