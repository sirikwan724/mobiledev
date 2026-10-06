import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/room.dart';
import '../../domain/models/booking.dart';
import '../viewmodels/booking_form_viewmodel.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.room, this.booking});

  final Room room;
  final Booking? booking;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  final _purposeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    if (booking != null) {
      _date = DateTime(booking.startTime.year, booking.startTime.month, booking.startTime.day);
      _start = TimeOfDay.fromDateTime(booking.startTime);
      _end = TimeOfDay.fromDateTime(booking.endTime);
      _purposeController.text = booking.purpose;
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  DateTime _at(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() => isStart ? _start = picked : _end = picked);
    }
  }

  Future<void> _submit(BookingFormViewModel viewModel) async {
    final ok = await viewModel.submit(
      bookingId: widget.booking?.id,
      roomId: widget.room.id,
      startTime: _at(_start),
      endTime: _at(_end),
      purpose: _purposeController.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
            content: Text(widget.booking == null ? 'จองห้องสำเร็จ' : 'แก้ไขการจองสำเร็จ'),
          ));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookingFormViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('${widget.booking == null ? 'จอง' : 'แก้ไขการจอง'} ${widget.room.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('วันที่'),
            subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
            onTap: _pickDate,
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('เวลาเริ่ม'),
            subtitle: Text(_start.format(context)),
            onTap: () => _pickTime(true),
          ),
          ListTile(
            leading: const Icon(Icons.access_time_filled),
            title: const Text('เวลาสิ้นสุด'),
            subtitle: Text(_end.format(context)),
            onTap: () => _pickTime(false),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _purposeController,
            decoration: const InputDecoration(
              labelText: 'วัตถุประสงค์ (ไม่บังคับ)',
              border: OutlineInputBorder(),
            ),
          ),
          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(viewModel.errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: viewModel.isSaving ? null : () => _submit(viewModel),
            child: viewModel.isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.booking == null ? 'ยืนยันการจอง' : 'บันทึกการแก้ไข'),
          ),
        ],
      ),
    );
  }
}
