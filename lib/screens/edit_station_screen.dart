import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../../models/polling_station.dart';
import '../../constants/app_theme.dart';

class EditStationScreen extends StatefulWidget {
  final PollingStation station;

  const EditStationScreen({super.key, required this.station});

  @override
  State<EditStationScreen> createState() => _EditStationScreenState();
}

class _EditStationScreenState extends State<EditStationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _zoneCtrl;
  late TextEditingController _provinceCtrl;
  bool _saving = false;

  final List<String> _validPrefixes = [
    'โรงเรียน',
    'วัด',
    'เต็นท์',
    'ศาลา',
    'หอประชุม',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.station.stationName);
    _zoneCtrl = TextEditingController(text: widget.station.zone);
    _provinceCtrl = TextEditingController(text: widget.station.province);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _zoneCtrl.dispose();
    _provinceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newName = _nameCtrl.text.trim();

    bool validPrefix = false;
    for (final prefix in _validPrefixes) {
      if (newName.startsWith(prefix)) {
        validPrefix = true;
        break;
      }
    }

    setState(() => _saving = true);

    final isDuplicate = await DatabaseHelper.instance.checkDuplicateStation(
      widget.station.stationId,
      newName,
    );

    final incidentCount = await DatabaseHelper.instance.countIncidentsByStation(
      widget.station.stationId,
    );

    if (incidentCount > 0) {
      setState(() => _saving = false);
      final confirm = await _showConfirmDialog(
        'ยืนยันการแก้ไข',
        'หน่วยนี้มีประวัติร้องเรียน $incidentCount เรื่อง ยืนยันการแก้ไขข้อมูลหรือไม่?',
      );
      if (confirm != true) return;
      setState(() => _saving = true);
    }

    final updatedStation = PollingStation(
      stationId: widget.station.stationId,
      stationName: newName,
      zone: _zoneCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
    );

    await DatabaseHelper.instance.updateStation(updatedStation);

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกข้อมูลสำเร็จ'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.warning),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, color: AppColors.warning),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขข้อมูลหน่วยเลือกตั้ง')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'รหัสหน่วย: ${widget.station.stationId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),
              _Label('ชื่อหน่วยเลือกตั้ง'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'เช่น เต็นท์ลานจอดรถ...',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อหน่วย' : null,
              ),
              const SizedBox(height: 16),
              _Label('เขตเลือกตั้ง'),
              TextFormField(
                controller: _zoneCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณากรอกเขต' : null,
              ),
              const SizedBox(height: 16),
              _Label('จังหวัด'),
              TextFormField(
                controller: _provinceCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'กรุณากรอกจังหวัด' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _saving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
