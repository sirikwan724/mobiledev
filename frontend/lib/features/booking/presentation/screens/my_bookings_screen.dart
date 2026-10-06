import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../domain/models/booking.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../viewmodels/my_bookings_viewmodel.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  String _fmt(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.day}/${t.month}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MyBookingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('การจองของฉัน'),
        actions: [
          IconButton(
            tooltip: context.watch<ThemeModeController>().isDark
                ? 'เปลี่ยนเป็นโหมดสว่าง'
                : 'เปลี่ยนเป็นโหมดมืด',
            icon: Icon(context.watch<ThemeModeController>().isDark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: context.read<ThemeModeController>().toggle,
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.errorMessage != null) {
            return Center(child: Text(viewModel.errorMessage!));
          }
          if (viewModel.bookings.isEmpty) {
            return const Center(child: Text('ยังไม่มีการจอง'));
          }
          return RefreshIndicator(
            onRefresh: viewModel.load,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: SegmentedButton<BookingFilter>(
                    segments: const [
                      ButtonSegment(value: BookingFilter.all, label: Text('ทั้งหมด')),
                      ButtonSegment(value: BookingFilter.confirmed, label: Text('ยืนยันแล้ว')),
                      ButtonSegment(value: BookingFilter.cancelled, label: Text('ยกเลิกแล้ว')),
                    ],
                    selected: {viewModel.filter},
                    onSelectionChanged: (selection) =>
                        viewModel.setFilter(selection.first),
                  ),
                ),
                Expanded(
                  child: viewModel.filteredBookings.isEmpty
                      ? Center(
                          child: Text(viewModel.filter == BookingFilter.cancelled
                              ? 'ไม่มีรายการที่ยกเลิก'
                              : 'ไม่มีรายการที่ยืนยันแล้ว'),
                        )
                      : ListView.separated(
              itemCount: viewModel.filteredBookings.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final Booking b = viewModel.filteredBookings[i];
                return ListTile(
                  title: Text(b.roomName),
                  subtitle: Text(
                    '${_fmt(b.startTime)} – ${_fmt(b.endTime)}'
                    '${b.purpose.isEmpty ? '' : '\n${b.purpose}'}',
                  ),
                  isThreeLine: b.purpose.isNotEmpty,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'จัดการการจอง',
                    onSelected: (action) => _handleAction(context, viewModel, b, action),
                    itemBuilder: (context) => [
                      if (!b.isCancelled)
                        const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                      if (!b.isCancelled)
                        const PopupMenuItem(value: 'cancel', child: Text('ยกเลิกการจอง')),
                      const PopupMenuItem(value: 'delete', child: Text('ลบรายการ')),
                    ],
                  ),
                );
              },
                    ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    MyBookingsViewModel viewModel,
    Booking booking,
    String action,
  ) async {
    if (action == 'edit') {
      await context.push('/booking/edit', extra: booking);
      if (context.mounted) await viewModel.load();
      return;
    }

    if (action == 'cancel') {
      await viewModel.cancel(booking.id);
      if (!context.mounted) return;
      final error = viewModel.actionErrorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'ยกเลิกการจองแล้ว')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบรายการจอง'),
        content: const Text('ต้องการลบรายการนี้อย่างถาวรหรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('กลับ')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final deleted = await viewModel.delete(booking.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(deleted ? 'ลบรายการแล้ว' : viewModel.actionErrorMessage ?? 'ลบรายการไม่สำเร็จ'),
    ));
  }
}
