import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'session_data.dart';
import 'services/notification_service.dart';

class InsulinReminderScreen extends StatefulWidget {
  const InsulinReminderScreen({super.key});

  @override
  State<InsulinReminderScreen> createState() => _InsulinReminderScreenState();
}

class _InsulinReminderScreenState extends State<InsulinReminderScreen> {
  late TimeOfDay _selectedTime;
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _selectedTime = TimeOfDay.now();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _addReminder() async {
    // Request notification permission first
    final status = await Permission.notification.request();
    
    if (status.isDenied) {
      // User denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ต้องให้อนุญาตการแจ้งเตือนเพื่อใช้ฟีเจอร์นี้',
              style: GoogleFonts.kanit(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    if (status.isPermanentlyDenied) {
      // Open app settings
      openAppSettings();
      return;
    }
    
    final sessionData = Provider.of<SessionData>(context, listen: false);
    sessionData.addInsulinReminder(_selectedTime.hour, _selectedTime.minute);
    
    // Schedule notification
    await _notificationService.scheduleInsulinReminder(
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เพิ่มแจ้งเตือนเวลา ${_selectedTime.format(context)} สำเร็จ',
            style: GoogleFonts.kanit(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDEFE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDEFE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'แจ้งเตือนการฉีดอินซูลิน',
          style: GoogleFonts.kanit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<SessionData>(
        builder: (context, sessionData, child) {
          final reminders = sessionData.getInsulinReminders();
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ส่วนตั้งเวลาใหม่
                  Text(
                    'ตั้งเวลาแจ้งเตือน',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // แสดงเวลาที่เลือก
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _selectedTime.format(context),
                          style: GoogleFonts.kanit(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFFABB5A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'เวลาแจ้งเตือน',
                          style: GoogleFonts.kanit(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ปุ่มเลือกเวลา
                  ElevatedButton.icon(
                    onPressed: () => _selectTime(context),
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      'เปลี่ยนเวลา',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABB5A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ปุ่มเพิ่มแจ้งเตือน
                  ElevatedButton.icon(
                    onPressed: _addReminder,
                    icon: const Icon(Icons.add),
                    label: Text(
                      'เพิ่มแจ้งเตือน',
                      style: GoogleFonts.kanit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ส่วนแสดงรายการแจ้งเตือน
                  Text(
                    'รายการแจ้งเตือน (${reminders.length})',
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (reminders.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ยังไม่มีแจ้งเตือน',
                              style: GoogleFonts.kanit(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = reminders[index];
                        final hour = reminder['hour'] as int;
                        final minute = reminder['minute'] as int;
                        final id = reminder['id'] as String;
                        final timeStr =
                            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFABB5A)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.notifications_active,
                                        color: Color(0xFFFABB5A),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          timeStr,
                                          style: GoogleFonts.kanit(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'ก่อนอาหาร',
                                          style: GoogleFonts.kanit(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      sessionData.removeInsulinReminder(id);
                                      _notificationService.cancelInsulinReminder(hour, minute);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'ลบแจ้งเตือน $timeStr สำเร็จ',
                                            style: GoogleFonts.kanit(),
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    } else if (value == 'edit') {
                                      _showEditDialog(context, id, hour,
                                          minute, sessionData);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit),
                                          const SizedBox(width: 8),
                                          Text(
                                            'แก้ไข',
                                            style: GoogleFonts.kanit(),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete,
                                              color: Colors.red),
                                          const SizedBox(width: 8),
                                          Text(
                                            'ลบ',
                                            style: GoogleFonts.kanit(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, String id, int hour, int minute,
      SessionData sessionData) {
    TimeOfDay editTime = TimeOfDay(hour: hour, minute: minute);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFDEFE0),
              title: Text(
                'แก้ไขเวลาแจ้งเตือน',
                style: GoogleFonts.kanit(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${editTime.hour.toString().padLeft(2, '0')}:${editTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.kanit(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFABB5A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: editTime,
                      );
                      if (picked != null && picked != editTime) {
                        setDialogState(() {
                          editTime = picked;
                        });
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      'เลือกเวลา',
                      style: GoogleFonts.kanit(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFABB5A),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'ยกเลิก',
                    style: GoogleFonts.kanit(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    sessionData.updateInsulinReminder(
                      id,
                      editTime.hour,
                      editTime.minute,
                    );
                    // Cancel old reminder and schedule new one
                    _notificationService.cancelInsulinReminder(hour, minute);
                    _notificationService.scheduleInsulinReminder(
                      editTime.hour,
                      editTime.minute,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'อัปเดตแจ้งเตือนสำเร็จ',
                          style: GoogleFonts.kanit(),
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFABB5A),
                  ),
                  child: Text(
                    'บันทึก',
                    style: GoogleFonts.kanit(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
